#!/usr/bin/env bash
#
# corvorum-proton-shortcut-sync.sh
# Vigila la carpeta proton_shortcuts dentro del prefijo umu/Proton.
# Cuando aparece un .desktop nuevo (o se modifica), lo reescribe para que
# Exec= use umu-run apuntando al .exe real, e Icon= sea válido para Linux.
# Luego lo copia corregido a ~/.local/share/applications/ en categoría "Otros".
#
# Requiere: inotify-tools (paquete inotifywait)
#
# NOTA: el bloque de reescritura está pendiente de confirmar el formato
# EXACTO que genera umu en sus .desktop (Path=, Exec= y formato del .lnk).
# Ajustar la función rewrite_desktop() en cuanto se confirme.

set -euo pipefail

PREFIX="${1:-$HOME/Games/umu/0}"
WATCH_DIR="$PREFIX/pfx/dosdevices/c:/proton_shortcuts"
DEST_DIR="$HOME/.local/share/applications"
CATEGORY="Corvorum-Otros"

mkdir -p "$DEST_DIR"

if [[ ! -d "$WATCH_DIR" ]]; then
    echo "No existe la carpeta a vigilar: $WATCH_DIR" >&2
    echo "Revisa la ruta del prefijo (PREFIX) o instala algo primero con umu-run." >&2
    exit 1
fi

if ! command -v inotifywait &>/dev/null; then
    echo "Falta inotify-tools. Instala con: sudo apt install inotify-tools" >&2
    exit 1
fi

# --- Detección de juegos DOS empaquetados (estilo GOG con DOSBox embebido) ---
#
# Señales típicas detectadas en este tipo de instalación:
#   - DOS4GW.EXE en la carpeta del juego (extensor DOS de los 90)
#   - ficheros dosbox*.conf (ej: dosboxTH_single.conf, dosboxTH_client.conf...)
#   - subcarpeta DOSBOX/ con el propio binario de dosbox para Windows embebido
#   - goggame-XXXXXXX.* (identificador interno de GOG)
#
# Si se detecta, usamos el DOSBox NATIVO de Linux (no el de Windows embebido,
# que tendría que correr bajo umu/Proton de forma innecesaria) y le pasamos
# el .conf específico del juego para respetar su configuración original.
is_dos_game() {
    local dir="$1"
    if [[ -f "$dir/DOS4GW.EXE" ]]; then
        return 0
    fi
    if compgen -G "$dir/dosbox*.conf" > /dev/null 2>&1; then
        return 0
    fi
    if [[ -d "$dir/DOSBOX" ]] || [[ -d "$dir/dosbox" ]]; then
        return 0
    fi
    return 1
}

# Elige el .conf más adecuado para lanzar (prioriza *_single.conf, que suele
# ser el perfil de un jugador; si no existe, coge el primer .conf que encuentre)
pick_dosbox_conf() {
    local dir="$1"
    local conf=""
    conf=$(compgen -G "$dir/*single.conf" 2>/dev/null | head -n1) || true
    if [[ -z "$conf" ]]; then
        conf=$(compgen -G "$dir/dosbox*.conf" 2>/dev/null | head -n1) || true
    fi
    echo "$conf"
}

# --- Extracción de icono real desde el .exe (icoutils) ---
#
# Requiere: icoutils (paquetes 'wrestool' e 'icotool')
#   sudo apt install icoutils
#
# wrestool extrae los recursos de icono embebidos en el .exe (formato .ico
# de Windows, que puede contener varias resoluciones). icotool convierte ese
# .ico al mejor .png disponible. Guardamos el resultado en una carpeta propia
# de Corvorum para no mezclar con los iconos del sistema.
ICON_CACHE_DIR="$HOME/.local/share/corvorum/icons"
mkdir -p "$ICON_CACHE_DIR"

