# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a personal dotfiles repository using GNU Stow for symlink management. Each top-level directory represents a stow package that can be independently deployed.

## Stow Package Structure

Each package follows the pattern `<package>/.config/<app>/` which stows to `~/.config/<app>/`:

- **ghostty/** - Ghostty terminal emulator config
- **hammerspoon/** - macOS automation scripts (Lua)
- **karabiner/** - Keyboard customization (JSON)
- **nvim/** - AstroNvim v4+ configuration (Lua)
- **pip/** - pip mirror configuration
- **tmux/** - Tmux with TPM plugins (uses `.tmux.conf` in home)
- **zsh/** - Zsh shell config with Zimfw

## Quick Start: Automated Installation

For new machines, use the automated installer:

```bash
# Clone repository
git clone https://github.com/obiyoag/my_dotfiles.git ~/my_dotfiles
cd ~/my_dotfiles

# Run installer (one command to configure everything)
./install.sh
```

The script will:
- Verify prerequisites (GNU Stow required)
- Deploy all configs (claude, nvim, pip, tmux, zsh)
- Install Zimfw for Zsh
- Configure Tmux scripts
- Verify all symlinks

**Requirements**: git, stow (others can be installed after)

## Manual Deployment (Advanced)

```bash
# Deploy a single package (from repo root)
stow <package>

# Deploy all packages
stow */

# Remove a package's symlinks
stow -D <package>
```

## Key Configuration Details

**Zsh**: Uses Zimfw as plugin manager. Main entry is `~/.zshrc` → `~/.config/zsh/zshrc`. The zimrc file at `~/.config/zsh/zimrc` is symlinked to `~/.zimrc`.

**Neovim**: AstroNvim v4+ based. Plugin configs in `lua/plugins/`. Uses Lazy.nvim for plugin management. Theme is catppuccin-mocha.

**Tmux**: Prefix is `C-Space`. Uses TPM for plugins. Vim-style navigation with `h/j/k/l` bindings.
