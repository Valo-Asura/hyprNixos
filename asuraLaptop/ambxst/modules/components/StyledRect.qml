pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import Quickshell.Widgets
import qs.config
import qs.modules.theme

ClippingRectangle {
    id: root

    clip: true
    antialiasing: true
    contentUnderBorder: true

    required property string variant

    property string gradientOrientation: "vertical"
    property bool enableShadow: false
    property bool enableBorder: true
    property bool animateRadius: true
    property real backgroundOpacity: -1  // -1 means use config value

    readonly property var variantConfig: Styling.getStyledRectConfig(variant) || {}

    readonly property var gradientStops: variantConfig.gradient

    readonly property string gradientType: variantConfig.gradientType

    readonly property real gradientAngle: variantConfig.gradientAngle

    readonly property real gradientCenterX: variantConfig.gradientCenterX

    readonly property real gradientCenterY: variantConfig.gradientCenterY

    readonly property real halftoneDotMin: variantConfig.halftoneDotMin

    readonly property real halftoneDotMax: variantConfig.halftoneDotMax

    readonly property real halftoneStart: variantConfig.halftoneStart

    readonly property real halftoneEnd: variantConfig.halftoneEnd

    readonly property color halftoneDotColor: Config.resolveColor(variantConfig.halftoneDotColor)

    readonly property color halftoneBackgroundColor: Config.resolveColor(variantConfig.halftoneBackgroundColor)

    readonly property var borderData: variantConfig.border

    readonly property color itemColor: Config.resolveColor(variantConfig.itemColor)
    property color item: itemColor

    readonly property real rectOpacity: backgroundOpacity >= 0 ? backgroundOpacity : variantConfig.opacity

    radius: variantConfig.radius !== undefined ? variantConfig.radius : Styling.radius(0)
    color: "transparent"

    Behavior on radius {
        enabled: root.animateRadius && Config.animDuration > 0
        NumberAnimation {
            duration: Config.animDuration / 4
        }
    }

    // Linear gradient texture generator
    Canvas {
        id: linearGradientCanvas
        width: 256
        height: 32 // Increase height to avoid interpolation artifacts at non-integer scales
        visible: false
        
        onPaint: {
            var ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            
            var stops = root.gradientStops;
            if (!stops || stops.length === 0) return;

            var grad = ctx.createLinearGradient(0, 0, width, 0);
            for (var i = 0; i < stops.length; i++) {
                var s = stops[i];
                grad.addColorStop(s[1], Config.resolveColor(s[0]));
            }
            
            ctx.fillStyle = grad;
            ctx.fillRect(0, 0, width, height);
        }
        
        Connections {
            target: root
            function onGradientStopsChanged() { linearGradientCanvas.requestPaint(); }
        }
        Connections {
            target: Colors
            function onLoaded() { linearGradientCanvas.requestPaint(); }
        }
        Component.onCompleted: requestPaint()
    }

    // Shared gradient texture source
    ShaderEffectSource {
        id: gradientTextureSource
        sourceItem: linearGradientCanvas
        hideSource: true
        smooth: true
        wrapMode: ShaderEffectSource.ClampToEdge
        visible: false
    }

    // Linear gradient
    ShaderEffect {
        anchors.fill: parent
        opacity: rectOpacity
        visible: gradientType === "linear"

        property real angle: gradientAngle
        property real canvasWidth: width
        property real canvasHeight: height
        property var gradTex: gradientTextureSource

        fragmentShader: "linear_gradient.frag.qsb"
    }

    // Radial gradient
    ShaderEffect {
        anchors.fill: parent
        opacity: rectOpacity
        visible: gradientType === "radial"

        property real centerX: gradientCenterX
        property real centerY: gradientCenterY
        property real canvasWidth: width
        property real canvasHeight: height
        property var gradTex: gradientTextureSource

        fragmentShader: "radial_gradient.frag.qsb"
    }

    // Halftone gradient
    ShaderEffect {
        anchors.fill: parent
        opacity: rectOpacity
        visible: gradientType === "halftone"

        property real angle: gradientAngle
        property real dotMinSize: halftoneDotMin
        property real dotMaxSize: halftoneDotMax
        property real gradientStart: halftoneStart
        property real gradientEnd: halftoneEnd
        property vector4d dotColor: {
            const c = halftoneDotColor || Qt.rgba(1, 1, 1, 1);
            return Qt.vector4d(c.r, c.g, c.b, c.a);
        }
        property vector4d backgroundColor: {
            const c = halftoneBackgroundColor || Qt.rgba(0, 0.5, 1, 1);
            return Qt.vector4d(c.r, c.g, c.b, c.a);
        }
        property real canvasWidth: width
        property real canvasHeight: height

        vertexShader: "halftone.vert.qsb"
        fragmentShader: "halftone.frag.qsb"
    }

    // Shadow effect
    layer.enabled: enableShadow
    layer.effect: Shadow {}

    // Border overlay to avoid ClippingRectangle artifacts
    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: "transparent"
        border.color: Config.resolveColor(borderData[0])
        border.width: borderData[1]
        visible: root.enableBorder
    }
}
