# Display and Input Configuration
{ ... }:

{
  services.xserver = {
    enable = true;
    xkb = {
      layout = "in";
      variant = "eng";
    };
    videoDrivers = ["nvidia"];
  };
  
  services.libinput.enable = true;
}