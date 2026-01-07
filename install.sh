#!/usr/bin/env bash
# install.sh - Automated dotfiles installer for macOS and Ubuntu
#
# This script deploys dotfiles configurations using GNU Stow for:
# - claude: Claude Code CLI configuration
# - nvim: Neovim with AstroNvim v4+
# - pip: Python package manager mirror configuration
# - tmux: Terminal multiplexer with custom scripts
# - zsh: Zsh shell with Zimfw plugin manager
#
# Usage: ./install.sh

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# ============================================================================
# CONFIGURATION
# ============================================================================

PACKAGES=(pip claude zsh tmux nvim)  # Order matters: simple to complex
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$HOME/.dotfiles-install.log"

# Color codes for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'  # No Color

# ============================================================================
# LOGGING FUNCTIONS
# ============================================================================

log_info() {
  echo -e "${BLUE}[INFO]${NC} $*" | tee -a "$LOG_FILE"
}

log_success() {
  echo -e "${GREEN}[✓]${NC} $*" | tee -a "$LOG_FILE"
}

log_warn() {
  echo -e "${YELLOW}[WARN]${NC} $*" | tee -a "$LOG_FILE"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $*" | tee -a "$LOG_FILE"
}

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

detect_os() {
  case "$(uname -s)" in
    Darwin)
      echo "macos"
      ;;
    Linux)
      if [ -f /etc/os-release ]; then
        . /etc/os-release
        case "$ID" in
          ubuntu|debian)
            echo "ubuntu"
            ;;
          *)
            echo "linux"
            ;;
        esac
      else
        echo "linux"
      fi
      ;;
    *)
      echo "unknown"
      ;;
  esac
}

command_exists() {
  command -v "$1" &>/dev/null
}

# ============================================================================
# VALIDATION FUNCTIONS
# ============================================================================

