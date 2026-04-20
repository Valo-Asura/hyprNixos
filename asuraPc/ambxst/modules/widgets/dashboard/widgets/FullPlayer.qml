import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
import Quickshell.Widgets
import Quickshell.Services.Mpris
import qs.modules.theme
import qs.modules.components
import qs.modules.services
import qs.config

StyledRect {
    id: player
    variant: "pane"

    property real playerRadius: Config.roundness > 0 ? Config.roundness + 4 : 0
    property bool playersListExpanded: false

    visible: MprisController.activePlayer !== null
    radius: playerRadius

    implicitHeight: {
        const baseHeight = MprisController.activePlayer ? layout.implicitHeight + layout.anchors.margins * 2 : 40;
        return playersListExpanded ? baseHeight + 4 + (40 * Math.min(3, MprisController.filteredPlayers.length)) : baseHeight;
    }

    Layout.preferredHeight: implicitHeight

    property bool isPlaying: MprisController.activePlayer?.playbackState === MprisPlaybackState.Playing
    property real position: MprisController.activePlayer?.position ?? 0.0
    property real length: MprisController.activePlayer?.length ?? 1.0
    property bool hasArtwork: (MprisController.activePlayer?.trackArtUrl ?? "") !== ""

    function formatTime(seconds) {
        const totalSeconds = Math.floor(seconds);
        const hours = Math.floor(totalSeconds / 3600);
        const minutes = Math.floor((totalSeconds % 3600) / 60);
        const secs = totalSeconds % 60;

        if (hours > 0) {
            return hours + ":" + (minutes < 10 ? "0" : "") + minutes + ":" + (secs < 10 ? "0" : "") + secs;
        } else {
            return minutes + ":" + (secs < 10 ? "0" : "") + secs;
        }
    }

    Timer {
        running: player.isPlaying
        interval: 1000
        repeat: true
        onTriggered: {
            if (!positionSlider.isDragging) {
                positionSlider.value = player.length > 0 ? Math.min(1.0, player.position / player.length) : 0;
            }
            MprisController.activePlayer?.positionChanged();
        }
    }

    Connections {
        target: MprisController.activePlayer
        function onPositionChanged() {
            if (!positionSlider.isDragging && MprisController.activePlayer) {
                positionSlider.value = player.length > 0 ? Math.min(1.0, player.position / player.length) : 0;
            }
        }
    }

    ClippingRectangle {
        anchors.fill: parent
        radius: player.playerRadius
        color: "transparent"

        // Background artwork for entire component
        Image {
            id: backgroundArt
            anchors.fill: parent
            source: MprisController.activePlayer?.trackArtUrl ?? ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            visible: false
        }

        MultiEffect {
            id: backgroundEffect
            anchors.fill: parent
            source: backgroundArt
            blurMax: 32
            blur: 0.75
            opacity: (MprisController.activePlayer?.trackArtUrl ?? "") !== "" ? 1.0 : 0.0

            Behavior on opacity {
                enabled: Config.animDuration > 0
                NumberAnimation {
                    duration: Config.animDuration
                    easing.type: Easing.OutQuart
                }
            }
        }

        StyledRect {
            anchors.fill: parent
            variant: "internalbg"
            opacity: (MprisController.activePlayer?.trackArtUrl ?? "") !== "" ? 0.5 : 0.0

            Behavior on opacity {
                enabled: Config.animDuration > 0
                NumberAnimation {
                    duration: Config.animDuration
                    easing.type: Easing.OutQuart
                }
            }
        }

        ClippingRectangle {
            anchors.fill: parent
            radius: player.playerRadius > 0 ? player.playerRadius - 4 : 0
            color: player.hasArtwork ? "transparent" : Colors.surface

            Behavior on color {
                enabled: Config.animDuration > 0
                ColorAnimation {
                    duration: Config.animDuration
                    easing.type: Easing.OutQuart
                }
            }

            Item {
                id: noPlayerContainer
                anchors.fill: parent
                anchors.margins: 4
                visible: !MprisController.activePlayer

                WavyLine {
                    id: noPlayerWavyLine
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: -4
                    frequency: 4
                    color: Colors.surfaceBright
                    amplitudeMultiplier: 4
                    height: 24
                    lineWidth: 2
                    fullLength: width
                    visible: true
                    opacity: 1.0

                    Behavior on color {
                        enabled: Config.animDuration > 0
                        ColorAnimation {
                            duration: Config.animDuration
                            easing.type: Easing.OutQuart
                        }
                    }

                    FrameAnimation {
                        running: noPlayerWavyLine.visible
                    }
                }
            }

            ColumnLayout {
                id: layout
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 16
                spacing: 8
                visible: MprisController.activePlayer
                layer.enabled: true
                layer.effect: Shadow {
                    shadowBlur: 0.5
                    shadowOpacity: 1
                    shadowVerticalOffset: 2
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 52
                    spacing: 8

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 0

                        Text {
                            Layout.fillWidth: true
                            text: MprisController.activePlayer?.trackTitle ?? "No hay reproducción activa"
                            textFormat: Text.PlainText
                            color: player.hasArtwork ? Colors.overBackground : Colors.overBackground
                            font.pixelSize: Config.theme.fontSize
                            font.weight: Font.Bold
                            font.family: Config.theme.font
                            elide: Text.ElideRight
                            wrapMode: Text.NoWrap
                            maximumLineCount: 1
                        }

                        Text {
                            Layout.fillWidth: true
                            text: MprisController.activePlayer?.trackArtist ?? ""
                            textFormat: Text.PlainText
                            color: player.hasArtwork ? Colors.overBackground : Colors.overBackground
                            font.pixelSize: Config.theme.fontSize
                            font.family: Config.theme.font
                            elide: Text.ElideRight
                            wrapMode: Text.NoWrap
                            maximumLineCount: 1
                            visible: text !== ""
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 4

                            Text {
                                text: player.formatTime(player.position)
                                textFormat: Text.PlainText
                                color: player.hasArtwork ? Colors.overBackground : Colors.overBackground
                                font.pixelSize: Config.theme.fontSize
                                font.family: Config.theme.font
                                visible: MprisController.activePlayer !== null
                            }

                            Text {
                                text: "/ " + player.formatTime(player.length)
                                textFormat: Text.PlainText
                                color: player.hasArtwork ? Colors.overBackground : Colors.overBackground
                                font.pixelSize: Config.theme.fontSize
                                font.family: Config.theme.font
                                opacity: 0.5
                                visible: MprisController.activePlayer !== null
                            }
                        }
                    }

                    StyledRect {
                        id: playPauseButton
                        Layout.preferredWidth: 40
                        Layout.preferredHeight: 40
                        variant: playPauseHover.hovered ? "primaryfocus" : "primary"
                        radius: player.isPlaying ? Styling.radius(-4) : Styling.radius(4)
                        opacity: MprisController.canTogglePlaying ? 1.0 : 0.3

                        Text {
                            id: playPauseBtn
                            anchors.centerIn: parent
                            text: player.isPlaying ? Icons.pause : Icons.play
                            textFormat: Text.RichText
                            color: playPauseButton.item
                            font.pixelSize: 20
                            font.family: Icons.font
                        }

                        HoverHandler {
                            id: playPauseHover
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            enabled: MprisController.canTogglePlaying
                            onClicked: MprisController.togglePlaying()
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    // Layout.preferredHeight: 40
                    spacing: 8

                    Text {
                        id: previousBtn
                        text: Icons.previous
                        textFormat: Text.RichText
                        color: previousHover.hovered ? (player.hasArtwork ? Styling.srItem("overprimary") : Styling.srItem("overprimary")) : Colors.overBackground
                        font.pixelSize: 20
                        font.family: Icons.font
                        opacity: MprisController.canGoPrevious ? 1.0 : 0.3

                        Behavior on color {
                            enabled: Config.animDuration > 0
                            ColorAnimation {
                                duration: Config.animDuration
                                easing.type: Easing.OutQuart
                            }
                        }

                        HoverHandler {
                            id: previousHover
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            enabled: MprisController.canGoPrevious
                            onClicked: MprisController.previous()
                        }
                    }

                    PositionSlider {
                        id: positionSlider
                        Layout.fillWidth: true
                        Layout.preferredHeight: 4

                        player: MprisController.activePlayer
                    }

                    Text {
                        id: nextBtn
                        text: Icons.next
                        textFormat: Text.RichText
                        color: nextHover.hovered ? (player.hasArtwork ? Styling.srItem("overprimary") : Styling.srItem("overprimary")) : Colors.overBackground
                        font.pixelSize: 20
                        font.family: Icons.font
                        opacity: MprisController.canGoNext ? 1.0 : 0.3

                        Behavior on color {
                            enabled: Config.animDuration > 0
                            ColorAnimation {
                                duration: Config.animDuration
                                easing.type: Easing.OutQuart
                            }
                        }

                        HoverHandler {
                            id: nextHover
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            enabled: MprisController.canGoNext
                            onClicked: MprisController.next()
                        }
                    }

                    Text {
                        id: modeBtn
                        text: {
                            if (MprisController.hasShuffle)
                                return Icons.shuffle;
                            switch (MprisController.loopState) {
                            case MprisLoopState.Track:
                                return Icons.repeatOnce;
                            case MprisLoopState.Playlist:
                                return Icons.repeat;
                            default:
                                return Icons.shuffle;
                            }
                        }
                        textFormat: Text.RichText
                        color: modeHover.hovered ? (player.hasArtwork ? Styling.srItem("overprimary") : Styling.srItem("overprimary")) : Colors.overBackground
                        font.pixelSize: 20
                        font.family: Icons.font
                        opacity: {
                            if (!(MprisController.shuffleSupported || MprisController.loopSupported))
                                return 0.3;
                            if (!MprisController.hasShuffle && MprisController.loopState === MprisLoopState.None)
                                return 0.3;
                            return 1.0;
                        }

                        Behavior on color {
                            enabled: Config.animDuration > 0
                            ColorAnimation {
                                duration: Config.animDuration
                                easing.type: Easing.OutQuart
                            }
                        }

                        HoverHandler {
                            id: modeHover
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            enabled: MprisController.shuffleSupported || MprisController.loopSupported
                            onClicked: {
                                if (MprisController.hasShuffle) {
                                    MprisController.setShuffle(false);
                                    MprisController.setLoopState(MprisLoopState.Playlist);
                                } else if (MprisController.loopState === MprisLoopState.Playlist) {
                                    MprisController.setLoopState(MprisLoopState.Track);
                                } else if (MprisController.loopState === MprisLoopState.Track) {
                                    MprisController.setLoopState(MprisLoopState.None);
                                } else {
                                    MprisController.setShuffle(true);
                                }
                            }
                        }
                    }

                    Text {
                        id: playerIcon
                        text: {
                            if (!MprisController.activePlayer)
                                return Icons.player;
                            return player.getPlayerIcon(MprisController.activePlayer);
                        }
                        textFormat: Text.RichText
                        color: playerIconHover.hovered ? (player.hasArtwork ? Styling.srItem("overprimary") : Styling.srItem("overprimary")) : Colors.overBackground
                        font.pixelSize: 20
                        font.family: Icons.font
                        opacity: MprisController.activePlayer ? 1.0 : 0.3

                        Behavior on color {
                            enabled: Config.animDuration > 0
                            ColorAnimation {
                                duration: Config.animDuration
                                easing.type: Easing.OutQuart
                            }
                        }

                        HoverHandler {
                            id: playerIconHover
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            onClicked: mouse => {
                                if (mouse.button === Qt.LeftButton) {
                                    MprisController.cyclePlayer(1);
                                } else if (mouse.button === Qt.RightButton) {
                                    player.playersListExpanded = !player.playersListExpanded;
                                }
                            }
                        }
                    }
                }
            }

            // Players list - similar to SchemeSelector
            RowLayout {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.leftMargin: 4
                anchors.rightMargin: 4
                anchors.bottomMargin: 4
                spacing: 4
                visible: MprisController.filteredPlayers.length > 0

                ClippingRectangle {
                    id: playersListContainer
                    Layout.fillWidth: true
                    Layout.preferredHeight: player.playersListExpanded ? (40 * Math.min(3, MprisController.filteredPlayers.length)) : 0
                    color: Colors.background
                    radius: Styling.radius(0)
                    opacity: player.playersListExpanded ? 1 : 0

                    Behavior on Layout.preferredHeight {
                        enabled: Config.animDuration > 0
                        NumberAnimation {
                            duration: Config.animDuration
                            easing.type: Easing.OutQuart
                        }
                    }

                    Behavior on opacity {
                        enabled: Config.animDuration > 0
                        NumberAnimation {
                            duration: Config.animDuration
                            easing.type: Easing.OutQuart
                        }
                    }

                    ListView {
                        id: playersListView
                        anchors.fill: parent
                        clip: true
                        model: MprisController.filteredPlayers
                        interactive: true
                        boundsBehavior: Flickable.StopAtBounds
                        highlightFollowsCurrentItem: !isScrolling
                        highlightRangeMode: ListView.ApplyRange
                        preferredHighlightBegin: 0
                        preferredHighlightEnd: height
                        currentIndex: -1

                        // Propiedad para detectar si está en movimiento
                        property bool isScrolling: dragging || flicking

                        function getPlayerIcon(player) {
                            if (!player)
                                return Icons.player;
                            const dbusName = (player.dbusName || "").toLowerCase();
                            const desktopEntry = (player.desktopEntry || "").toLowerCase();
                            const identity = (player.identity || "").toLowerCase();

                            if (dbusName.includes("spotify") || desktopEntry.includes("spotify") || identity.includes("spotify"))
                                return Icons.spotify;
                            if (dbusName.includes("chromium") || dbusName.includes("chrome") || desktopEntry.includes("chromium") || desktopEntry.includes("chrome"))
                                return Icons.chromium;
                            if (dbusName.includes("firefox") || desktopEntry.includes("firefox"))
                                return Icons.firefox;
                            if (dbusName.includes("telegram") || desktopEntry.includes("telegram") || identity.includes("telegram"))
                                return Icons.telegram;
                            return Icons.player;
                        }

                        highlight: Rectangle {
                            color: Styling.srItem("overprimary")
                            radius: Styling.radius(0)
                            visible: playersListView.currentIndex >= 0
                            z: -1
                        }

                        highlightMoveDuration: Config.animDuration > 0 ? Config.animDuration / 2 : 0
                        highlightMoveVelocity: -1
                        highlightResizeDuration: Config.animDuration / 2
                        highlightResizeVelocity: -1

                        delegate: Item {
                            required property var modelData
                            required property int index

                            width: playersListView.width
                            height: 40

                            Rectangle {
                                anchors.fill: parent
                                anchors.leftMargin: 4
                                anchors.rightMargin: 4
                                anchors.topMargin: 2
                                anchors.bottomMargin: 2
                                color: "transparent"
                                radius: Styling.radius(0)

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 6
                                    spacing: 8

                                    Text {
                                        text: playersListView.getPlayerIcon(modelData)
                                        textFormat: Text.RichText
                                        color: playersListView.currentIndex === index ? Colors.overPrimary : Colors.overSurface
                                        font.pixelSize: 20
                                        font.family: Icons.font

                                        Behavior on color {
                                            enabled: Config.animDuration > 0
                                            ColorAnimation {
                                                duration: Config.animDuration / 2
                                                easing.type: Easing.OutQuart
                                            }
                                        }
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: modelData.trackTitle || modelData.identity || "Unknown Player"
                                        textFormat: Text.PlainText
                                        color: playersListView.currentIndex === index ? Colors.overPrimary : Colors.overSurface
                                        font.pixelSize: Config.theme.fontSize
                                        font.weight: playersListView.currentIndex === index ? Font.Bold : Font.Normal
                                        font.family: Config.theme.font
                                        elide: Text.ElideRight
                                        wrapMode: Text.NoWrap
                                        maximumLineCount: 1

                                        Behavior on color {
                                            enabled: Config.animDuration > 0
                                            ColorAnimation {
                                                duration: Config.animDuration / 2
                                                easing.type: Easing.OutQuart
                                            }
                                        }
                                    }
                                }

                                HoverHandler {
                                    id: playerItemHover
                                    enabled: !playersListView.isScrolling
                                    onHoveredChanged: {
                                        if (hovered && !playersListView.isScrolling) {
                                            playersListView.currentIndex = index;
                                        }
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    hoverEnabled: !playersListView.isScrolling
                                    onClicked: {
                                        if (playersListView.isScrolling)
                                            return;
                                        MprisController.setActivePlayer(modelData);
                                        player.playersListExpanded = false;
                                    }
                                }
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        propagateComposedEvents: true
                        acceptedButtons: Qt.NoButton

                        onWheel: wheel => {
                            if (player.playersListExpanded && playersListView.contentHeight > playersListView.height) {
                                const delta = wheel.angleDelta.y;
                                playersListView.contentY = Math.max(0, Math.min(playersListView.contentHeight - playersListView.height, playersListView.contentY - delta));
                                wheel.accepted = true;
                            } else {
                                wheel.accepted = false;
                            }
                        }
                    }
                }

                ScrollBar {
                    Layout.preferredWidth: 8
                    Layout.preferredHeight: player.playersListExpanded ? (40 * Math.min(3, MprisController.filteredPlayers.length)) - 32 : 0
                    Layout.alignment: Qt.AlignVCenter
                    orientation: Qt.Vertical
                    visible: MprisController.filteredPlayers.length > 3

                    position: playersListView.contentY / playersListView.contentHeight
                    size: playersListView.height / playersListView.contentHeight

                    background: Rectangle {
                        color: Colors.background
                        radius: Styling.radius(0)
                    }

                    contentItem: Rectangle {
                        color: Styling.srItem("overprimary")
                        radius: Styling.radius(0)
                    }

                    property bool scrollBarPressed: false

                    onPressedChanged: {
                        scrollBarPressed = pressed;
                    }

                    onPositionChanged: {
                        if (scrollBarPressed && playersListView.contentHeight > playersListView.height) {
                            playersListView.contentY = position * playersListView.contentHeight;
                        }
                    }
                }
            }
        }
    }

    function getPlayerIcon(player) {
        if (!player)
            return Icons.player;
        const dbusName = (player.dbusName || "").toLowerCase();
        const desktopEntry = (player.desktopEntry || "").toLowerCase();
        const identity = (player.identity || "").toLowerCase();

        if (dbusName.includes("spotify") || desktopEntry.includes("spotify") || identity.includes("spotify"))
            return Icons.spotify;
        if (dbusName.includes("chromium") || dbusName.includes("chrome") || desktopEntry.includes("chromium") || desktopEntry.includes("chrome"))
            return Icons.chromium;
        if (dbusName.includes("firefox") || desktopEntry.includes("firefox"))
            return Icons.firefox;
        if (dbusName.includes("telegram") || desktopEntry.includes("telegram") || identity.includes("telegram"))
            return Icons.telegram;
        return Icons.player;
    }

    Behavior on Layout.preferredHeight {
        enabled: Config.animDuration > 0
        NumberAnimation {
            duration: Config.animDuration
            easing.type: Easing.OutQuart
        }
    }
}