extract_icon() {
    local exe_path="$1"
    local app_id="$2"   # identificador seguro (safe_id) para nombrar el png resultante
    local out_png="$ICON_CACHE_DIR/${app_id}.png"

    # Si ya lo extrajimos antes, no repetir trabajo
    if [[ -f "$out_png" ]]; then
        echo "$out_png"
        return 0
    fi

    if ! command -v wrestool &>/dev/null || ! command -v icotool &>/dev/null; then
        return 1
    fi

    local tmp_ico
    tmp_ico=$(mktemp --suffix=.ico)

    # -x extrae recursos tipo icono (-t14 = RT_GROUP_ICON), -o escribe a stdout/archivo
    if ! wrestool -x -t14 "$exe_path" -o "$tmp_ico" 2>/dev/null; then
        rm -f "$tmp_ico"
        return 1
    fi

    if [[ ! -s "$tmp_ico" ]]; then
        rm -f "$tmp_ico"
        return 1
    fi

    # icotool -x extrae todas las resoluciones contenidas en el .ico a pngs
    # numerados; nos quedamos con el de mayor resolución disponible.
    local tmp_dir
    tmp_dir=$(mktemp -d)
    if ! icotool -x -o "$tmp_dir" "$tmp_ico" 2>/dev/null; then
        rm -f "$tmp_ico"
        rm -rf "$tmp_dir"
        return 1
    fi

    local best_png
    best_png=$(ls -S "$tmp_dir"/*.png 2>/dev/null | head -n1) || true

    if [[ -z "$best_png" ]]; then
        rm -f "$tmp_ico"
        rm -rf "$tmp_dir"
        return 1
    fi

    cp "$best_png" "$out_png"
    rm -f "$tmp_ico"
    rm -rf "$tmp_dir"

    echo "$out_png"
    return 0
}

# --- Función que corrige un .desktop de umu y lo deja usable en Linux ---
#
# Formato real confirmado en umu (ejemplo Notepad++.desktop):
#   [Desktop Entry]
#   Name=Notepad++
#   Exec=C:\\users\\Public\\Desktop\\Notepad++.lnk   <- INSERVIBLE en Linux, se ignora
#   Type=Application
#   StartupNotify=true
#   Path=/home/technomantus/Games/umu/0/pfx/dosdevices/c:/Program Files/Notepad++  <- ruta Linux real, válida
#   Icon=7ABC_notepad++.0
#   StartupWMClass=notepad++.exe
#
# Estrategia: Path= ya es una ruta Linux completa y válida hacia la carpeta
# de instalación dentro del prefijo. Buscamos ahí el .exe real usando Name
# y, si no coincide exacto, el primer .exe que no sea uninstall/setup.
#
# Antes de eso, comprobamos si es un juego DOS empaquetado (GOG-style): en
# ese caso se ignora umu-run por completo y se usa dosbox nativo de Linux.
rewrite_desktop() {
    local src="$1"
    local name path exe_path icon_guess dest dosbox_conf
    local ref_exe extracted_icon wm_class

    name=$(grep -m1 '^Name=' "$src" | cut -d= -f2-)
    [[ -z "$name" ]] && name=$(basename "$src" .desktop)

    # Path= en umu ya viene como ruta Linux completa y válida (dosdevices/c:/...)
    path=$(grep -m1 '^Path=' "$src" | cut -d= -f2-)

    if [[ -z "$path" || ! -d "$path" ]]; then
        echo "  [!] No se pudo localizar la carpeta del programa para '$name' (Path=$path). Omitido." >&2
        return 1
    fi

    safe_id=$(echo "$name" | tr -cs 'A-Za-z0-9' '-' | tr 'A-Z' 'a-z')
    dest="$DEST_DIR/corvorum-win-${safe_id}.desktop"
    icon_guess="wine"

    if is_dos_game "$path"; then
        if ! command -v dosbox &>/dev/null; then
            echo "  [!] '$name' parece un juego DOS pero no se encontró 'dosbox' nativo instalado. Omitido." >&2
            return 1
        fi

        dosbox_conf=$(pick_dosbox_conf "$path")

        # Intentamos sacar un icono real de cualquier .exe presente en la carpeta
        # (aunque no se use para ejecutar, sirve como fuente de icono)
        ref_exe=$(find "$path" -maxdepth 1 -iname "*.exe" | head -n1) || true
        if [[ -n "$ref_exe" ]]; then
            extracted_icon=$(extract_icon "$ref_exe" "$safe_id") || true
            [[ -n "$extracted_icon" ]] && icon_guess="$extracted_icon"
        fi

        cat > "$dest" <<EOF
[Desktop Entry]
Type=Application
Name=${name}
Comment=Juego DOS (vía DOSBox nativo) - Corvorum OS
Exec=dosbox -conf "${dosbox_conf}" -exit
Path=${path}
Icon=${icon_guess}
Terminal=false
Categories=${CATEGORY};
X-Corvorum-WinApp=true
X-Corvorum-DosGame=true
X-Corvorum-Source=${src}
EOF
        chmod +x "$dest"
        echo "  [OK] Detectado juego DOS -> Generado: $dest  (Exec -> dosbox -conf \"$dosbox_conf\")"
        return 0
    fi

    # --- Caso normal: aplicación Windows moderna vía umu-run ---
    exe_path=""

    # 1) Primera fuente: StartupWMClass del .desktop original de umu
    # umu suele poner el nombre del .exe real aquí (ej: sh2pc.exe, notepad++.exe)
    local wm_class
    wm_class=$(grep -m1 '^StartupWMClass=' "$src" | cut -d= -f2- | tr '[:upper:]' '[:lower:]')

    if [[ -n "$wm_class" ]]; then
        # Buscar ese .exe exacto dentro de la carpeta del programa (recursivo un nivel)
        while IFS= read -r candidate; do
            base=$(basename "$candidate" | tr '[:upper:]' '[:lower:]')
            if [[ "$base" == "$wm_class" ]]; then
                exe_path="$candidate"
                break
            fi
        done < <(find "$path" -maxdepth 2 -iname "*.exe")
    fi

    # 2) Segunda fuente: nombre.exe exacto igual al Name del juego
    if [[ -z "$exe_path" && -f "$path/${name}.exe" ]]; then
        exe_path="$path/${name}.exe"
    fi

    # 3) Tercera fuente: primer .exe que no sea instalador, parche, fix, redist ni uninstall
    if [[ -z "$exe_path" ]]; then
        while IFS= read -r candidate; do
            base=$(basename "$candidate" | tr '[:upper:]' '[:lower:]')
            case "$base" in
                uninstall*.exe|unins*.exe|setup*.exe|install*.exe|\
                *redist*.exe|vcredist*.exe|*fix*.exe|*patch*.exe|\
                *update*.exe|*widescreen*.exe|*directx*.exe|*.tmp.exe)
                    continue ;;
                *) exe_path="$candidate"; break ;;
            esac
        done < <(find "$path" -maxdepth 1 -iname "*.exe")
    fi

    if [[ -z "$exe_path" ]]; then
        echo "  [!] No se pudo determinar el .exe real para '$name' (Path=$path). Omitido." >&2
        return 1
    fi

    local extracted_icon
    extracted_icon=$(extract_icon "$exe_path" "$safe_id") || true
    [[ -n "$extracted_icon" ]] && icon_guess="$extracted_icon"

    cat > "$dest" <<EOF
[Desktop Entry]
Type=Application
Name=${name}
Comment=Aplicación Windows (vía umu-run) - Corvorum OS
Exec=umu-run "${exe_path}"
Path=${path}
Icon=${icon_guess}
Terminal=false
Categories=${CATEGORY};
X-Corvorum-WinApp=true
X-Corvorum-Source=${src}
EOF

    chmod +x "$dest"
    echo "  [OK] Generado: $dest  (Exec -> umu-run \"$exe_path\")"
}

echo "Vigilando $WATCH_DIR ..."
echo "Los lanzadores corregidos se irán creando en $DEST_DIR"
echo "Categoría asignada por defecto: $CATEGORY (reclasificar manualmente si procede)"
echo

# Procesar los que ya existen al arrancar el servicio, por si hay alguno previo
find "$WATCH_DIR" -maxdepth 1 -iname "*.desktop" | while read -r existing; do
    echo "Procesando existente: $(basename "$existing")"
    rewrite_desktop "$existing" || true
done

# Vigilancia continua de nuevos/modificados
inotifywait -m -e create -e moved_to --format '%f' "$WATCH_DIR" | while read -r filename; do
    case "$filename" in
        *.desktop)
            full="$WATCH_DIR/$filename"
            # pequeña espera por si el archivo aún se está escribiendo
            sleep 1
            echo "Nuevo shortcut detectado: $filename"
            rewrite_desktop "$full" || true
            if command -v update-desktop-database &>/dev/null; then
                update-desktop-database "$DEST_DIR" &>/dev/null || true
            fi
            ;;
    esac
done