check_prerequisites() {
  log_info "Checking prerequisites..."

  # Critical dependency: GNU Stow
  if ! command_exists stow; then
    log_error "GNU Stow is required but not installed"
    echo
    echo "Install Stow with:"
    echo "  macOS:   brew install stow"
    echo "  Ubuntu:  sudo apt install stow"
    echo
    exit 1
  fi
  log_info "Found: stow ($(stow --version | head -1))"

  # Optional but recommended tools
  local missing_tools=()
  for cmd in git zsh tmux nvim; do
    if ! command_exists "$cmd"; then
      missing_tools+=("$cmd")
      log_warn "$cmd not found. Configs will install but won't be usable until $cmd is installed."
    else
      log_info "Found: $cmd"
    fi
  done

  if [ ${#missing_tools[@]} -gt 0 ]; then
    echo
    log_warn "Missing tools: ${missing_tools[*]}"
    echo "Installation will continue, but you'll need to install these tools later."
    echo
  fi
}

verify_repo_structure() {
  log_info "Verifying repository structure..."

  local missing_packages=()
  for pkg in "${PACKAGES[@]}"; do
    if [ ! -d "$REPO_ROOT/$pkg" ]; then
      missing_packages+=("$pkg")
      log_error "Package directory not found: $REPO_ROOT/$pkg"
    fi
  done

  if [ ${#missing_packages[@]} -gt 0 ]; then
    log_error "Repository structure is invalid. Missing packages: ${missing_packages[*]}"
    exit 1
  fi

  log_success "Repository structure verified"
}

# ============================================================================
# STOW DEPLOYMENT FUNCTIONS
# ============================================================================

stow_package() {
  local package="$1"
  local package_dir="$REPO_ROOT/$package"

  if [ ! -d "$package_dir" ]; then
    log_error "Package directory not found: $package_dir"
    return 1
  fi

  log_info "Stowing package: $package"

  # Use -R (restow) to handle existing symlinks gracefully
  # Use -v (verbose) for detailed output
  # Use -t (target) to specify home directory
  # Use -d (directory) to specify stow directory
  if stow -R -v -t "$HOME" -d "$REPO_ROOT" "$package" >> "$LOG_FILE" 2>&1; then
    log_success "Stowed $package"
    return 0
  else
    log_error "Failed to stow $package (see $LOG_FILE for details)"
    return 1
  fi
}

deploy_all_packages() {
  log_info "Deploying all packages..."
  echo

  local failed_packages=()

  for pkg in "${PACKAGES[@]}"; do
    if ! stow_package "$pkg"; then
      failed_packages+=("$pkg")
    fi
  done

  echo

  if [ ${#failed_packages[@]} -gt 0 ]; then
    log_error "Failed to deploy packages: ${failed_packages[*]}"
    echo
    echo "Common issues:"
    echo "  - Existing files that are not symlinks (backup and remove them)"
    echo "  - Permission errors (check file ownership)"
    echo "  - Incorrect directory structure"
    echo
    echo "Check the log file for details: $LOG_FILE"
    return 1
  fi

  log_success "All packages deployed successfully"
  return 0
}

# ============================================================================
# POST-INSTALLATION SETUP FUNCTIONS
# ============================================================================

setup_zsh_zimfw() {
  if ! command_exists zsh; then
    log_warn "Zsh not found, skipping Zimfw setup"
    return 0
  fi

  log_info "Setting up Zimfw for Zsh..."

  # Create ~/.zimrc symlink if needed
  if [ ! -L "$HOME/.zimrc" ]; then
    log_info "Creating ~/.zimrc symlink"
    ln -sf "$HOME/.config/zsh/zimrc" "$HOME/.zimrc"
    log_success "Created ~/.zimrc -> ~/.config/zsh/zimrc"
  else
    local target
    target=$(readlink "$HOME/.zimrc")
    if [ "$target" != "$HOME/.config/zsh/zimrc" ]; then
      log_warn "~/.zimrc exists but points to $target, updating..."
      ln -sf "$HOME/.config/zsh/zimrc" "$HOME/.zimrc"
      log_success "Updated ~/.zimrc symlink"
    else
      log_info "~/.zimrc symlink already correct"
    fi
  fi

  # Install Zimfw if ~/.zim doesn't exist
  if [ ! -d "$HOME/.zim" ]; then
    log_info "Installing Zimfw (this may take 30-60 seconds)..."

    if curl -fsSL https://raw.githubusercontent.com/zimfw/install/master/install.zsh | zsh >> "$LOG_FILE" 2>&1; then
      log_success "Zimfw installed to ~/.zim"
    else
      log_warn "Zimfw installation failed, but it will auto-install on first shell launch"
      return 0
    fi
  else
    log_info "Zimfw already installed at ~/.zim"
  fi

  # Update Zimfw modules if zimfw command is available
  if command_exists zimfw; then
    log_info "Installing/updating Zimfw modules..."
    if zimfw install >> "$LOG_FILE" 2>&1; then
      log_success "Zimfw modules updated"
    else
      log_warn "Failed to update Zimfw modules, run 'zimfw install' manually if needed"
    fi
  fi
}

setup_tmux_scripts() {
  log_info "Setting up Tmux scripts..."

  if [ -d "$HOME/.config/tmux/scripts" ]; then
    # Make all scripts executable
    chmod +x "$HOME/.config/tmux/scripts"/*.sh 2>/dev/null || true
    chmod +x "$HOME/.config/tmux/scripts"/*.py 2>/dev/null || true
    log_success "Tmux scripts made executable"
  else
    log_warn "Tmux scripts directory not found at ~/.config/tmux/scripts"
  fi

  if [ -d "$HOME/.config/tmux/status" ]; then
    chmod +x "$HOME/.config/tmux/status"/*.sh 2>/dev/null || true
    log_success "Tmux status scripts made executable"
  else
    log_warn "Tmux status directory not found at ~/.config/tmux/status"
  fi
}

verify_symlinks() {
  log_info "Verifying critical symlinks..."

  local critical_links=(
    "$HOME/.zshrc"
    "$HOME/.tmux.conf"
    "$HOME/.config/nvim/init.lua"
    "$HOME/.config/zsh/zshrc"
    "$HOME/.config/pip/pip.conf"
    "$HOME/.config/claude/system-prompt.txt"
  )

  local all_good=true
  for link in "${critical_links[@]}"; do
    if [ ! -e "$link" ]; then
      log_error "Missing or broken symlink: $link"
      all_good=false
    fi
  done

  if $all_good; then
    log_success "All critical symlinks verified"
    return 0
  else
    log_error "Some symlinks are missing or broken"
    return 1
  fi
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

show_banner() {
  echo
  echo "═══════════════════════════════════════════════════════════════"
  echo "            Dotfiles Installer for macOS & Ubuntu"
  echo "═══════════════════════════════════════════════════════════════"
  echo
  echo "Repository:  $REPO_ROOT"
  echo "OS:          $(detect_os)"
  echo "Packages:    ${PACKAGES[*]}"
  echo "Log file:    $LOG_FILE"
  echo
  echo "This script will:"
  echo "  1. Verify prerequisites (stow, etc.)"
  echo "  2. Deploy configs using GNU Stow"
  echo "  3. Setup Zimfw for Zsh"
  echo "  4. Configure Tmux scripts"
  echo "  5. Verify installation"
  echo
  echo "═══════════════════════════════════════════════════════════════"
  echo
}

show_summary() {
  echo
  echo "═══════════════════════════════════════════════════════════════"
  echo "                    Installation Complete!"
  echo "═══════════════════════════════════════════════════════════════"
  echo
  log_success "Dotfiles installation finished successfully!"
  echo
  echo "Next steps:"
  echo
  echo "  1. Restart your shell:"
  echo "     $ exec zsh"
  echo
  echo "  2. Launch Neovim to install plugins (first launch ~1-2 min):"
  echo "     $ nvim"
  echo
  echo "  3. Launch Tmux to verify configuration:"
  echo "     $ tmux"
  echo
  echo "Troubleshooting:"
  echo "  - Zsh errors:  Run 'zimfw install' to reinstall modules"
  echo "  - Nvim errors: Lazy.nvim will auto-bootstrap on first launch"
  echo "  - View logs:   cat $LOG_FILE"
  echo
  echo "═══════════════════════════════════════════════════════════════"
  echo
}

main() {
  # Initialize log file
  echo "Dotfiles installation started at $(date)" > "$LOG_FILE"
  echo "Repository: $REPO_ROOT" >> "$LOG_FILE"
  echo "OS: $(detect_os)" >> "$LOG_FILE"
  echo >> "$LOG_FILE"

  # Show banner
  show_banner

  # Phase 1: Validation
  check_prerequisites
  verify_repo_structure
  echo

  # Phase 2: Deployment
  if ! deploy_all_packages; then
    log_error "Deployment failed. Please fix errors and try again."
    exit 1
  fi

  # Phase 3: Post-installation setup
  if command_exists zsh; then
    echo
    setup_zsh_zimfw
  fi

  echo
  setup_tmux_scripts

  # Phase 4: Verification
  echo
  if ! verify_symlinks; then
    log_warn "Some verifications failed, but installation may still be usable"
  fi

  # Phase 5: Summary
  show_summary

  echo "Installation completed at $(date)" >> "$LOG_FILE"
}

# Run main function
main "$@"
