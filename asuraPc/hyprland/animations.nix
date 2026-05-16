{ ... }:
let
  animationSpeed = "fast";
  mkAnimation =
    leaf: enabled: speed: bezier: style:
    {
      inherit leaf enabled speed bezier;
    }
    // (if style == null then { } else { inherit style; });

  animationDuration = if animationSpeed == "slow" then
    4.0
  else if animationSpeed == "medium" then
    2.5
  else
    1.0;
  borderDuration = if animationSpeed == "slow" then
    10.0
  else if animationSpeed == "medium" then
    6.0
  else
    3.0;
in {
  wayland.windowManager.hyprland.settings = {
    config.animations = {
      enabled = true;
    };

    curve = [
      {
        _args = [
          "linear"
          {
            type = "bezier";
            points = [
              [ 0 0 ]
              [ 1 1 ]
            ];
          }
        ];
      }
      {
        _args = [
          "md3_standard"
          {
            type = "bezier";
            points = [
              [ 0.2 0 ]
              [ 0 1 ]
            ];
          }
        ];
      }
      {
        _args = [
          "md3_decel"
          {
            type = "bezier";
            points = [
              [ 0.05 0.7 ]
              [ 0.1 1 ]
            ];
          }
        ];
      }
      {
        _args = [
          "md3_accel"
          {
            type = "bezier";
            points = [
              [ 0.3 0 ]
              [ 0.8 0.15 ]
            ];
          }
        ];
      }
      {
        _args = [
          "overshot"
          {
            type = "bezier";
            points = [
              [ 0.05 0.9 ]
              [ 0.1 1.1 ]
            ];
          }
        ];
      }
      {
        _args = [
          "crazyshot"
          {
            type = "bezier";
            points = [
              [ 0.1 1.5 ]
              [ 0.76 0.92 ]
            ];
          }
        ];
      }
      {
        _args = [
          "hyprnostretch"
          {
            type = "bezier";
            points = [
              [ 0.05 0.9 ]
              [ 0.1 1.0 ]
            ];
          }
        ];
      }
      {
        _args = [
          "menu_decel"
          {
            type = "bezier";
            points = [
              [ 0.1 1 ]
              [ 0 1 ]
            ];
          }
        ];
      }
      {
        _args = [
          "menu_accel"
          {
            type = "bezier";
            points = [
              [ 0.38 0.04 ]
              [ 1 0.07 ]
            ];
          }
        ];
      }
      {
        _args = [
          "easeInOutCirc"
          {
            type = "bezier";
            points = [
              [ 0.85 0 ]
              [ 0.15 1 ]
            ];
          }
        ];
      }
      {
        _args = [
          "easeOutCirc"
          {
            type = "bezier";
            points = [
              [ 0 0.55 ]
              [ 0.45 1 ]
            ];
          }
        ];
      }
      {
        _args = [
          "easeOutExpo"
          {
            type = "bezier";
            points = [
              [ 0.16 1 ]
              [ 0.3 1 ]
            ];
          }
        ];
      }
      {
        _args = [
          "softAcDecel"
          {
            type = "bezier";
            points = [
              [ 0.26 0.26 ]
              [ 0.15 1 ]
            ];
          }
        ];
      }
      {
        _args = [
          "md2"
          {
            type = "bezier";
            points = [
              [ 0.4 0 ]
              [ 0.2 1 ]
            ];
          }
        ];
      }
    ];

    animation = [
      (mkAnimation "windows" true animationDuration "md3_decel" "popin 60%")
      (mkAnimation "windowsIn" true animationDuration "md3_decel" "popin 60%")
      (mkAnimation "windowsOut" true animationDuration "md3_accel" "popin 60%")
      (mkAnimation "border" true borderDuration "default" null)
      (mkAnimation "fade" true animationDuration "md3_decel" null)
      (mkAnimation "layersIn" true animationDuration "menu_decel" "slide")
      (mkAnimation "layersOut" true animationDuration "menu_accel" null)
      (mkAnimation "fadeLayersIn" true animationDuration "menu_decel" null)
      (mkAnimation "fadeLayersOut" true animationDuration "menu_accel" null)
      (mkAnimation "workspaces" true animationDuration "menu_decel" "slide")
      (mkAnimation "specialWorkspace" true animationDuration "md3_decel" "slidevert")
    ];
  };
}
