/* Corvorum OS - Slideshow de instalación */
import QtQuick 2.0
import calamares.slideshow 1.0

Presentation {
    id: presentation

    function nextSlide() {
        presentation.goToNextSlide()
    }

    Timer {
        id: slideshowTimer
        interval: 5000
        repeat: true
        running: presentation.activatedInCalamares
        onTriggered: nextSlide()
    }

    /* ── SLIDE 1: Bienvenida ─────────────────────────────────────── */
    Slide {
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#0d1117" }
                GradientStop { position: 1.0; color: "#1a1f2e" }
            }
        }
        Column {
            anchors.centerIn: parent
            spacing: 20
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "CORVORUM OS"
                font.pixelSize: 52
                font.bold: true
                color: "#4a9eff"
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Desktop Edition 1.0"
                font.pixelSize: 22
                color: "#9ca3af"
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Instalando tu sistema..."
                font.pixelSize: 16
                color: "#6b7280"
            }
        }
    }

    /* ── SLIDE 2: Entorno de escritorio ──────────────────────────── */
    Slide {
        Rectangle {
            anchors.fill: parent
            color: "#0d1117"
        }
        Column {
            anchors.centerIn: parent
            spacing: 16
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Escritorio Cinnamon"
                font.pixelSize: 36
                font.bold: true
                color: "#4a9eff"
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Ligero · Estable · Personalizable"
                font.pixelSize: 18
                color: "#9ca3af"
            }
            Rectangle { height: 2; width: 400; color: "#1f2937"; anchors.horizontalCenter: parent.horizontalCenter }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Cinnamon ofrece un entorno de trabajo familiar\ny altamente configurable, sin sacrificar rendimiento.\nTema oscuro Orchis-Dark preconfigurado."
                font.pixelSize: 14
                color: "#6b7280"
                horizontalAlignment: Text.AlignHCenter
                lineHeight: 1.5
            }
        }
    }

    /* ── SLIDE 3: IA Local ───────────────────────────────────────── */
    Slide {
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#0d1117" }
                GradientStop { position: 1.0; color: "#0f1a2e" }
            }
        }
        Column {
            anchors.centerIn: parent
            spacing: 16
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "IA Local con Ollama"
                font.pixelSize: 36
                font.bold: true
                color: "#4a9eff"
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Sin internet · Sin APIs externas · Sin costes"
                font.pixelSize: 18
                color: "#9ca3af"
            }
            Rectangle { height: 2; width: 400; color: "#1f2937"; anchors.horizontalCenter: parent.horizontalCenter }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Corvorum OS incluye Ollama con el modelo corvorum-dev\npreconfigurado y listo para usarse desde el primer arranque.\nIntegrado con VSCodium via Continue.dev para asistencia de código."
                font.pixelSize: 14
                color: "#6b7280"
                horizontalAlignment: Text.AlignHCenter
                lineHeight: 1.5
            }
        }
    }

    /* ── SLIDE 4: Herramientas de desarrollo ─────────────────────── */
    Slide {
        Rectangle {
            anchors.fill: parent
            color: "#0d1117"
        }
        Column {
            anchors.centerIn: parent
            spacing: 16
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Entorno de Desarrollo"
                font.pixelSize: 36
                font.bold: true
                color: "#4a9eff"
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "VSCodium · Chromium · Tilix · Flatpak"
                font.pixelSize: 18
                color: "#9ca3af"
            }
            Rectangle { height: 2; width: 400; color: "#1f2937"; anchors.horizontalCenter: parent.horizontalCenter }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "VSCodium sin telemetría con extensiones preinstaladas.\nChromium para depuración frontend.\nFlatpak + Flathub para gestión de aplicaciones aisladas."
                font.pixelSize: 14
                color: "#6b7280"
                horizontalAlignment: Text.AlignHCenter
                lineHeight: 1.5
            }
        }
    }

    /* ── SLIDE 5: Privacidad y soberanía ─────────────────────────── */
    Slide {
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#0d1117" }
                GradientStop { position: 1.0; color: "#1a1f2e" }
            }
        }
        Column {
            anchors.centerIn: parent
            spacing: 16
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Arquitectura Soberana"
                font.pixelSize: 36
                font.bold: true
                color: "#4a9eff"
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Sin Snap · Sin telemetría · Sin dependencias externas"
                font.pixelSize: 18
                color: "#9ca3af"
            }
            Rectangle { height: 2; width: 400; color: "#1f2937"; anchors.horizontalCenter: parent.horizontalCenter }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Corvorum OS elimina Snap y toda telemetría del sistema base.\nTu infraestructura, tus datos, bajo tu control.\nBasado en Ubuntu 22.04 LTS."
                font.pixelSize: 14
                color: "#6b7280"
                horizontalAlignment: Text.AlignHCenter
                lineHeight: 1.5
            }
        }
    }

    /* ── SLIDE 6: Listo ──────────────────────────────────────────── */
    Slide {
        Rectangle {
            anchors.fill: parent
            color: "#0d1117"
        }
        Column {
            anchors.centerIn: parent
            spacing: 20
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Casi listo..."
                font.pixelSize: 42
                font.bold: true
                color: "#4a9eff"
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Corvorum OS se está instalando en tu sistema"
                font.pixelSize: 16
                color: "#9ca3af"
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Escribe 'ai' en la terminal para consultar al asistente local\nEscribe 'codium' para abrir el editor\nEscribe 'lazydocker' para gestionar contenedores"
                font.pixelSize: 13
                color: "#6b7280"
                horizontalAlignment: Text.AlignHCenter
                lineHeight: 1.6
            }
        }
    }
}