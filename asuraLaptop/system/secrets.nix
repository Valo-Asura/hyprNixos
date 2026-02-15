# SOPS secrets for Ambxst AI + OpenClaw
{ config, ... }:

{
  sops = {
    defaultSopsFile = ../secrets/ambxst-ai.yaml;
    age.keyFile = "/home/asura/.config/sops/age/keys.txt";
  };

  sops.secrets = {
    GEMINI_API_KEY = { owner = "asura"; mode = "0400"; };
    # Additional AI keys (ambxst launcher loads these from /run/secrets/ if present)
    OPENAI_API_KEY = { owner = "asura"; mode = "0400"; neededForUsers = true; };
    OPENROUTER_API_KEY = { owner = "asura"; mode = "0400"; neededForUsers = true; };
    OPENCLAW_GATEWAY_TOKEN = { owner = "asura"; mode = "0400"; neededForUsers = true; };
  };
}
