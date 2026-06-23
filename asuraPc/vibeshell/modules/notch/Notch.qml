import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import qs.modules.globals
import qs.modules.theme
import qs.modules.components
import qs.modules.corners
import qs.modules.services
import qs.config

Item {
    id: notchContainer

    z: 1000

    property Component defaultViewComponent
    property Component dashboardViewComponent
    property Component powermenuViewComponent
    property Component toolsMenuViewComponent
    property Component notificationViewComponent
    property var stackView: stackViewInternal
    property bool isExpanded: stackViewInternal.depth > 1
    property bool isHovered: false
    property bool hoverLatch: false

    // Screen-specific visibility properties passed from parent
    property var visibilities
    readonly property bool screenNotchOpen: visibilities ? (visibilities.launcher || visibilities.dashboard || visibilities.powermenu || visibilities.tools) : false
    readonly property bool hasActiveNotifications: Notifications.popupList.length > 0
    readonly property bool morphActive: screenNotchOpen || hasActiveNotifications || isHovered || hoverLatch || stackViewInternal.busy
    readonly property string morphMode: {
        if (visibilities) {
            if (visibilities.launcher)
                return "launcher";
            if (visibilities.dashboard)
                return "dashboard";
            if (visibilities.powermenu)
                return "powermenu";
            if (visibilities.tools)
                return "tools";
        }
        if (hasActiveNotifications)
            return "notification";
        if (isHovered || hoverLatch)
            return "hover";
        return "rest";
    }
    readonly property int minRestWidth: 168
    readonly property int minHoverWidth: 264
    readonly property int minLauncherWidth: 486
    readonly property int minDashboardWidth: 430
    readonly property int minToolsWidth: 520
    readonly property int minPowerWidth: 420
    readonly property int minNotificationWidth: 410
    readonly property real morphRadius: Config.roundness > 0 ? (morphActive ? Config.roundness + 20 : Config.roundness + 4) : 0

    function minWidthForMode(mode) {
        if (mode === "launcher")
            return minLauncherWidth;
        if (mode === "dashboard")
            return minDashboardWidth;
        if (mode === "powermenu")
            return minPowerWidth;
        if (mode === "tools")
            return minToolsWidth;
        if (mode === "notification")
            return minNotificationWidth;
        if (mode === "hover")
            return minHoverWidth;
        return minRestWidth;
    }

    property int defaultHeight: Config.showBackground ? (morphActive ? Math.max(stackContainer.height, 44) : 44) : (morphActive ? Math.max(stackContainer.height, 40) : 40)
    property int islandHeight: morphActive ? Math.max(stackContainer.height, morphMode === "hover" ? 42 : 36) : 36
    readonly property int targetWidth: Math.max(stackContainer.width + totalCornerWidth, minWidthForMode(morphMode))
    readonly property int targetHeight: Config.notchTheme === "default" ? defaultHeight : (Config.notchTheme === "island" ? islandHeight : defaultHeight)

    // Corner size calculation for dynamic width (only for default theme)
    readonly property int cornerSize: Config.roundness > 0 ? Config.roundness + 4 : 0
    readonly property int totalCornerWidth: Config.notchTheme === "default" ? cornerSize * 2 : 0

    width: targetWidth
    height: targetHeight
    implicitWidth: width
    implicitHeight: height

    readonly property real morphCloseness: {
        const d = Math.max(Math.abs(width - targetWidth), Math.abs(height - targetHeight));
        return 1 - Math.min(1, d / 110);
    }

    readonly property var activeSurfaceItem: stackViewInternal.currentItem
    readonly property string fallbackAmeForm: morphMode === "rest" ? "rest"
        : (morphMode === "hover" ? "soul"
        : (morphMode === "launcher" ? "caret"
        : (morphMode === "dashboard" ? "ring"
        : (morphMode === "powermenu" || morphMode === "tools" ? "dock"
        : (morphMode === "notification" ? "rowseam" : "off")))))
    readonly property string activeAmeForm: activeSurfaceItem && activeSurfaceItem.hasOwnProperty("ameForm") ? activeSurfaceItem.ameForm : fallbackAmeForm
    readonly property real activeAmeHeat: activeSurfaceItem && activeSurfaceItem.hasOwnProperty("ameHeat") ? activeSurfaceItem.ameHeat : 0
    readonly property point activeAmePoint: {
        if (activeSurfaceItem && activeSurfaceItem.hasOwnProperty("amePoint")) {
            const p = activeSurfaceItem.amePoint;
            return activeSurfaceItem.mapToItem(notchRect, p.x, p.y);
        }
        return Qt.point(Math.max(1, width - totalCornerWidth) / 2, Math.min(height / 2, 22));
    }

    Behavior on width {
        enabled: morphActive && Config.animDuration > 0
        NumberAnimation {
            duration: Motion.morph
            easing.type: Motion.easeMorph
            easing.bezierCurve: Motion.morphCurve
        }
    }

    Behavior on height {
        enabled: morphActive && Config.animDuration > 0
        NumberAnimation {
            duration: Motion.morph
            easing.type: Motion.easeMorph
            easing.bezierCurve: Motion.morphCurve
        }
    }

    // StyledRect extendido que cubre todo (notch + corners) para usar como máscara
    StyledRect {
        variant: "bg"
        id: notchFullBackground
        visible: Config.notchTheme === "default"
        anchors.centerIn: parent
        width: parent.implicitWidth
        height: parent.implicitHeight
        enabled: false // No interactuable
        enableBorder: false // No usar border de StyledRect, el Canvas se encarga
        animateRadius: false // Custom animation below

        property int defaultRadius: Config.roundness > 0 ? (morphActive ? Config.roundness + 20 : Config.roundness + 4) : 0

        topLeftRadius: 0
        topRightRadius: 0
        bottomLeftRadius: defaultRadius
        bottomRightRadius: defaultRadius

        Behavior on bottomLeftRadius {
            enabled: Config.animDuration > 0
            NumberAnimation {
                duration: Motion.morph
                easing.type: Motion.easeMorph
                easing.bezierCurve: Motion.morphCurve
            }
        }

        Behavior on bottomRightRadius {
            enabled: Config.animDuration > 0
            NumberAnimation {
                duration: Motion.morph
                easing.type: Motion.easeMorph
                easing.bezierCurve: Motion.morphCurve
            }
        }

        layer.enabled: true
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: notchFullMask
            maskThresholdMin: 0.5
            maskSpreadAtMin: 1.0
        }
    }

    // Máscara completa para el notch + corners
    Item {
        id: notchFullMask
        visible: false
        anchors.centerIn: parent
        width: parent.implicitWidth
        height: parent.implicitHeight
        layer.enabled: true
        layer.smooth: true

    // Left corner mask
    Item {
        id: leftCornerMaskPart
        anchors.top: parent.top
        anchors.left: parent.left
        width: Config.notchTheme === "default" && Config.roundness > 0 ? Config.roundness + 4 : 0
        height: width

        RoundCorner {
            anchors.fill: parent
            corner: RoundCorner.CornerEnum.TopRight
            size: Math.max(parent.width, 1)
            color: "white"
        }
    }

        // Center rect mask
        Rectangle {
            id: centerMaskPart
            anchors.top: parent.top
            anchors.left: leftCornerMaskPart.right
            anchors.right: rightCornerMaskPart.left
            height: parent.height
            color: "white"

            topLeftRadius: notchRect.topLeftRadius
            topRightRadius: notchRect.topRightRadius
            bottomLeftRadius: notchRect.bottomLeftRadius
            bottomRightRadius: notchRect.bottomRightRadius
        }

    // Right corner mask
    Item {
        id: rightCornerMaskPart
        anchors.top: parent.top
        anchors.right: parent.right
        width: Config.notchTheme === "default" && Config.roundness > 0 ? Config.roundness + 4 : 0
        height: width

        RoundCorner {
            anchors.fill: parent
            corner: RoundCorner.CornerEnum.TopLeft
            size: Math.max(parent.width, 1)
            color: "white"
        }
    }
    }

    // Contenedor del notch (solo visual, sin fondo)
    Item {
        id: notchRect
        anchors.centerIn: parent
        width: parent.implicitWidth - totalCornerWidth
        height: parent.implicitHeight

        property int defaultRadius: Config.roundness > 0 ? (morphActive ? Config.roundness + 20 : Config.roundness + 4) : 0
        property int islandRadius: Config.roundness > 0 ? (morphActive ? Config.roundness + 20 : Config.roundness + 4) : 0

        property int topLeftRadius: Config.notchTheme === "default" ? 0 : islandRadius
        property int topRightRadius: Config.notchTheme === "default" ? 0 : islandRadius
        property int bottomLeftRadius: Config.notchTheme === "island" ? islandRadius : defaultRadius
        property int bottomRightRadius: Config.notchTheme === "island" ? islandRadius : defaultRadius

        // Fondo del notch solo para theme "island"
        StyledRect {
            variant: "bg"
            id: notchIslandBg
            visible: Config.notchTheme === "island"
            anchors.fill: parent
            layer.enabled: false
            clip: false // Desactivar clip para que no corte el border
            enableBorder: true // En island sí usar border de StyledRect
            animateRadius: false // Custom animation below
            
            // Usar el islandRadius como radius base también
            radius: parent.islandRadius

            topLeftRadius: parent.topLeftRadius
            topRightRadius: parent.topRightRadius
            bottomLeftRadius: parent.bottomLeftRadius
            bottomRightRadius: parent.bottomRightRadius
            
            Behavior on topLeftRadius {
                enabled: Config.animDuration > 0
                NumberAnimation {
                    duration: Motion.morph
                    easing.type: Motion.easeMorph
                    easing.bezierCurve: Motion.morphCurve
                }
            }

            Behavior on topRightRadius {
                enabled: Config.animDuration > 0
                NumberAnimation {
                    duration: Motion.morph
                    easing.type: Motion.easeMorph
                    easing.bezierCurve: Motion.morphCurve
                }
            }

            Behavior on bottomLeftRadius {
                enabled: Config.animDuration > 0
                NumberAnimation {
                    duration: Motion.morph
                    easing.type: Motion.easeMorph
                    easing.bezierCurve: Motion.morphCurve
                }
            }

            Behavior on bottomRightRadius {
                enabled: Config.animDuration > 0
                NumberAnimation {
                    duration: Motion.morph
                    easing.type: Motion.easeMorph
                    easing.bezierCurve: Motion.morphCurve
                }
            }
        }

        // HoverHandler para detectar hover sin bloquear eventos
        HoverHandler {
            id: notchHoverHandler
            enabled: true

            onHoveredChanged: {
                isHovered = hovered;
                if (hovered) {
                    hoverReleaseTimer.stop();
                    hoverLatch = true;
                } else {
                    hoverReleaseTimer.restart();
                }
                if (stackViewInternal.currentItem && stackViewInternal.currentItem.hasOwnProperty("notchHovered")) {
                    stackViewInternal.currentItem.notchHovered = hovered;
                }
            }
        }

        Timer {
            id: hoverReleaseTimer
            interval: 140
            repeat: false
            onTriggered: hoverLatch = false
        }

        Item {
            id: stackContainer
            anchors.centerIn: parent
            width: stackViewInternal.currentItem ? Math.max(stackViewInternal.currentItem.implicitWidth + (screenNotchOpen ? 32 : 0), minWidthForMode(morphMode) - totalCornerWidth) : (screenNotchOpen ? minWidthForMode(morphMode) : minRestWidth)
            height: stackViewInternal.currentItem ? stackViewInternal.currentItem.implicitHeight + (screenNotchOpen ? 32 : 0) : (screenNotchOpen ? 32 : 0)
            clip: false

            Behavior on width {
                enabled: morphActive && Config.animDuration > 0
                NumberAnimation {
                    duration: Motion.morph
                    easing.type: Motion.easeMorph
                    easing.bezierCurve: Motion.morphCurve
                }
            }

            Behavior on height {
                enabled: morphActive && Config.animDuration > 0
                NumberAnimation {
                    duration: Motion.morph
                    easing.type: Motion.easeMorph
                    easing.bezierCurve: Motion.morphCurve
                }
            }

            // Propiedad para controlar el blur durante las transiciones
            property real transitionBlur: 0.0

            // Aplicar MultiEffect con blur animable
            layer.enabled: transitionBlur > 0.0
            layer.effect: MultiEffect {
                blurEnabled: Config.performance.blurTransition
                blurMax: 64
                blur: Math.min(Math.max(stackContainer.transitionBlur, 0.0), 1.0)
            }

            // Animación simple de blur → nitidez durante transiciones
            PropertyAnimation {
                id: blurTransitionAnimation
                target: stackContainer
                property: "transitionBlur"
                from: 1.0
                to: 0.0
                duration: Config.animDuration
                easing.type: Easing.OutQuart
            }

            StackView {
                id: stackViewInternal
                anchors.fill: parent
                anchors.margins: screenNotchOpen ? 16 : 0
                initialItem: defaultViewComponent

                Component.onCompleted: {
                    isShowingDefault = true;
                    isShowingNotifications = false;
                }

                // Activar blur al inicio de transición y animarlo a nítido
                onBusyChanged: {
                    if (busy) {
                        stackContainer.transitionBlur = 1.0;
                        blurTransitionAnimation.start();
                    }
                }

                pushEnter: Transition {}
                pushExit: Transition {}
                popEnter: Transition {}
                popExit: Transition {}
                replaceEnter: Transition {}
                replaceExit: Transition {}
            }

            Binding {
                target: stackViewInternal.currentItem
                property: "morphCloseness"
                value: notchContainer.morphCloseness
                when: stackViewInternal.currentItem !== null && stackViewInternal.currentItem.hasOwnProperty("morphCloseness")
            }

            Binding {
                target: stackViewInternal.currentItem
                property: "opacity"
                value: Math.pow(notchContainer.morphCloseness, 1.3)
                when: stackViewInternal.currentItem !== null
            }
        }

        Ame {
            id: ameBead
            anchors.fill: parent
            z: 3
            s: Math.max(0.85, Math.min(1.15, notchContainer.height / 44))
            form: notchContainer.activeAmeForm
            point: notchContainer.activeAmePoint
            wake: Qt.point(notchRect.width / 2, Math.min(22, notchRect.height / 2))
            heat: notchContainer.activeAmeHeat
            wickDir: notchContainer.morphMode === "launcher" ? 1 : -1
        }
    }

    // Propiedades para mejorar el control del estado de las vistas
    property bool isShowingNotifications: false
    property bool isShowingDefault: false

    // Unified outline canvas (single continuous stroke around silhouette)
    Canvas {
        id: outlineCanvas
        anchors.centerIn: parent
        width: parent.implicitWidth
        height: parent.implicitHeight
        z: 5000
        antialiasing: true
        
        readonly property var borderData: Config.theme.srBg.border
        readonly property int borderWidth: borderData[1]
        readonly property color borderColor: Config.resolveColor(borderData[0])
        
        visible: Config.notchTheme === "default" && borderWidth > 0
        
        onPaint: {
            if (Config.notchTheme !== "default")
                return; // Only draw for default theme
            var ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            
            if (borderWidth <= 0)
                return; // No outline when borderWidth is 0
            
            ctx.strokeStyle = borderColor;
            ctx.lineWidth = borderWidth;
            ctx.lineJoin = "round";
            ctx.lineCap = "round";

            // Offset to move path inward by half the border width
            var offset = borderWidth / 2;
            
            var rTop = Config.roundness > 0 ? Config.roundness + 4 : 0;
            var bl = notchRect.bottomLeftRadius;
            var br = notchRect.bottomRightRadius;
            var wCenter = notchRect.width;
            var yBottom = height - offset;

            ctx.beginPath();
            if (rTop > 0) {
                // Start at top-left, adjusted inward
                ctx.moveTo(offset, offset);
                // Left top corner arc - center at (offset, rTop), radius reduced by offset
                ctx.arc(offset, rTop, rTop - offset, 3 * Math.PI / 2, 2 * Math.PI);
                // This ends at (rTop, rTop)
            } else {
                ctx.moveTo(offset, offset);
                ctx.lineTo(rTop, rTop);
            }
            // Left vertical line down
            ctx.lineTo(rTop, yBottom - bl);
            // Bottom left corner
            if (bl > 0) {
                ctx.arcTo(rTop, yBottom, rTop + bl, yBottom, bl - offset);
            }
            // Bottom horizontal line
            ctx.lineTo(rTop + wCenter - br, yBottom);
            // Bottom right corner
            if (br > 0) {
                ctx.arcTo(rTop + wCenter, yBottom, rTop + wCenter, yBottom - br, br - offset);
            }
            // Right vertical line up
            ctx.lineTo(rTop + wCenter, rTop);
            // Right top corner arc - center at (width - offset, rTop), from 180° to 270°
            if (rTop > 0) {
                ctx.arc(width - offset, rTop, rTop - offset, Math.PI, 3 * Math.PI / 2);
                // This ends at (width - offset - (rTop - offset), offset) = (width - rTop, offset)
            }
            ctx.stroke();
        }
        Connections {
            target: Colors
            function onPrimaryChanged() {
                outlineCanvas.requestPaint();
            }
        }
        Connections {
            target: Config.theme.srBg
            function onBorderChanged() {
                outlineCanvas.requestPaint();
            }
        }
        Connections {
            target: notchRect
            function onBottomLeftRadiusChanged() {
                outlineCanvas.requestPaint();
            }
            function onBottomRightRadiusChanged() {
                outlineCanvas.requestPaint();
            }
            function onWidthChanged() {
                outlineCanvas.requestPaint();
            }
            function onHeightChanged() {
                outlineCanvas.requestPaint();
            }
        }
        Connections {
            target: notchContainer
            function onImplicitWidthChanged() {
                outlineCanvas.requestPaint();
            }
            function onImplicitHeightChanged() {
                outlineCanvas.requestPaint();
            }
        }
        Connections {
            target: Config
            function onNotchThemeChanged() {
                outlineCanvas.requestPaint();
            }
        }
        Connections {
            target: leftCornerMaskPart
            function onWidthChanged() {
                outlineCanvas.requestPaint();
            }
        }
        Connections {
            target: rightCornerMaskPart
            function onWidthChanged() {
                outlineCanvas.requestPaint();
            }
        }
    }
}
