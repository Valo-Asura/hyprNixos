pragma Singleton
pragma ComponentBehavior: Bound

import QtQml.Models
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import qs.config

Singleton {
    id: root
    property MprisPlayer trackedPlayer: null
    property var filteredPlayers: {
        const filtered = Mpris.players.values.filter(player => {
            const dbusName = (player.dbusName || "").toLowerCase();
            if (!Config.bar.enableFirefoxPlayer && dbusName.includes("firefox")) {
                return false;
            }
            return true;
        });
        return filtered;
    }
    property MprisPlayer activePlayer: trackedPlayer ?? filteredPlayers[0] ?? null

    property string cacheFilePath: Quickshell.dataPath("lastPlayer.json")
    property bool isInitializing: true
    property string cachedDbusName: ""
    property bool cacheFileReady: false

    Process {
        id: ensureCacheFile
        running: true
        command: ["bash", "-c", "mkdir -p \"$(dirname '" + root.cacheFilePath + "')\" && if [ ! -f '" + root.cacheFilePath + "' ]; then echo '{}' > '" + root.cacheFilePath + "'; fi"]
        onExited: {
            root.cacheFileReady = true
            cacheFile.reload()
        }
    }

    FileView {
        id: cacheFile
        path: root.cacheFileReady ? root.cacheFilePath : ""
        onLoaded: root.loadLastPlayer()
    }

    onFilteredPlayersChanged: {
        if (root.isInitializing && root.cachedDbusName && root.filteredPlayers.length > 0) {
            for (const player of root.filteredPlayers) {
                if (player.dbusName === root.cachedDbusName) {
                    root.trackedPlayer = player;
                    root.isInitializing = false;
                    return;
                }
            }
        }
    }

    Component.onCompleted: {
        cacheFile.reload();
    }

    function loadLastPlayer() {
        try {
            const data = cacheFile.text();
            if (!data) {
                root.isInitializing = false;
                return;
            }

            const obj = JSON.parse(data);
            if (obj && obj.dbusName) {
                root.cachedDbusName = obj.dbusName;
                for (const player of root.filteredPlayers) {
                    if (player.dbusName === obj.dbusName) {
                        root.trackedPlayer = player;
                        root.isInitializing = false;
                        return;
                    }
                }
            }
        } catch (e) {
            console.warn("Error loading last player:", e);
            root.isInitializing = false;
        }
    }

    function saveLastPlayer() {
        if (!root.trackedPlayer || root.isInitializing)
            return;

        const data = JSON.stringify({
            dbusName: root.trackedPlayer.dbusName
        });

        cacheFile.setText(data);
    }

    Instantiator {
        model: Mpris.players

        Connections {
            required property MprisPlayer modelData
            target: modelData

            Component.onCompleted: {
                const dbusName = (modelData.dbusName || "").toLowerCase();
                const shouldIgnore = !Config.bar.enableFirefoxPlayer && dbusName.includes("firefox");

                if (!shouldIgnore && (root.trackedPlayer == null || modelData.isPlaying)) {
                    root.trackedPlayer = modelData;
                }
            }

            Component.onDestruction: {
                if (root.trackedPlayer == null || !root.trackedPlayer.isPlaying) {
                    for (const player of root.filteredPlayers) {
                        if (player.playbackState.isPlaying) {
                            root.trackedPlayer = player;
                            break;
                        }
                    }

                    if (trackedPlayer == null && root.filteredPlayers.length != 0) {
                        trackedPlayer = root.filteredPlayers[0];
                    }
                }
            }

            function onPlaybackStateChanged() {
            // Comentado para evitar cambio automático de player
            // if (root.trackedPlayer !== modelData) root.trackedPlayer = modelData
            }
        }
    }

    property bool isPlaying: this.activePlayer && this.activePlayer.isPlaying
    property bool canTogglePlaying: this.activePlayer?.canTogglePlaying ?? false
    function togglePlaying() {
        if (this.canTogglePlaying)
            this.activePlayer.togglePlaying();
    }

    property bool canGoPrevious: this.activePlayer?.canGoPrevious ?? false
    function previous() {
        if (this.canGoPrevious) {
            this.activePlayer.previous();
        }
    }

    property bool canGoNext: this.activePlayer?.canGoNext ?? false
    function next() {
        if (this.canGoNext) {
            this.activePlayer.next();
        }
    }

    property bool canChangeVolume: this.activePlayer && this.activePlayer.volumeSupported && this.activePlayer.canControl

    property bool loopSupported: this.activePlayer && this.activePlayer.loopSupported && this.activePlayer.canControl
    property var loopState: this.activePlayer?.loopState ?? MprisLoopState.None
    function setLoopState(loopState) {
        if (this.loopSupported) {
            this.activePlayer.loopState = loopState;
        }
    }

    property bool shuffleSupported: this.activePlayer && this.activePlayer.shuffleSupported && this.activePlayer.canControl
    property bool hasShuffle: this.activePlayer?.shuffle ?? false
    function setShuffle(shuffle) {
        if (this.shuffleSupported) {
            this.activePlayer.shuffle = shuffle;
        }
    }

    function setActivePlayer(player) {
        const targetPlayer = player ?? Mpris.players[0];

        this.trackedPlayer = targetPlayer;
        this.saveLastPlayer();
    }

    function cyclePlayer(direction) {
        const players = root.filteredPlayers;
        if (players.length === 0)
            return;

        const currentIndex = players.indexOf(this.activePlayer);
        let newIndex;

        if (direction > 0) {
            newIndex = (currentIndex + 1) % players.length;
        } else {
            newIndex = (currentIndex - 1 + players.length) % players.length;
        }

        this.trackedPlayer = players[newIndex];
        this.saveLastPlayer();
    }
}
