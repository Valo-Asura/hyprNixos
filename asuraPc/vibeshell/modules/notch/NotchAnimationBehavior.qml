import QtQuick
import qs.config

// Comportamiento estándar para animaciones de elementos que aparecen en el notch
Item {
    id: root

    // Propiedad para controlar la visibilidad con animaciones
    property bool isVisible: false

    // Aplicar las animaciones estándar del notch
    scale: isVisible ? 1.0 : 0.92
    opacity: isVisible ? 1.0 : 0.0
    visible: opacity > 0

    Behavior on scale {
        enabled: Config.animDuration > 0
        SpringAnimation {
            spring: 4.4
            damping: 0.32
            epsilon: 0.002
        }
    }

    Behavior on opacity {
        enabled: Config.animDuration > 0
        NumberAnimation {
            duration: Math.max(120, Config.animDuration * 0.7)
            easing.type: Easing.OutQuint
        }
    }
}
