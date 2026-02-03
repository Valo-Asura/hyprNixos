# Direnv templates for different project types
{ pkgs, ... }:

{
  home.file = {
    # Node.js project template
    ".config/direnv/templates/node.envrc".text = ''
      # Node.js development environment
      use node 20
      
      # Add node_modules/.bin to PATH
      PATH_add node_modules/.bin
      
      # Set NODE_ENV for development
      export NODE_ENV=development
      
      # Enable pnpm if available
      if has pnpm; then
        export PNPM_HOME="$PWD/.pnpm"
        PATH_add "$PNPM_HOME"
      fi
    '';
    
    # Python project template
    ".config/direnv/templates/python.envrc".text = ''
      # Python development environment
      use flake
      
      # Create and activate virtual environment
      layout python python3
      
      # Set PYTHONPATH
      export PYTHONPATH="$PWD:$PYTHONPATH"
      
      # Development settings
      export PYTHONDONTWRITEBYTECODE=1
      export PYTHONUNBUFFERED=1
    '';
    
    # Rust project template
    ".config/direnv/templates/rust.envrc".text = ''
      # Rust development environment
      use flake
      
      # Set RUST_LOG for development
      export RUST_LOG=debug
      
      # Enable rust-analyzer
      export RUST_SRC_PATH="$(rustc --print sysroot)/lib/rustlib/src/rust/library"
      
      # Add cargo bin to PATH
      PATH_add "$HOME/.cargo/bin"
    '';
    
    # NixOS project template
    ".config/direnv/templates/nix.envrc".text = ''
      # Nix development environment
      use flake
      
      # Enable nix-direnv for better performance
      if ! has nix_direnv_version || ! nix_direnv_version 3.0.4; then
        source_url "https://raw.githubusercontent.com/nix-community/nix-direnv/3.0.4/direnvrc" "sha256-DzlYZ33mWF/Gs8DDeyjr8mnVmQGx7ASYqA5WlxwvBG4="
      fi
      
      use flake
    '';
    
    # Generic development template
    ".config/direnv/templates/generic.envrc".text = ''
      # Generic development environment
      use flake
      
      # Add local bin to PATH
      PATH_add bin
      PATH_add scripts
      
      # Set development environment
      export ENV=development
      export DEBUG=1
    '';
  };
  
  # Helper script to copy templates
  home.packages = [
    (pkgs.writeShellScriptBin "init-envrc" ''
      if [ $# -eq 0 ]; then
        echo "Usage: init-envrc <template>"
        echo "Available templates:"
        echo "  node     - Node.js project"
        echo "  python   - Python project"
        echo "  rust     - Rust project"
        echo "  nix      - NixOS project"
        echo "  generic  - Generic project"
        exit 1
      fi
      
      template="$1"
      template_file="$HOME/.config/direnv/templates/$template.envrc"
      
      if [ ! -f "$template_file" ]; then
        echo "Template '$template' not found!"
        exit 1
      fi
      
      if [ -f ".envrc" ]; then
        echo "Warning: .envrc already exists!"
        read -p "Overwrite? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
          exit 1
        fi
      fi
      
      cp "$template_file" .envrc
      echo "Created .envrc from $template template"
      echo "Run 'direnv allow' to activate the environment"
    '')
  ];
}