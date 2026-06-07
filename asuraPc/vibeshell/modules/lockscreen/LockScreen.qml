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
import qs.modules.services
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
    readonly property string generatedLockscreenFramePath: {
        if (!GlobalStates.wallpaperManager)
            return "";
        return GlobalStates.wallpaperManager.getLockscreenFramePath(GlobalStates.wallpaperManager.currentWallpaper);
    }
    readonly property string thumbnailLockscreenImagePath: {
        if (!GlobalStates.wallpaperManager)
            return "";
        return GlobalStates.wallpaperManager.getThumbnailPath(GlobalStates.wallpaperManager.currentWallpaper);
    }
    readonly property string activeLockscreenImagePath: {
        if (configuredLockscreenImagePath.length > 0)
            return configuredLockscreenImagePath;
        if (generatedLockscreenFramePath.length > 0)
            return generatedLockscreenFramePath;
        return fallbackLockscreenImagePath;
    }
    property string displayedLockscreenImagePath: activeLockscreenImagePath
    property date currentDate: new Date()

    onActiveLockscreenImagePathChanged: displayedLockscreenImagePath = activeLockscreenImagePath

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
            return desc;
        }
        return "Session locked";
    }

    function weatherTempLabel() {
        if (WeatherService.dataAvailable)
            return Math.round(WeatherService.currentTemp) + "°";
        return "--°";
    }

    function weatherSymbolLabel() {
        if (WeatherService.dataAvailable)
            return WeatherService.effectiveWeatherSymbol || WeatherService.weatherSymbol || Icons.lock;
        return Icons.lock;
    }

    function networkLabel() {
        if (NetworkService.networkName && NetworkService.networkName.length > 0)
            return NetworkService.networkName;
        if (NetworkService.ethernet)
            return "Ethernet";
        if (NetworkService.wifiEnabled)
            return "Wi-Fi";
        return "Offline";
    }

    function batteryLabel() {
        if (!Battery.available)
            return "";
        return Math.round(Battery.percentage) + "%";
    }

    function submitPassword() {
        if (passwordInput.text.trim() === "")
            return;

        authPasswordHolder.password = passwordInput.text;
        passwordInput.text = "";
        authenticating = true;
        errorMessage = "";
        pamAuth.start();
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

        source: root.fileUrl(root.displayedLockscreenImagePath)

        onStatusChanged: {
            if (status === Image.Ready) {
                console.log("Lockscreen using wallpaper:", root.displayedLockscreenImagePath);
            } else if (status === Image.Error) {
                console.warn("Failed to load lockscreen wallpaper:", root.displayedLockscreenImagePath);
                if (root.displayedLockscreenImagePath !== root.thumbnailLockscreenImagePath && root.thumbnailLockscreenImagePath.length > 0) {
                    root.displayedLockscreenImagePath = root.thumbnailLockscreenImagePath;
                } else if (root.displayedLockscreenImagePath !== root.fallbackLockscreenImagePath) {
                    root.displayedLockscreenImagePath = root.fallbackLockscreenImagePath;
                }
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

    // Reference-style top status/notch, kept independent from the main notch module.
    Item {
        id: lockStatusBar
        z: 11
        width: Math.min(parent.width, Math.max(760, parent.width * 0.63))
        height: 40
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: startAnim ? 0 : -height
        opacity: startAnim ? 1 : 0

        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0.03, 0.035, 0.05, 0.90)
            radius: 20

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: parent.radius
                color: parent.color
            }
        }

        layer.enabled: true
        layer.effect: BgShadow {}

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 24
            anchors.verticalCenter: parent.verticalCenter
            width: Math.max(160, (parent.width - lockPill.width) / 2 - 48)
            text: (usernameCollector.text.trim() || Quickshell.env("USER") || "asura") + "  •  " + root.networkLabel()
            font.family: Config.theme.font
            font.pixelSize: Styling.fontSize(-1)
            font.weight: Font.Medium
            color: Colors.overBackground
            elide: Text.ElideRight
        }

        Rectangle {
            id: lockPill
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            width: lockPillContent.implicitWidth + 26
            height: 28
            radius: height / 2
            color: Qt.rgba(0, 0, 0, 0.72)

            Row {
                id: lockPillContent
                anchors.centerIn: parent
                spacing: 7

                Text {
                    text: Icons.lock
                    font.family: Icons.font
                    font.pixelSize: 13
                    color: Colors.overBackground
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: "Locked"
                    font.family: Config.theme.font
                    font.pixelSize: Styling.fontSize(-2)
                    font.bold: true
                    color: Colors.overBackground
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        Row {
            anchors.right: parent.right
            anchors.rightMargin: 24
            anchors.verticalCenter: parent.verticalCenter
            spacing: 9

            Text {
                text: NetworkService.wifi ? NetworkService.wifiIconForStrength(NetworkService.networkStrength) : Icons.wifiOff
                font.family: Icons.font
                font.pixelSize: 15
                color: Colors.overBackground
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                visible: BluetoothService.enabled
                text: BluetoothService.connected ? Icons.bluetoothConnected : Icons.bluetooth
                font.family: Icons.font
                font.pixelSize: 15
                color: Colors.overBackground
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                visible: Battery.available
                text: Battery.getBatteryIcon()
                font.family: Icons.font
                font.pixelSize: 15
                color: Colors.overBackground
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                visible: Battery.available
                text: root.batteryLabel()
                font.family: Config.theme.font
                font.pixelSize: Styling.fontSize(-2)
                font.bold: true
                color: Colors.overBackground
                anchors.verticalCenter: parent.verticalCenter
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

    // Center reference-style clock/weather cluster.
    Item {
        id: clockContainer
        anchors.centerIn: parent
        anchors.verticalCenterOffset: Math.max(-80, -root.height * 0.075)
        width: Math.min(Math.max(root.width * 0.18, 250), 350)
        height: Math.min(350, root.height * 0.42)
        z: 10
        opacity: startAnim ? 1 : 0
        scale: startAnim ? 1 : 0.84

        Item {
            id: analogBlob
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.min(parent.width, 238)
            height: width

            readonly property real hourRotation: ((root.currentDate.getHours() % 12) + root.currentDate.getMinutes() / 60) * 30
            readonly property real minuteRotation: root.currentDate.getMinutes() * 6

            Rectangle {
                anchors.centerIn: parent
                width: parent.width * 0.83
                height: parent.height * 0.76
                radius: height * 0.36
                rotation: -10
                color: Qt.rgba(0.20, 0.28, 0.50, 0.86)
            }

            Rectangle {
                width: parent.width * 0.50
                height: parent.height * 0.44
                radius: height / 2
                x: parent.width * 0.16
                y: parent.height * 0.16
                color: Qt.rgba(0.26, 0.34, 0.58, 0.86)
            }

            Rectangle {
                width: parent.width * 0.47
                height: parent.height * 0.40
                radius: height / 2
                x: parent.width * 0.46
                y: parent.height * 0.34
                color: Qt.rgba(0.18, 0.25, 0.47, 0.86)
            }

            Rectangle {
                width: parent.width * 0.52
                height: parent.height * 0.42
                radius: height / 2
                x: parent.width * 0.25
                y: parent.height * 0.52
                color: Qt.rgba(0.22, 0.30, 0.53, 0.86)
            }

            layer.enabled: true
            layer.effect: BgShadow {}

            Repeater {
                model: 12

                Rectangle {
                    required property int index
                    readonly property real markAngle: index * Math.PI / 6
                    width: index % 3 === 0 ? 10 : 8
                    height: width
                    radius: width / 2
                    x: analogBlob.width / 2 + Math.sin(markAngle) * (analogBlob.width * 0.34) - width / 2
                    y: analogBlob.height / 2 - Math.cos(markAngle) * (analogBlob.height * 0.34) - height / 2
                    color: index === 2 ? Colors.primaryFixedDim : Qt.rgba(0.78, 0.84, 1.0, 0.25)
                }
            }

            Rectangle {
                width: 52
                height: 52
                radius: 18
                x: analogBlob.width * 0.08
                y: analogBlob.height * 0.26
                color: Qt.rgba(0.58, 0.30, 0.48, 0.92)
                rotation: -10

                Text {
                    anchors.centerIn: parent
                    text: Qt.formatDate(root.currentDate, "dd")
                    font.family: Config.theme.font
                    font.pixelSize: 21
                    font.bold: true
                    color: Colors.overBackground
                }
            }

            Rectangle {
                width: 52
                height: 52
                radius: height / 2
                x: analogBlob.width * 0.72
                y: analogBlob.height * 0.58
                color: Qt.rgba(0.31, 0.34, 0.45, 0.92)

                Text {
                    anchors.centerIn: parent
                    text: Qt.formatDate(root.currentDate, "MM")
                    font.family: Config.theme.font
                    font.pixelSize: 21
                    font.bold: true
                    color: Colors.overBackground
                }
            }

            Item {
                anchors.centerIn: parent
                width: 1
                height: 1
                rotation: analogBlob.hourRotation

                Rectangle {
                    width: 17
                    height: 62
                    radius: width / 2
                    x: -width / 2
                    y: -height + 10
                    color: "#f3abc8"
                }
            }

            Item {
                anchors.centerIn: parent
                width: 1
                height: 1
                rotation: analogBlob.minuteRotation

                Rectangle {
                    width: 17
                    height: 78
                    radius: width / 2
                    x: -width / 2
                    y: -height + 10
                    color: "#c4cffd"
                }
            }

            Rectangle {
                anchors.centerIn: parent
                width: 17
                height: 17
                radius: width / 2
                color: "#9eb0f0"
            }

            Column {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: 24
                spacing: -10

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.formatHour12(root.currentDate).replace(/^0/, "")
                    font.family: "League Gothic"
                    font.pixelSize: 58
                    font.bold: true
                    color: Qt.rgba(0.86, 0.89, 1, 0.76)
                    layer.enabled: true
                    layer.effect: BgShadow {}
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatTime(root.currentDate, "mm")
                    font.family: "League Gothic"
                    font.pixelSize: 58
                    font.bold: true
                    color: Qt.rgba(0.86, 0.89, 1, 0.58)
                    layer.enabled: true
                    layer.effect: BgShadow {}
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatTime(root.currentDate, "AP").toLowerCase()
                    font.family: Config.theme.font
                    font.pixelSize: Styling.fontSize(1)
                    font.bold: true
                    color: Qt.rgba(0.86, 0.89, 1, 0.62)
                }
            }
        }

        Column {
            anchors.top: analogBlob.bottom
            anchors.topMargin: 4
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 4

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 8

                Text {
                    text: root.weatherSymbolLabel()
                    font.family: Config.theme.font
                    font.pixelSize: 24
                    color: Colors.overBackground
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: root.weatherTempLabel()
                    font.family: Config.theme.font
                    font.pixelSize: 32
                    font.bold: true
                    color: Colors.overBackground
                    anchors.verticalCenter: parent.verticalCenter
                    layer.enabled: true
                    layer.effect: BgShadow {}
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                width: clockContainer.width - 32
                text: root.weatherLabel()
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                font.family: Config.theme.font
                font.pixelSize: Styling.fontSize(-1)
                color: Colors.overBackground
                opacity: 0.9
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
            bottomMargin: !isTopPosition ? (startAnim ? Math.max(102, root.height * 0.105) : -140) : 0
        }
        width: Math.min(400, parent.width - 56)
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
            bottomMargin: !isTopPosition ? (startAnim ? Math.max(28, root.height * 0.03) : -80) : 0
        }
        width: Math.min(400, parent.width - 56)
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

        // Password input pill, reference-style bottom island.
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

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 18
                anchors.rightMargin: 8
                spacing: 10

                Text {
                    id: passwordStatusIcon
                    text: authenticating ? Icons.spinnerGap : Icons.lock
                    font.family: Icons.font
                    font.pixelSize: 18
                    color: passwordInputBox.showError ? Colors.error : Colors.overSurfaceVariant
                    Layout.preferredWidth: 20
                    Layout.alignment: Qt.AlignVCenter
                    rotation: 0

                    Timer {
                        interval: 100
                        repeat: true
                        running: authenticating
                        onTriggered: passwordStatusIcon.rotation = (passwordStatusIcon.rotation + 45) % 360
                    }

                    onTextChanged: {
                        if (passwordStatusIcon.text === Icons.lock)
                            passwordStatusIcon.rotation = 0;
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredHeight: parent.height

                    readonly property string promptText: failLockSecondsLeft > 0 ? `Locked ${failLockSecondsLeft}s` : "Enter password"

                    Text {
                        anchors.centerIn: parent
                        visible: passwordInput.text.length === 0
                        text: parent.promptText
                        font.family: Config.theme.font
                        font.pixelSize: Styling.fontSize(-1)
                        font.weight: Font.Medium
                        color: passwordInputBox.showError ? Colors.error : Colors.overBackground
                        opacity: 0.9
                    }

                    TextField {
                        id: passwordInput
                        anchors.fill: parent
                        placeholderText: ""
                        font.family: Config.theme.font
                        font.pixelSize: Styling.fontSize(-1)
                        font.weight: Font.Medium
                        color: Colors.overBackground
                        background: null
                        echoMode: TextInput.Password
                        verticalAlignment: TextInput.AlignVCenter
                        horizontalAlignment: TextInput.AlignHCenter
                        enabled: !authenticating

                        Behavior on color {
                            enabled: Config.animDuration > 0
                            ColorAnimation {
                                duration: Config.animDuration
                                easing.type: Easing.OutCubic
                            }
                        }

                        onAccepted: root.submitPassword()
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 42
                    Layout.preferredHeight: 42
                    Layout.alignment: Qt.AlignVCenter
                    radius: width / 2
                    color: passwordInput.text.length > 0 ? Colors.primaryFixedDim : Qt.rgba(Colors.primaryFixedDim.r, Colors.primaryFixedDim.g, Colors.primaryFixedDim.b, 0.42)
                    opacity: authenticating ? 0.55 : 1.0

                    Text {
                        anchors.centerIn: parent
                        text: Icons.arrowRight
                        font.family: Icons.font
                        font.pixelSize: 18
                        color: Styling.srItem("primary")
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: !authenticating
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.submitPassword()
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
