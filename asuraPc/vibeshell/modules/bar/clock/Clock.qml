pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.modules.theme
import qs.modules.components
import qs.modules.services
import "../../widgets/dashboard/widgets"

Item {
    id: root

    property string currentTime: ""
    property string currentDayAbbrev: ""
    property string currentHours: ""
    property string currentMinutes: ""
    property string currentFullDate: ""

    required property var bar
    property bool vertical: bar.orientation === "vertical"
    property bool isHovered: false
    property bool layerEnabled: true

    // Popup visibility state
    property bool popupOpen: clockPopup.isOpen

    // Weather availability
    readonly property bool weatherAvailable: WeatherService.dataAvailable

    function compactWeatherLocation() {
        const location = String(WeatherService.lastLocation || "").trim();
        if (location.length === 0 || location.toLowerCase() === "auto")
            return "Weather";
        const parts = location.split(",").map(part => part.trim()).filter(part => part.length > 0);
        if (parts.length >= 2)
            return parts[0] + ", " + parts[parts.length - 1];
        return location;
    }

    Layout.preferredWidth: vertical ? 36 : buttonBg.implicitWidth
    Layout.preferredHeight: vertical ? buttonBg.implicitHeight : 36

    HoverHandler {
        onHoveredChanged: root.isHovered = hovered
    }

    // Main button
    StyledRect {
        id: buttonBg
        variant: root.popupOpen ? "primary" : "bg"
        anchors.fill: parent
        enableShadow: root.layerEnabled

        implicitWidth: vertical ? 36 : rowLayout.implicitWidth + 24
        implicitHeight: vertical ? columnLayout.implicitHeight + 24 : 36

        Rectangle {
            anchors.fill: parent
            color: Styling.srItem("overprimary")
            opacity: root.popupOpen ? 0 : (root.isHovered ? 0.25 : 0)
            radius: parent.radius ?? 0

            Behavior on opacity {
                enabled: Config.animDuration > 0
                NumberAnimation {
                    duration: Config.animDuration / 2
                }
            }
        }

        RowLayout {
            id: rowLayout
            visible: !root.vertical
            anchors.centerIn: parent
            spacing: 8

            Text {
                id: dayDisplay
                text: root.weatherAvailable ? WeatherService.weatherSymbol : root.currentDayAbbrev
                color: root.popupOpen ? buttonBg.item : Colors.overBackground
                font.pixelSize: root.weatherAvailable ? 16 : Config.theme.fontSize
                font.family: root.weatherAvailable ? Config.theme.font : Config.theme.font
                font.bold: !root.weatherAvailable
            }

            Separator {
                id: separator
                vert: true
            }

            Text {
                id: timeDisplay
                text: root.currentTime
                color: root.popupOpen ? buttonBg.item : Colors.overBackground
                font.pixelSize: Config.theme.fontSize
                font.family: Config.theme.font
                font.bold: true
            }
        }

        ColumnLayout {
            id: columnLayout
            visible: root.vertical
            anchors.centerIn: parent
            spacing: 4
            Layout.alignment: Qt.AlignHCenter

            Text {
                id: dayDisplayV
                text: root.weatherAvailable ? WeatherService.weatherSymbol : root.currentDayAbbrev
                color: root.popupOpen ? buttonBg.item : Colors.overBackground
                font.pixelSize: root.weatherAvailable ? 16 : Config.theme.fontSize
                font.family: Config.theme.font
                font.bold: !root.weatherAvailable
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.NoWrap
                Layout.alignment: Qt.AlignHCenter
            }

            Separator {
                id: separatorV
                vert: false
                Layout.alignment: Qt.AlignHCenter
            }

            Text {
                id: hoursDisplayV
                text: root.currentHours
                color: root.popupOpen ? buttonBg.item : Colors.overBackground
                font.pixelSize: Config.theme.fontSize
                font.family: Config.theme.font
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.NoWrap
                Layout.alignment: Qt.AlignHCenter
            }

            Text {
                id: minutesDisplayV
                text: root.currentMinutes
                color: root.popupOpen ? buttonBg.item : Colors.overBackground
                font.pixelSize: Config.theme.fontSize
                font.family: Config.theme.font
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.NoWrap
                Layout.alignment: Qt.AlignHCenter
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: false
            cursorShape: Qt.PointingHandCursor
            onClicked: clockPopup.toggle()
        }
    }

    // Clock & Weather popup
    BarPopup {
        id: clockPopup
        anchorItem: buttonBg
        bar: root.bar
        variant: "transparent"
        popupPadding: 0

        contentWidth: popupColumn.width
        contentHeight: popupColumn.height

        onIsOpenChanged: {
            if (isOpen && !WeatherService.dataAvailable) {
                WeatherService.updateWeather();
            }
        }

        // Main popup column
        Column {
            id: popupColumn
            spacing: 4

            // Mini weekly calendar
            StyledRect {
                id: calendarWrapper
                variant: "popup"
                radius: Styling.radius(8)
                enableShadow: false
                width: popupWrapper.width
                height: calendarContent.height + 32

                property date currentDate: new Date()
                property int currentDayOfWeek: (currentDate.getDay() + 6) % 7  // Monday = 0
                property int currentDayOfMonth: currentDate.getDate()

                // Get the Monday of the current week
                function getWeekStart(date) {
                    var d = new Date(date);
                    var day = d.getDay();
                    var diff = d.getDate() - day + (day === 0 ? -6 : 1);
                    return new Date(d.setDate(diff));
                }

                property date weekStart: getWeekStart(currentDate)

                // Update date every minute
                Timer {
                    interval: 60000
                    running: true
                    repeat: true
                    onTriggered: calendarWrapper.currentDate = new Date()
                }

                Column {
                    id: calendarContent
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: 16
                    spacing: 4

                    // Helper function to capitalize first letter
                    function capitalizeMonth(date) {
                        var month = date.toLocaleDateString(Qt.locale(), "MMMM");
                        return month.charAt(0).toUpperCase() + month.slice(1);
                    }

                    // Header row: Month and events count
                    Item {
                        width: daysRow.width
                        height: monthText.height

                        Text {
                            id: monthText
                            anchors.left: parent.left
                            anchors.leftMargin: 4
                            text: calendarContent.capitalizeMonth(calendarWrapper.currentDate)
                            color: Colors.outline
                            font.family: Config.theme.font
                            font.pixelSize: Styling.fontSize(0)
                            font.weight: Font.Medium
                        }

                        // Placeholder for events count (future feature)
                        Text {
                            anchors.right: parent.right
                            anchors.rightMargin: 4
                            text: ""
                            color: Colors.outline
                            font.family: Config.theme.font
                            font.pixelSize: Styling.fontSize(-1)
                            visible: text !== ""
                        }
                    }

                    // Days of week row
                    Row {
                        id: daysRow
                        spacing: 4

                        Repeater {
                            model: 7

                            Column {
                                id: dayColumn
                                required property int index
                                spacing: 2
                                width: 36

                                // Get the date for this day of the week
                                property date dayDate: {
                                    var d = new Date(calendarWrapper.weekStart);
                                    d.setDate(d.getDate() + index);
                                    return d;
                                }
                                property bool isToday: index === calendarWrapper.currentDayOfWeek

                                // Day abbreviation from locale
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: {
                                        var dayName = dayColumn.dayDate.toLocaleDateString(Qt.locale(), "ddd");
                                        // Capitalize first letter and limit to 2 chars
                                        return (dayName.charAt(0).toUpperCase() + dayName.slice(1, 2)).replace(".", "");
                                    }
                                    color: Colors.overBackground
                                    font.family: Config.theme.font
                                    font.pixelSize: Styling.fontSize(0)
                                    font.weight: Font.Medium
                                }

                                // Day number with circle for current day
                                Item {
                                    width: 28
                                    height: 28
                                    anchors.horizontalCenter: parent.horizontalCenter

                                    Rectangle {
                                        anchors.centerIn: parent
                                        width: 28
                                        height: 28
                                        radius: Styling.radius(0)
                                        color: Styling.srItem("overprimary")
                                        visible: dayColumn.isToday
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        text: dayColumn.dayDate.getDate()
                                        color: dayColumn.isToday ? Colors.background : Colors.overBackground
                                        font.family: Config.theme.font
                                        font.pixelSize: Styling.fontSize(0)
                                        font.weight: dayColumn.isToday ? Font.Bold : Font.Normal
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Nandoroid-inspired weather card
            StyledRect {
                id: popupWrapper
                variant: "popup"
                radius: Styling.radius(8)
                enableShadow: false
                width: 396
                height: weatherCard.implicitHeight + 40
                visible: WeatherService.dataAvailable

                function relativeUpdateText() {
                    var updated = WeatherService.lastUpdated;
                    if (!updated || updated.getTime() <= 0)
                        return WeatherService.isLoading ? "Updating..." : "Click to refresh";
                    var diffMinutes = Math.floor((new Date().getTime() - updated.getTime()) / 60000);
                    if (diffMinutes < 1)
                        return "Updated just now, click to refresh";
                    if (diffMinutes < 60)
                        return "Updated " + diffMinutes + " min ago, click to refresh";
                    return "Updated " + Math.floor(diffMinutes / 60) + " hr ago, click to refresh";
                }

                ColumnLayout {
                    id: weatherCard
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 16

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 16

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Text {
                                    text: WeatherService.effectiveWeatherSymbol
                                    font.pixelSize: 30
                                    Layout.alignment: Qt.AlignTop
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    Text {
                                        text: WeatherService.effectiveWeatherDescription
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                        color: Colors.overBackground
                                        font.family: Config.theme.font
                                        font.pixelSize: Styling.fontSize(4)
                                        font.weight: Font.Medium
                                    }

                                    Text {
                                        text: root.compactWeatherLocation()
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                        color: Colors.outline
                                        font.family: Config.theme.font
                                        font.pixelSize: Styling.fontSize(-1)
                                    }
                                }
                            }

                            Text {
                                text: "Feels like " + Math.round(WeatherService.feelsLikeTemp) + "\u00B0"
                                color: Colors.overSurfaceVariant
                                font.family: Config.theme.font
                                font.pixelSize: Styling.fontSize(0)
                            }

                            Text {
                                text: Math.round(WeatherService.maxTemp) + "\u00B0 · " + Math.round(WeatherService.minTemp) + "\u00B0"
                                color: Colors.outline
                                font.family: Config.theme.font
                                font.pixelSize: Styling.fontSize(0)
                            }
                        }

                        Text {
                            text: Math.round(WeatherService.currentTemp) + "\u00B0"
                            color: Colors.overBackground
                            font.family: Config.theme.font
                            font.pixelSize: 62
                            font.weight: Font.Light
                            Layout.alignment: Qt.AlignRight | Qt.AlignTop
                        }

                        StyledRect {
                            Layout.preferredWidth: 34
                            Layout.preferredHeight: 34
                            Layout.alignment: Qt.AlignTop
                            radius: Styling.radius(2)
                            variant: refreshHover.hovered ? "focus" : "common"

                            Text {
                                id: refreshIcon
                                anchors.centerIn: parent
                                text: Icons.sync
                                font.family: Icons.font
                                font.pixelSize: 17
                                color: Colors.overBackground

                                RotationAnimation on rotation {
                                    from: 0
                                    to: 360
                                    duration: 800
                                    loops: Animation.Infinite
                                    running: WeatherService.isRefreshing
                                }
                            }

                            HoverHandler {
                                id: refreshHover
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: WeatherService.updateWeather()
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        visible: WeatherService.hourlyForecast.length > 0

                        Repeater {
                            model: WeatherService.hourlyForecast

                            ColumnLayout {
                                required property var modelData
                                Layout.fillWidth: true
                                Layout.preferredWidth: 0
                                spacing: 7

                                Text {
                                    text: Math.round(modelData.temp) + "\u00B0"
                                    Layout.alignment: Qt.AlignHCenter
                                    color: Colors.overBackground
                                    font.family: Config.theme.font
                                    font.pixelSize: Styling.fontSize(-1)
                                    font.weight: Font.Medium
                                }

                                Text {
                                    text: modelData.emoji
                                    Layout.alignment: Qt.AlignHCenter
                                    font.pixelSize: 25
                                }

                                Text {
                                    text: modelData.time
                                    Layout.fillWidth: true
                                    horizontalAlignment: Text.AlignHCenter
                                    color: Colors.outline
                                    font.family: Config.theme.font
                                    font.pixelSize: Styling.fontSize(-2)
                                }
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 9
                        visible: WeatherService.forecast.length > 0

                        Repeater {
                            model: WeatherService.forecast.slice(0, 3)

                            RowLayout {
                                required property var modelData
                                Layout.fillWidth: true
                                spacing: 10

                                Text {
                                    text: modelData.dayName
                                    Layout.fillWidth: true
                                    color: Colors.overBackground
                                    font.family: Config.theme.font
                                    font.pixelSize: Styling.fontSize(0)
                                }

                                Text {
                                    text: Math.round(modelData.maxTemp) + "\u00B0 " + Math.round(modelData.minTemp) + "\u00B0"
                                    color: Colors.overSurfaceVariant
                                    font.family: Config.theme.font
                                    font.pixelSize: Styling.fontSize(0)
                                }

                                Text {
                                    text: modelData.emoji
                                    font.pixelSize: 22
                                }
                            }
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 22

                        Text {
                            id: updateFooter
                            property int refreshTick: 0
                            anchors.centerIn: parent
                            text: {
                                refreshTick;
                                return popupWrapper.relativeUpdateText();
                            }
                            color: Colors.outline
                            font.family: Config.theme.font
                            font.pixelSize: Styling.fontSize(-3)

                            Timer {
                                interval: 60000
                                running: clockPopup.isOpen
                                repeat: true
                                onTriggered: updateFooter.refreshTick++
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: WeatherService.updateWeather()
                        }
                    }
                }
            }

            StyledRect {
                variant: "popup"
                radius: Styling.radius(8)
                enableShadow: false
                width: 396
                height: 92
                visible: WeatherService.hasFailed && !WeatherService.dataAvailable

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 12

                    Text {
                        text: Icons.sync
                        font.family: Icons.font
                        font.pixelSize: 22
                        color: Colors.error
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            text: "Weather refresh failed"
                            font.family: Config.theme.font
                            font.pixelSize: Styling.fontSize(1)
                            font.bold: true
                            color: Colors.overBackground
                        }

                        Text {
                            text: WeatherService.isRefreshing ? "Retrying..." : "Click to retry"
                            font.family: Config.theme.font
                            font.pixelSize: Styling.fontSize(-1)
                            color: Colors.outline
                        }
                    }

                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: WeatherService.updateWeather()
                }
            }
        }
    }

    function scheduleNextDayUpdate() {
        var now = new Date();
        var next = new Date(now.getFullYear(), now.getMonth(), now.getDate() + 1, 0, 0, 1);
        var ms = next - now;
        dayUpdateTimer.interval = ms;
        dayUpdateTimer.start();
    }

    function formatTime12h(now) {
        var hours24 = now.getHours();
        var minutes = now.getMinutes();
        var hours12 = hours24 % 12;
        if (hours12 === 0) hours12 = 12;

        var hh = (hours12 < 10 ? "0" : "") + hours12;
        var mm = (minutes < 10 ? "0" : "") + minutes;
        var ampm = hours24 < 12 ? "AM" : "PM";

        return {
            time: hh + ":" + mm + " " + ampm,
            hours: hh,
            minutes: mm
        };
    }

    function updateDay() {
        var now = new Date();
        var day = Qt.formatDateTime(now, Qt.locale(), "ddd");
        root.currentDayAbbrev = day.slice(0, 3).charAt(0).toUpperCase() + day.slice(1, 3);
        root.currentFullDate = Qt.formatDateTime(now, Qt.locale(), "dddd, MMMM d, yyyy");
        scheduleNextDayUpdate();
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            var now = new Date();
            var formatted = formatTime12h(now);
            root.currentTime = formatted.time;
            root.currentHours = formatted.hours;
            root.currentMinutes = formatted.minutes;
        }
    }

    Timer {
        id: dayUpdateTimer
        repeat: false
        running: false
        onTriggered: updateDay()
    }

    Component.onCompleted: {
        var now = new Date();
        var formatted = formatTime12h(now);
        root.currentTime = formatted.time;
        root.currentHours = formatted.hours;
        root.currentMinutes = formatted.minutes;
        updateDay();
    }
}
