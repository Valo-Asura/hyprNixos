# Programs Configuration
{ ... }:

{
  programs = {
    firefox.enable = false; # librewolf is primary browser
    
    # Enable direnv system-wide
    direnv.enable = true;
    
    # Fish shell (detailed config in home-manager)
    fish.enable = true;
    
    ssh.startAgent = true;
  };
}
