import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.modules.components
import qs.modules.globals
import qs.modules.services
import qs.modules.theme
import qs.config

Item {
    id: root

    implicitWidth: 440
    implicitHeight: 360
    focus: true

    property var appsById: ({})
    property string searchText: GlobalStates.launcherSearchText
    property int selectedIndex: GlobalStates.launcherSelectedIndex
    property point lastPointer: Qt.point(-1, -1)

    function focusSearchInput() {
        Qt.callLater(() => searchInput.focusInput());
    }

    function closeLauncher() {
        GlobalStates.clearLauncherState();
        Visibilities.setActiveModule("");
    }

    function refreshApps() {
        const source = searchText.length > 0 ? AppSearch.fuzzyQuery(searchText) : AppSearch.getAllApps().slice(0, 12);
        const nextById = {};

        appsModel.clear();
        for (let i = 0; i < source.length; i++) {
            const app = source[i];
            nextById[app.id] = app;
            appsModel.append({
                appId: app.id,
                appName: app.name,
                appIcon: app.icon,
                appComment: app.comment || "",
                appExecString: app.execString || ""
            });
        }

        appsById = nextById;

        if (appsModel.count === 0) {
            setSelectedIndex(-1);
        } else if (selectedIndex < 0 || selectedIndex >= appsModel.count) {
            setSelectedIndex(0);
        } else {
            resultsList.currentIndex = selectedIndex;
        }
    }

    function setSelectedIndex(index) {
        selectedIndex = index;
        GlobalStates.launcherSelectedIndex = index;
        resultsList.currentIndex = index;
    }

    function launchApp(appId) {
        const app = appsById[appId];
        if (!app || !app.execute)
            return;

        app.execute();
        UsageTracker.recordUsage(appId);
        closeLauncher();
    }

    function launchSelected() {
        if (selectedIndex < 0 && appsModel.count > 0)
            setSelectedIndex(0);

        if (selectedIndex >= 0 && selectedIndex < appsModel.count) {
            const app = appsModel.get(selectedIndex);
            if (app)
                launchApp(app.appId);
        }
    }

    ListModel {
        id: appsModel
    }

    Component.onCompleted: {
        refreshApps();
        focusSearchInput();
        UsageTracker.usageDataReady.connect(function() {
            AppSearch.invalidateCache();
            refreshApps();
        });
    }

    onSearchTextChanged: refreshApps()

    Connections {
        target: GlobalStates
        function onLauncherSearchTextChanged() {
            if (root.searchText !== GlobalStates.launcherSearchText)
                root.searchText = GlobalStates.launcherSearchText;
        }
        function onLauncherSelectedIndexChanged() {
            if (root.selectedIndex !== GlobalStates.launcherSelectedIndex)
                root.setSelectedIndex(GlobalStates.launcherSelectedIndex);
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Text {
                text: Icons.apps
                font.family: Icons.font
                font.pixelSize: 24
                color: Styling.srItem("overprimary")
                Layout.alignment: Qt.AlignVCenter
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                Text {
                    Layout.fillWidth: true
                    text: "Launcher"
                    color: Colors.overBackground
                    font.family: Config.theme.font
                    font.pixelSize: Styling.fontSize(2)
                    font.weight: Font.Bold
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    text: "Type, pick, launch. The notch stays one morphing surface."
                    color: Colors.outline
                    font.family: Config.theme.font
                    font.pixelSize: Styling.fontSize(-2)
                    elide: Text.ElideRight
                }
            }
        }

        SearchInput {
            id: searchInput
            Layout.fillWidth: true
            text: GlobalStates.launcherSearchText
            placeholderText: "Search applications..."
            iconText: Icons.launch
            clearOnEscape: false

            onSearchTextChanged: text => {
                GlobalStates.launcherSearchText = text;
                root.searchText = text;
                root.setSelectedIndex(text.length > 0 && appsModel.count > 0 ? 0 : root.selectedIndex);
            }

            onAccepted: root.launchSelected()
            onEscapePressed: {
                if (text.length > 0) {
                    clear();
                } else {
                    root.closeLauncher();
                }
            }
            onDownPressed: {
                if (appsModel.count > 0)
                    root.setSelectedIndex(Math.min(root.selectedIndex + 1, appsModel.count - 1));
            }
            onUpPressed: {
                if (appsModel.count > 0)
                    root.setSelectedIndex(Math.max(root.selectedIndex - 1, 0));
            }
            onHomePressed: {
                if (appsModel.count > 0)
                    root.setSelectedIndex(0);
            }
            onEndPressed: {
                if (appsModel.count > 0)
                    root.setSelectedIndex(appsModel.count - 1);
            }
        }

        ListView {
            id: resultsList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: appsModel
            currentIndex: root.selectedIndex
            spacing: 4
            boundsBehavior: Flickable.StopAtBounds

            Behavior on contentY {
                enabled: Config.animDuration > 0 && !resultsList.moving
                NumberAnimation {
                    duration: Math.max(120, Config.animDuration / 2)
                    easing.type: Easing.OutCubic
                }
            }

            highlightMoveDuration: Config.animDuration > 0 ? Math.max(120, Config.animDuration / 2) : 0
            highlightResizeDuration: highlightMoveDuration
            highlight: StyledRect {
                variant: "primary"
                radius: Styling.radius(0)
            }

            delegate: Item {
                id: row

                required property string appId
                required property string appName
                required property string appIcon
                required property string appComment
                required property string appExecString
                required property int index

                width: resultsList.width
                height: 50

                readonly property bool selected: root.selectedIndex === index

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onPositionChanged: event => {
                        const pos = mapToItem(null, event.x, event.y);
                        if (pos.x !== root.lastPointer.x || pos.y !== root.lastPointer.y) {
                            root.lastPointer = Qt.point(pos.x, pos.y);
                            root.setSelectedIndex(index);
                        }
                    }
                    onClicked: {
                        root.setSelectedIndex(index);
                        root.launchApp(appId);
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 12

                    Item {
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32

                        Image {
                            id: appIconImage
                            anchors.fill: parent
                            source: "image://icon/" + appIcon
                            fillMode: Image.PreserveAspectFit
                            visible: !Config.tintIcons
                            onStatusChanged: if (status === Image.Error) source = "image://icon/image-missing"
                        }

                        Tinted {
                            anchors.fill: parent
                            visible: Config.tintIcons
                            sourceItem: Image {
                                source: "image://icon/" + appIcon
                                fillMode: Image.PreserveAspectFit
                                onStatusChanged: if (status === Image.Error) source = "image://icon/image-missing"
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        Text {
                            Layout.fillWidth: true
                            text: appName
                            color: row.selected ? Styling.srItem("primary") : Colors.overBackground
                            font.family: Config.theme.font
                            font.pixelSize: Styling.fontSize(0)
                            font.weight: Font.Bold
                            elide: Text.ElideRight
                        }

                        Text {
                            Layout.fillWidth: true
                            text: appComment.length > 0 ? appComment : appExecString
                            color: row.selected ? Styling.srItem("primary") : Colors.outline
                            font.family: Config.theme.font
                            font.pixelSize: Styling.fontSize(-2)
                            elide: Text.ElideRight
                        }
                    }

                    Text {
                        text: Icons.enter
                        font.family: Icons.font
                        font.pixelSize: 18
                        color: row.selected ? Styling.srItem("primary") : Colors.outline
                        opacity: row.selected ? 1 : 0
                        Behavior on opacity {
                            enabled: Config.animDuration > 0
                            NumberAnimation {
                                duration: Config.animDuration / 2
                                easing.type: Easing.OutCubic
                            }
                        }
                    }
                }
            }

            onCurrentIndexChanged: {
                if (currentIndex < 0)
                    return;

                const itemHeight = 54;
                const itemTop = currentIndex * itemHeight;
                const itemBottom = itemTop + itemHeight;
                if (itemTop < contentY) {
                    contentY = itemTop;
                } else if (itemBottom > contentY + height) {
                    contentY = itemBottom - height;
                }
            }
        }
    }
}
