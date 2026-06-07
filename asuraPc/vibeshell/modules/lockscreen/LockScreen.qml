pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam
import Quickshell.Wayland
import qs.modules.components
import qs.modules.corners
import qs.modules.theme
import qs.modules.globals
import qs.modules.widgets.dashboard.widgets
import qs.config

// Lock surface UI - shown on each screen when locked
WlSessionLockSurface {
    id: root

    property bool startAnim: false
    property bool authenticating: false
    property string errorMessage: ""
    property int failLockSecondsLeft: 0
    readonly property string fallbackLockscreenImagePath: "/etc/nixos/asuraPc/hyprland/lock-images/lockscreen.png"
    readonly property string configuredLockscreenImagePath: Config.lockscreen?.imagePath ?? ""
    readonly property string syncedLockscreenImagePath: (Quickshell.env("XDG_CACHE_HOME") && Quickshell.env("XDG_CACHE_HOME").length > 0 ? Quickshell.env("XDG_CACHE_HOME") : Quickshell.env("HOME") + "/.cache") + "/Vibeshell/lockscreen.png"
    readonly property string generatedLockscreenFramePath: {
        if (!GlobalStates.wallpaperManager)
            return "";
        return GlobalStates.wallpaperManager.getLockscreenFramePath(GlobalStates.wallpaperManager.currentWallpaper);
    }
    readonly property string activeLockscreenImagePath: {
        if (configuredLockscreenImagePath.length > 0)
            return configuredLockscreenImagePath;
        if (generatedLockscreenFramePath.length > 0)
            return generatedLockscreenFramePath;
        if (syncedLockscreenImagePath.length > 0)
            return syncedLockscreenImagePath;
        return fallbackLockscreenImagePath;
    }
    property date currentDate: new Date()

    function fileUrl(path) {
        if (!path || path.length === 0)
            return "";
        return path.indexOf("file://") === 0 ? path : "file://" + path;
    }

    function formatHour12(date) {
        var h = date.getHours() % 12;
        if (h === 0)
            h = 12;
        return (h < 10 ? "0" : "") + h;
    }

    function lockUserLabel() {
        const user = usernameCollector.text.trim() || Quickshell.env("USER") || "asura";
        const host = hostnameCollector.text.trim() || Quickshell.env("HOSTNAME") || "nixos";
        return user + "@" + host;
    }

    function weatherLabel() {
        if (WeatherService.dataAvailable) {
            const desc = WeatherService.effectiveWeatherDescription || "Weather";
            return Math.round(WeatherService.currentTemp) + "°" + Config.weather.unit + "  " + desc;
        }
        return "Session locked";
    }

    // Always transparent - blur background handles the visuals
    color: "transparent"

    // Screen capture background (fondo absoluto con zoom sincronizado)
    ScreencopyView {
        id: screencopyBackground
        anchors.fill: parent
        captureSource: root.screen
        live: false
        paintCursor: false
        visible: startAnim  // Visible solo cuando startAnim es true
        z: 0  // Capa más baja - fondo absoluto

        property real zoomScale: startAnim ? 1.14 : 1.0

        transform: Scale {
            origin.x: screencopyBackground.width / 2
            origin.y: screencopyBackground.height / 2
            xScale: screencopyBackground.zoomScale
            yScale: screencopyBackground.zoomScale
        }

        Behavior on zoomScale {
            enabled: Config.animDuration > 0
            NumberAnimation {
                duration: Config.animDuration * 2
                easing.type: Easing.OutExpo
            }
        }
    }

    // Wallpaper background source for the visible and blurred layers
    Image {
        id: wallpaperBackground
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        smooth: true
        visible: false
        z: 1

        source: root.fileUrl(root.activeLockscreenImagePath)

        onStatusChanged: {
            if (status === Image.Ready) {
                console.log("Lockscreen using wallpaper:", root.activeLockscreenImagePath);
            } else if (status === Image.Error) {
                console.warn("Failed to load lockscreen wallpaper:", root.activeLockscreenImagePath);
            }
        }
    }

    // Blur effect
    MultiEffect {
        id: blurEffect
        anchors.fill: parent
        source: wallpaperBackground
        autoPaddingEnabled: false
        blurEnabled: true
        blur: startAnim ? 0.30 : 0
        blurMax: 32
        visible: true
        opacity: startAnim ? 0.76 : 0
        z: 2

        property real zoomScale: startAnim ? 1.14 : 1.0

        transform: Scale {
            origin.x: blurEffect.width / 2
            origin.y: blurEffect.height / 2
            xScale: blurEffect.zoomScale
            yScale: blurEffect.zoomScale
        }

        Behavior on blur {
            enabled: Config.animDuration > 0
            NumberAnimation {
                duration: Config.animDuration * 2
                easing.type: Easing.OutExpo
            }
        }

        Behavior on opacity {
            enabled: Config.animDuration > 0
            NumberAnimation {
                duration: Config.animDuration * 2
                easing.type: Easing.OutQuint
            }
        }

        Behavior on zoomScale {
            enabled: Config.animDuration > 0
            NumberAnimation {
                duration: Config.animDuration * 2
                easing.type: Easing.OutExpo
            }
        }
    }

    // Overlay for dimming
    Rectangle {
        id: dimOverlay
        anchors.fill: parent
        color: "black"
        opacity: startAnim ? 0.20 : 0
        z: 3

        property real zoomScale: startAnim ? 1.04 : 1.0

        transform: Scale {
            origin.x: dimOverlay.width / 2
            origin.y: dimOverlay.height / 2
            xScale: dimOverlay.zoomScale
            yScale: dimOverlay.zoomScale
        }

        Behavior on opacity {
            enabled: Config.animDuration > 0
            NumberAnimation {
                duration: Config.animDuration * 2
                easing.type: Easing.OutQuint
            }
        }

        Behavior on zoomScale {
            enabled: Config.animDuration > 0
            NumberAnimation {
                duration: Config.animDuration * 2
                easing.type: Easing.OutExpo
            }
        }
    }

    // Reference-style status strip
    StyledRect {
        id: lockStatusBar
        z: 11
        variant: "popup"
        backgroundOpacity: 0.62
        enableShadow: true
        width: Math.min(parent.width - 48, 520)
        height: 34
        radius: height / 2
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: startAnim ? 14 : -height
        opacity: startAnim ? 1 : 0

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            spacing: 12

            Text {
                text: root.lockUserLabel()
                Layout.fillWidth: true
                font.family: Config.theme.font
                font.pixelSize: Styling.fontSize(-2)
                color: Colors.overBackground
                elide: Text.ElideRight
            }

            StyledRect {
                Layout.preferredWidth: lockPillText.implicitWidth + 22
                Layout.preferredHeight: 24
                radius: height / 2
                variant: "common"
                backgroundOpacity: 0.65

                Text {
                    id: lockPillText
                    anchors.centerIn: parent
                    text: "Locked"
                    font.family: Config.theme.font
                    font.pixelSize: Styling.fontSize(-2)
                    font.bold: true
                    color: Colors.overBackground
                }
            }

            Text {
                text: Qt.formatTime(root.currentDate, "hh:mm AP")
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignRight
                font.family: Config.theme.font
                font.pixelSize: Styling.fontSize(-2)
                color: Colors.overBackground
            }
        }

        Behavior on anchors.topMargin {
            enabled: Config.animDuration > 0
            NumberAnimation {
                duration: Config.animDuration * 2
                easing.type: Easing.OutExpo
            }
        }

        Behavior on opacity {
            enabled: Config.animDuration > 0
            NumberAnimation {
                duration: Config.animDuration * 2
                easing.type: Easing.OutQuad
            }
        }
    }

    // Clock island (center)
    Item {
        id: clockContainer
        anchors.centerIn: parent
        width: Math.min(Math.max(root.width * 0.16, 220), 330)
        height: Math.min(Math.max(root.height * 0.20, 190), 260)
        z: 10
        opacity: startAnim ? 1 : 0
        scale: startAnim ? 1 : 0.84

        StyledRect {
            anchors.fill: parent
            variant: "popup"
            backgroundOpacity: 0.38
            enableShadow: true
            radius: Math.min(width, height) * 0.22

            Rectangle {
                anchors.fill: parent
                anchors.margins: 18
                radius: Math.min(width, height) * 0.24
                color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.12)
                border.width: 1
                border.color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.26)
            }

            Column {
                anchors.centerIn: parent
                spacing: 4

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 6

                    Text {
                        text: root.formatHour12(root.currentDate)
                        font.family: "League Gothic"
                        font.pixelSize: Math.min(Math.max(clockContainer.width * 0.36, 78), 118)
                        color: Colors.overBackground
                        antialiasing: true
                        layer.enabled: true
                        layer.effect: BgShadow {}
                    }

                    Text {
                        text: Qt.formatTime(root.currentDate, "mm")
                        font.family: "League Gothic"
                        font.pixelSize: Math.min(Math.max(clockContainer.width * 0.36, 78), 118)
                        color: Colors.primaryFixedDim
                        antialiasing: true
                        layer.enabled: true
                        layer.effect: BgShadow {}
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatTime(root.currentDate, "AP").toLowerCase()
                    font.family: Config.theme.font
                    font.pixelSize: Styling.fontSize(-1)
                    font.bold: true
                    color: Colors.overBackground
                    opacity: 0.8
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDate(root.currentDate, "ddd, dd MMM")
                    font.family: Config.theme.font
                    font.pixelSize: Styling.fontSize(-2)
                    color: Colors.overSurfaceVariant
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: clockContainer.width - 40
                    text: root.weatherLabel()
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    font.family: Config.theme.font
                    font.pixelSize: Styling.fontSize(-2)
                    color: Colors.overBackground
                    opacity: 0.82
                }
            }
        }

        Behavior on opacity {
            enabled: Config.animDuration > 0
            NumberAnimation {
                duration: Config.animDuration * 2
                easing.type: Easing.OutExpo
            }
        }

        Behavior on scale {
            enabled: Config.animDuration > 0
            SpringAnimation {
                spring: 3.8
                damping: 0.34
                epsilon: 0.002
            }
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.currentDate = new Date()
    }

    // Music player (bottom-centered, reference-style lock card)
    Item {
        id: playerContainer
        z: 10

        property bool isTopPosition: Config.lockscreen.position === "top"

        anchors {
            horizontalCenter: parent.horizontalCenter
            top: isTopPosition ? parent.top : undefined
            topMargin: isTopPosition ? (startAnim ? 96 : -140) : 0
            bottom: !isTopPosition ? parent.bottom : undefined
            bottomMargin: !isTopPosition ? (startAnim ? 104 : -140) : 0
        }
        width: Math.min(390, parent.width - 48)
        height: playerContent.height

        opacity: startAnim && playerContent.visible ? 1 : 0
        scale: startAnim && playerContent.visible ? 1 : 0.94

        Behavior on anchors.topMargin {
            enabled: Config.animDuration > 0
            NumberAnimation {
                duration: Config.animDuration * 2
                easing.type: Easing.OutExpo
            }
        }

        Behavior on anchors.bottomMargin {
            enabled: Config.animDuration > 0
            NumberAnimation {
                duration: Config.animDuration * 2
                easing.type: Easing.OutExpo
            }
        }

        Behavior on opacity {
            enabled: Config.animDuration > 0
            NumberAnimation {
                duration: Config.animDuration * 2
                easing.type: Easing.OutQuad
            }
        }

        Behavior on scale {
            enabled: Config.animDuration > 0
            SpringAnimation {
                spring: 4.2
                damping: 0.34
                epsilon: 0.002
            }
        }

        LockPlayer {
            id: playerContent
            width: parent.width
        }
    }

    // Password input container (slides from top or bottom)
    Item {
        id: passwordContainer
        z: 10

        property bool isTopPosition: Config.lockscreen.position === "top"

        anchors {
            horizontalCenter: parent.horizontalCenter
            top: isTopPosition ? parent.top : undefined
            topMargin: isTopPosition ? (startAnim ? 28 : -80) : 0
            bottom: !isTopPosition ? parent.bottom : undefined
            bottomMargin: !isTopPosition ? (startAnim ? 26 : -80) : 0
        }
        width: Math.min(370, parent.width - 48)
        height: 64

        opacity: startAnim ? 1 : 0
        scale: startAnim ? 1 : 0.92

        Behavior on anchors.topMargin {
            enabled: Config.animDuration > 0
            NumberAnimation {
                duration: Config.animDuration * 2
                easing.type: Easing.OutExpo
            }
        }

        Behavior on anchors.bottomMargin {
            enabled: Config.animDuration > 0
            NumberAnimation {
                duration: Config.animDuration * 2
                easing.type: Easing.OutExpo
            }
        }

        Behavior on opacity {
            enabled: Config.animDuration > 0
            NumberAnimation {
                duration: Config.animDuration * 2
                easing.type: Easing.OutQuad
            }
        }

        Behavior on scale {
            enabled: Config.animDuration > 0
            NumberAnimation {
                duration: Config.animDuration * 2
                easing.type: Easing.OutBack
                easing.overshoot: 1.2
            }
        }

        // Password input with avatar
        StyledRect {
            id: passwordInputBox
            variant: "popup"
            backgroundOpacity: 0.86
            enableShadow: true
            anchors.centerIn: parent
            width: parent.width
            height: 58
            radius: Config.roundness > 0 ? (height / 2) * (Config.roundness / 16) : 0

            property real shakeOffset: 0
            property bool showError: false

            transform: Translate {
                x: passwordInputBox.shakeOffset
            }

            Row {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                spacing: 12

                // Avatar
                Rectangle {
                    id: avatarContainer
                    width: 42
                    height: 42
                    radius: Config.roundness > 0 ? (height / 2) * (Config.roundness / 16) : 0
                    color: "transparent"
                    anchors.verticalCenter: parent.verticalCenter

                    Image {
                        id: userAvatar
                        anchors.fill: parent
                        source: `file://${Quickshell.env("HOME")}/.face.icon`
                        fillMode: Image.PreserveAspectCrop
                        smooth: true
                        asynchronous: true
                        visible: status === Image.Ready

                        layer.enabled: true
                        layer.effect: MultiEffect {
                            maskEnabled: true
                            maskThresholdMin: 0.5
                            maskSpreadAtMin: 1.0
                            maskSource: ShaderEffectSource {
                                sourceItem: Rectangle {
                                    width: userAvatar.width
                                    height: userAvatar.height
                                    radius: Config.roundness > 0 ? (height / 2) * (Config.roundness / 16) : 0
                                }
                            }
                        }
                    }

                    // Fallback icon if image not found
                    Text {
                        anchors.centerIn: parent
                        text: "👤"
                        font.pixelSize: 22
                        visible: userAvatar.status !== Image.Ready
                    }
                }

                // Password field
                StyledRect {
                    id: passwordFieldBg
                    width: parent.width - avatarContainer.width - parent.spacing
                    height: 40
                    anchors.verticalCenter: parent.verticalCenter
                    variant: passwordInputBox.showError ? "error" : "common"
                    radius: Config.roundness > 0 ? (height / 2) * (Config.roundness / 16) : 0

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 32
                        spacing: 8

                        // User icon / Spinner
                        Text {
                            id: userIcon
                            text: authenticating ? Icons.spinnerGap : Icons.user
                            font.family: Icons.font
                            font.pixelSize: 24
                            color: passwordFieldBg.item
                            Layout.preferredWidth: 24
                            Layout.preferredHeight: 24
                            Layout.alignment: Qt.AlignVCenter
                            z: 10
                            rotation: 0

                            Behavior on color {
                                enabled: Config.animDuration > 0
                                ColorAnimation {
                                    duration: Config.animDuration
                                    easing.type: Easing.OutCubic
                                }
                            }

                            Timer {
                                id: spinnerTimer
                                interval: 100
                                repeat: true
                                running: authenticating
                                onTriggered: {
                                    userIcon.rotation = (userIcon.rotation + 45) % 360;
                                }
                            }

                            onTextChanged: {
                                if (userIcon.text === Icons.user) {
                                    userIcon.rotation = 0;
                                }
                            }
                        }

                        // Text field
                        TextField {
                            id: passwordInput
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            placeholderText: failLockSecondsLeft > 0 ? `Locked ${failLockSecondsLeft}s` : "Enter password"
                            placeholderTextColor: Qt.rgba(passwordFieldBg.item.r, passwordFieldBg.item.g, passwordFieldBg.item.b, 0.5)
                            font.family: Config.theme.font
                            font.pixelSize: Styling.fontSize(0)
                            color: passwordFieldBg.item
                            background: null
                            echoMode: TextInput.Password
                            verticalAlignment: TextInput.AlignVCenter
                            enabled: !authenticating

                            Behavior on color {
                                enabled: Config.animDuration > 0
                                ColorAnimation {
                                    duration: Config.animDuration
                                    easing.type: Easing.OutCubic
                                }
                            }

                            Behavior on placeholderTextColor {
                                enabled: Config.animDuration > 0
                                ColorAnimation {
                                    duration: Config.animDuration
                                    easing.type: Easing.OutQuad
                                }
                            }

                            onAccepted: {
                                if (passwordInput.text.trim() === "")
                                    return;

                                // Guardar contraseña y limpiar campo inmediatamente
                                authPasswordHolder.password = passwordInput.text;
                                passwordInput.text = "";

                                authenticating = true;
                                errorMessage = "";
                                pamAuth.start();
                            }
                        }
                    }
                }
            }

            SequentialAnimation {
                id: wrongPasswordAnim
                ScriptAction {
                    script: {
                        passwordInputBox.showError = true;
                    }
                }
                NumberAnimation {
                    target: passwordInputBox
                    property: "shakeOffset"
                    to: 10
                    duration: 50
                    easing.type: Easing.InOutQuad
                }
                NumberAnimation {
                    target: passwordInputBox
                    property: "shakeOffset"
                    to: -10
                    duration: 100
                    easing.type: Easing.InOutQuad
                }
                NumberAnimation {
                    target: passwordInputBox
                    property: "shakeOffset"
                    to: 10
                    duration: 100
                    easing.type: Easing.InOutQuad
                }
                NumberAnimation {
                    target: passwordInputBox
                    property: "shakeOffset"
                    to: 0
                    duration: 50
                    easing.type: Easing.InOutQuad
                }
                ScriptAction {
                    script: {
                        passwordInput.text = "";
                        authenticating = false;
                        passwordInputBox.showError = false;
                    }
                }
            }
        }
    }

    // Timer to unlock after exit animation
    Timer {
        id: unlockTimer
        interval: Config.animDuration * 2  // Wait for zoom out (1x) + fade out (1x)
        onTriggered: {
            GlobalStates.lockscreenVisible = false;
        }
    }

    // Processes for user info
    Process {
        id: usernameProc
        command: ["whoami"]
        running: true

        stdout: StdioCollector {
            id: usernameCollector
            waitForEnd: true
        }
    }

    Process {
        id: hostnameProc
        command: ["hostname"]
        running: true

        stdout: StdioCollector {
            id: hostnameCollector
            waitForEnd: true
        }
    }

    // Holder temporal para la contraseña durante autenticación
    QtObject {
        id: authPasswordHolder
        property string password: ""
    }

    // Proceso para verificar tiempo de faillock
    Process {
        id: failLockCheck
        command: ["bash", "-c", `faillock --user '${usernameCollector.text.trim()}' 2>/dev/null | grep -oP 'left \\K[0-9]+' | head -1`]
        running: false

        stdout: StdioCollector {
            id: failLockCollector

            onStreamFinished: {
                const output = text.trim();
                const seconds = parseInt(output);

                if (!isNaN(seconds) && seconds > 0) {
                    failLockSecondsLeft = seconds;
                    failLockCountdown.start();
                } else {
                    failLockSecondsLeft = 0;
                }
            }
        }
    }

    // Timer para actualizar el countdown de faillock
    Timer {
        id: failLockCountdown
        interval: 1000
        repeat: true
        running: false

        onTriggered: {
            if (failLockSecondsLeft > 0) {
                failLockSecondsLeft--;
            } else {
                stop();
                errorMessage = "";
            }
        }
    }

    // PAM authentication process
    PamContext {
        id: pamAuth
        // Use custom PAM config for lockscreen authentication
        configDirectory: Qt.resolvedUrl("../../config/pam").toString().replace("file://", "")
        config: "password.conf"

        onPamMessage: {
            console.log("PAM Message:", this.message, "Type:", this.messageType, "Required:", this.responseRequired);
            if (this.responseRequired) {
                // pam_unix asks for password, respond with stored password
                this.respond(authPasswordHolder.password);
            }
        }

        onCompleted: result => {
            // Limpiar contraseña
            authPasswordHolder.password = "";

            if (result === PamResult.Success) {
                // Autenticación exitosa - trigger exit animation
                startAnim = false;

                // Wait for exit animation, then unlock
                unlockTimer.start();

                errorMessage = "";
                authenticating = false;
            } else {
                // Error de autenticación
                errorMessage = "Authentication failed";
                console.warn("PAM auth failed with result:", result);
                if (Config.animDuration > 0) {
                    wrongPasswordAnim.start();
                }
            }
        }
    }

    // Screen corners
    RoundCorner {
        id: topLeft
        size: Styling.radius(4)
        anchors.left: parent.left
        anchors.top: parent.top
        corner: RoundCorner.CornerEnum.TopLeft
        z: 100
    }

    RoundCorner {
        id: topRight
        size: Styling.radius(4)
        anchors.right: parent.right
        anchors.top: parent.top
        corner: RoundCorner.CornerEnum.TopRight
        z: 100
    }

    RoundCorner {
        id: bottomLeft
        size: Styling.radius(4)
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        corner: RoundCorner.CornerEnum.BottomLeft
        z: 100
    }

    RoundCorner {
        id: bottomRight
        size: Styling.radius(4)
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        corner: RoundCorner.CornerEnum.BottomRight
        z: 100
    }

    // Initialize when component is created (when lock becomes active)
    Component.onCompleted: {
        // Capture screen immediately
        screencopyBackground.captureFrame();

        // Start animations
        startAnim = true;
        passwordInput.forceActiveFocus();
    }
}
