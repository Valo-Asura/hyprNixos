# Ambxst Home Manager integration
{ ... }:

{
  xdg.configFile."Ambxst/binds.json".source = ./binds.json;
  xdg.configFile."Ambxst/config/ai.json".source = ./ai.json;
  xdg.configFile."Ambxst/config/system.json".source = ./system.json;
}
