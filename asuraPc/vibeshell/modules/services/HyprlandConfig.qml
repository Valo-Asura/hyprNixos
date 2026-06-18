import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.config
import qs.modules.theme
import qs.modules.bar
import qs.modules.globals
import qs.modules.services

QtObject {
    id: root

    property Process hyprctlProcess: Process {}

    property var barInstances: []

    function registerBar(barInstance) {
        barInstances.push(barInstance);
    }

    function getBarOrientation() {
        if (barInstances.length > 0) {
            return barInstances[0].orientation || "horizontal";
        }
        const position = Config.bar.position || "top";
        return (position === "left" || position === "right") ? "vertical" : "horizontal";
    }

    property Timer applyTimer: Timer {
        interval: 100
        repeat: false
        onTriggered: applyHyprlandConfigInternal()
    }

    function getColorValue(colorName) {
        const resolved = Config.resolveColor(colorName);
        // If it is a string (HEX), convert it to color; if it is already a color, return as is
        return (typeof resolved === 'string') ? Qt.color(resolved) : resolved;
    }

    function formatColorForHyprland(color) {
        // Hyprland expects colors in format: rgb(rrggbb) or rgba(rrggbbaa)
        const r = Math.round(color.r * 255).toString(16).padStart(2, '0');
        const g = Math.round(color.g * 255).toString(16).padStart(2, '0');
        const b = Math.round(color.b * 255).toString(16).padStart(2, '0');
        const a = Math.round(color.a * 255).toString(16).padStart(2, '0');

        if (color.a === 1.0) {
            return `rgb(${r}${g}${b})`;
        } else {
            return `rgba(${r}${g}${b}${a})`;
        }
    }

    function applyHyprlandConfig() {
        applyTimer.restart();
    }

    function applyHyprlandConfigInternal() {
        // Verify that adapters are loaded before applying configuration
        if (!Config.loader.loaded) {
            console.log("HyprlandConfig: Waiting for Config to load...");
            return;
        }

        // Wait for layout to be ready
        if (!GlobalStates.hyprlandLayoutReady) {
            console.log("HyprlandConfig: Waiting for Hyprland layout detection...");
            return;
        }

        // Determine active colors
        let activeColorFormatted = "";
        // If syncBorderColor is enabled, force usage of hyprlandBorderColor
        // Otherwise, use the configured list of colors (which allows gradients)
        const borderColors = Config.hyprland.syncBorderColor ? null : Config.hyprland.activeBorderColor;

        if (borderColors && borderColors.length > 1) {
            // Gradient with multiple colors
            const formattedColors = borderColors.map(colorName => {
                const color = getColorValue(colorName);
                return formatColorForHyprland(color);
            }).join(" ");
            activeColorFormatted = `${formattedColors} ${Config.hyprland.borderAngle}deg`;
        } else {
            // Single color
            // If borderColors is null (sync enabled) or empty, use Config.hyprlandBorderColor
            // If borderColors has 1 element, use it
            const singleColorName = (borderColors && borderColors.length === 1) ? borderColors[0] : Config.hyprlandBorderColor;
            const activeColor = getColorValue(singleColorName);
            activeColorFormatted = formatColorForHyprland(activeColor);
        }

        // Determine inactive colors
        let inactiveColorFormatted = "";
        const inactiveBorderColors = Config.hyprland.inactiveBorderColor;

        if (inactiveBorderColors && inactiveBorderColors.length > 1) {
            // Gradient with multiple colors
            const formattedColors = inactiveBorderColors.map(colorName => {
                const color = getColorValue(colorName);
                const colorWithFullOpacity = Qt.rgba(color.r, color.g, color.b, 1.0);
                return formatColorForHyprland(colorWithFullOpacity);
            }).join(" ");
            inactiveColorFormatted = `${formattedColors} ${Config.hyprland.inactiveBorderAngle}deg`;
        } else {
            // Single color
            const singleColorName = (inactiveBorderColors && inactiveBorderColors.length === 1) ? inactiveBorderColors[0] : "surface";
            const inactiveColor = getColorValue(singleColorName);
            const inactiveColorWithFullOpacity = Qt.rgba(inactiveColor.r, inactiveColor.g, inactiveColor.b, 1.0);
            inactiveColorFormatted = formatColorForHyprland(inactiveColorWithFullOpacity);
        }

        // Colors for shadows
        const shadowColor = getColorValue(Config.hyprlandShadowColor);
        const shadowColorInactive = getColorValue(Config.hyprland.shadowColorInactive);
        const shadowColorWithOpacity = Qt.rgba(shadowColor.r, shadowColor.g, shadowColor.b, shadowColor.a * Config.hyprlandShadowOpacity);
        const shadowColorInactiveWithOpacity = Qt.rgba(shadowColorInactive.r, shadowColorInactive.g, shadowColorInactive.b, shadowColorInactive.a * Config.hyprlandShadowOpacity);
        const shadowColorFormatted = formatColorForHyprland(shadowColorWithOpacity);
        const shadowColorInactiveFormatted = formatColorForHyprland(shadowColorInactiveWithOpacity);

        const barOrientation = getBarOrientation();
        const workspacesAnimation = barOrientation === "vertical" ? "slidefadevert 20%" : "slidefade 20%";
        const isGameMode = GameModeService.toggled;

        let batchCommand = [
            `keyword bezier myBezier,0.4,0.0,0.2,1.0`,
            `keyword cursor:no_warps true`,
            `keyword input:mouse_refocus false`,
            `keyword general:col.active_border ${activeColorFormatted}`,
            `keyword general:col.inactive_border ${inactiveColorFormatted}`,
            `keyword general:border_size ${isGameMode ? 1 : Config.hyprlandBorderSize}`,
            `keyword general:layout ${GlobalStates.hyprlandLayout}`,
            `keyword decoration:rounding ${isGameMode ? 0 : Config.hyprlandRounding}`,
            `keyword general:gaps_in ${isGameMode ? 0 : Config.hyprland.gapsIn}`,
            `keyword general:gaps_out ${isGameMode ? 0 : Config.hyprland.gapsOut}`,
            `keyword decoration:shadow:enabled ${(!isGameMode && Config.hyprland.shadowEnabled) ? 1 : 0}`,
            `keyword decoration:shadow:range ${Config.hyprland.shadowRange}`,
            `keyword decoration:shadow:render_power ${Config.hyprland.shadowRenderPower}`,
            `keyword decoration:shadow:sharp ${Config.hyprland.shadowSharp ? 1 : 0}`,
            `keyword decoration:shadow:ignore_window ${Config.hyprland.shadowIgnoreWindow ? 1 : 0}`,
            `keyword decoration:shadow:color ${shadowColorFormatted}`,
            `keyword decoration:shadow:color_inactive ${shadowColorInactiveFormatted}`,
            `keyword decoration:shadow:offset ${Config.hyprland.shadowOffset}`,
            `keyword decoration:shadow:scale ${Config.hyprland.shadowScale}`,
            `keyword decoration:blur:enabled ${(!isGameMode && Config.hyprland.blurEnabled) ? 1 : 0}`,
            `keyword decoration:blur:size ${Config.hyprland.blurSize}`,
            `keyword decoration:blur:passes ${Config.hyprland.blurPasses}`,
            `keyword decoration:blur:ignore_opacity ${Config.hyprland.blurIgnoreOpacity ? 1 : 0}`,
            `keyword decoration:blur:new_optimizations ${Config.hyprland.blurNewOptimizations ? 1 : 0}`,
            `keyword decoration:blur:xray ${Config.hyprland.blurXray ? 1 : 0}`,
            `keyword decoration:blur:noise ${Config.hyprland.blurNoise}`,
            `keyword decoration:blur:contrast ${Config.hyprland.blurContrast}`,
            `keyword decoration:blur:brightness ${Config.hyprland.blurBrightness}`,
            `keyword decoration:blur:vibrancy ${Config.hyprland.blurVibrancy}`,
            `keyword decoration:blur:vibrancy_darkness ${Config.hyprland.blurVibrancyDarkness}`,
            `keyword decoration:blur:special ${Config.hyprland.blurSpecial ? 1 : 0}`,
            `keyword decoration:blur:popups ${Config.hyprland.blurPopups ? 1 : 0}`,
            `keyword decoration:blur:popups_ignorealpha ${Config.hyprland.blurPopupsIgnorealpha}`,
            `keyword decoration:blur:input_methods ${Config.hyprland.blurInputMethods ? 1 : 0}`,
            `keyword decoration:blur:input_methods_ignorealpha ${Config.hyprland.blurInputMethodsIgnorealpha}`,
            `keyword animations:enabled ${isGameMode ? 0 : 1}`,
            `keyword animation windows,1,2.5,myBezier,popin 80%`,
            `keyword animation border,1,2.5,myBezier`,
            `keyword animation fade,1,2.5,myBezier`,
            `keyword animation workspaces,1,2.5,myBezier,${workspacesAnimation}`
        ].join(" ; ");

        // Calculate ignorealpha
        let ignoreAlphaValue = 0.0;

        if (Config.hyprland.blurExplicitIgnoreAlpha) {
            ignoreAlphaValue = Config.hyprland.blurIgnoreAlphaValue.toFixed(2);
        } else {
            // Calculate ignorealpha dynamically based on the opacity of the StyledRects
            // If barbg has opacity > 0, use the lesser of barbg and bg; otherwise use bg
            const barBgOpacity = (Config.theme.srBarBg && Config.theme.srBarBg.opacity !== undefined) ? Config.theme.srBarBg.opacity : 0;
            const bgOpacity = (Config.theme.srBg && Config.theme.srBg.opacity !== undefined) ? Config.theme.srBg.opacity : 1.0;
            ignoreAlphaValue = (barBgOpacity > 0 ? Math.min(barBgOpacity, bgOpacity) : bgOpacity).toFixed(2);
            console.log(`HyprlandConfig: Auto ignorealpha calculated: ${ignoreAlphaValue} (bg: ${bgOpacity}, bar: ${barBgOpacity})`);
        }

        console.log(`HyprlandConfig: Applying ignorealpha: ${ignoreAlphaValue}, explicit: ${Config.hyprland.blurExplicitIgnoreAlpha}`);
        batchCommand += ` ; keyword layerrule "no_anim on, match:namespace quickshell" ; keyword layerrule "blur off, match:namespace quickshell" ; keyword layerrule "ignore_alpha ${ignoreAlphaValue}, match:namespace quickshell"`;
        console.log("HyprlandConfig: Applying hyprctl batch command.");
        hyprctlProcess.command = ["hyprctl", "--batch", batchCommand];
        hyprctlProcess.running = true;
    }

    property Connections configConnections: Connections {
        target: Config.loader
        function onFileChanged() {
            applyHyprlandConfig();
        }
        function onLoaded() {
            applyHyprlandConfig();
        }
    }

    property Connections hyprlandConfigConnections: Connections {
        target: Config.hyprland
        function onBorderSizeChanged() {
            applyHyprlandConfig();
        }
        function onRoundingChanged() {
            applyHyprlandConfig();
        }
        function onGapsInChanged() {
            applyHyprlandConfig();
        }
        function onGapsOutChanged() {
            applyHyprlandConfig();
        }
        function onActiveBorderColorChanged() {
            applyHyprlandConfig();
        }
        function onInactiveBorderColorChanged() {
            applyHyprlandConfig();
        }
        function onBorderAngleChanged() {
            applyHyprlandConfig();
        }
        function onInactiveBorderAngleChanged() {
            applyHyprlandConfig();
        }
        function onSyncRoundnessChanged() {
            applyHyprlandConfig();
        }
        function onSyncBorderWidthChanged() {
            applyHyprlandConfig();
        }
        function onSyncBorderColorChanged() {
            applyHyprlandConfig();
        }
        function onSyncShadowOpacityChanged() {
            applyHyprlandConfig();
        }
        function onSyncShadowColorChanged() {
            applyHyprlandConfig();
        }
        function onShadowEnabledChanged() {
            applyHyprlandConfig();
        }
        function onShadowRangeChanged() {
            applyHyprlandConfig();
        }
        function onShadowRenderPowerChanged() {
            applyHyprlandConfig();
        }
        function onShadowSharpChanged() {
            applyHyprlandConfig();
        }
        function onShadowIgnoreWindowChanged() {
            applyHyprlandConfig();
        }
        function onShadowColorChanged() {
            applyHyprlandConfig();
        }
        function onShadowColorInactiveChanged() {
            applyHyprlandConfig();
        }
        function onShadowOpacityChanged() {
            applyHyprlandConfig();
        }
        function onShadowOffsetChanged() {
            applyHyprlandConfig();
        }
        function onShadowScaleChanged() {
            applyHyprlandConfig();
        }
        function onBlurEnabledChanged() {
            applyHyprlandConfig();
        }
        function onBlurSizeChanged() {
            applyHyprlandConfig();
        }
        function onBlurPassesChanged() {
            applyHyprlandConfig();
        }
        function onBlurIgnoreOpacityChanged() {
            applyHyprlandConfig();
        }
        function onBlurExplicitIgnoreAlphaChanged() {
            applyHyprlandConfig();
        }
        function onBlurIgnoreAlphaValueChanged() {
            applyHyprlandConfig();
        }
        function onBlurNewOptimizationsChanged() {
            applyHyprlandConfig();
        }
        function onBlurXrayChanged() {
            applyHyprlandConfig();
        }
        function onBlurNoiseChanged() {
            applyHyprlandConfig();
        }
        function onBlurContrastChanged() {
            applyHyprlandConfig();
        }
        function onBlurBrightnessChanged() {
            applyHyprlandConfig();
        }
        function onBlurVibrancyChanged() {
            applyHyprlandConfig();
        }
        function onBlurVibrancyDarknessChanged() {
            applyHyprlandConfig();
        }
        function onBlurSpecialChanged() {
            applyHyprlandConfig();
        }
        function onBlurPopupsChanged() {
            applyHyprlandConfig();
        }
        function onBlurPopupsIgnorealphaChanged() {
            applyHyprlandConfig();
        }
        function onBlurInputMethodsChanged() {
            applyHyprlandConfig();
        }
        function onBlurInputMethodsIgnorealphaChanged() {
            applyHyprlandConfig();
        }
    }

    property Connections colorsConnections: Connections {
        target: Colors
        function onFileChanged() {
            applyHyprlandConfig();
        }
        function onLoaded() {
            applyHyprlandConfig();
        }
    }

    property Connections barConnections: Connections {
        target: Config.bar
        function onPositionChanged() {
            applyHyprlandConfig();
        }
    }

    property Connections srBgConnections: Connections {
        target: Config.theme.srBg
        function onOpacityChanged() {
            applyHyprlandConfig();
        }
    }

    property Connections srBarBgConnections: Connections {
        target: Config.theme.srBarBg
        function onOpacityChanged() {
            applyHyprlandConfig();
        }
    }

    property Connections globalStatesConnections: Connections {
        target: GlobalStates
        function onHyprlandLayoutChanged() {
            applyHyprlandConfig();
        }
        function onHyprlandLayoutReadyChanged() {
            if (GlobalStates.hyprlandLayoutReady) {
                applyHyprlandConfig();
            }
        }
    }

    property Connections hyprlandConnections: Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "configreloaded") {
                console.log("HyprlandConfig: configreloaded detected, reapplying configuration...");
                applyHyprlandConfig();
            }
        }
    }

    property Connections gameModeConnections: Connections {
        target: GameModeService
        function onToggledChanged() {
            console.log("HyprlandConfig: GameMode toggled to", GameModeService.toggled, ", applying config...");
            applyHyprlandConfig();
        }
    }

    Component.onCompleted: {
        // If Config loader is already loaded, apply immediately
        if (Config.loader.loaded) {
            applyHyprlandConfig();
        }
        // Otherwise, the onLoaded connections will handle it
    }
}
