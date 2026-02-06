# SOPS secrets for Ambxst AI + OpenClaw
{ config, ... }:

{
  sops = {
    defaultSopsFile = ../secrets/ambxst-ai.yaml;
    age.keyFile = "/home/asura/.config/sops/age/keys.txt";
  };

  sops.secrets = {
    OPENCLAW_GATEWAY_TOKEN = { owner = "asura"; mode = "0400"; };
    OPENAI_API_KEY = { owner = "asura"; mode = "0400"; };
    OPENROUTER_API_KEY = { owner = "asura"; mode = "0400"; };
    GEMINI_API_KEY = { owner = "asura"; mode = "0400"; };
    MISTRAL_API_KEY = { owner = "asura"; mode = "0400"; };
    GITHUB_TOKEN = { owner = "asura"; mode = "0400"; };
  };
}
