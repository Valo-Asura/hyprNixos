# SOPS secrets for Ambxst AI + OpenClaw
{ config, ... }:

{
  sops = {
    defaultSopsFile = ../secrets/ambxst-ai.yaml;
    age.keyFile = "/home/asura/.config/sops/age/keys.txt";
  };

  sops.secrets = {
    GEMINI_API_KEY = { owner = "asura"; mode = "0400"; };
  };
}
