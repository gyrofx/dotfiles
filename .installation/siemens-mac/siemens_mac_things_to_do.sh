#!/bin/bash
# "Things To Do!" script for a fresh Siemens (business) Mac
# Run as your normal user, NOT with sudo:  bash siemens_mac_things_to_do.sh

# Function to echo colored text
color_echo() {
    local color="$1"
    local text="$2"
    case "$color" in
        "red")     echo -e "\033[0;31m$text\033[0m" ;;
        "green")   echo -e "\033[0;32m$text\033[0m" ;;
        "yellow")  echo -e "\033[1;33m$text\033[0m" ;;
        "blue")    echo -e "\033[0;34m$text\033[0m" ;;
        *)         echo "$text" ;;
    esac
}

# Only run on macOS
if [ "$(uname)" != "Darwin" ]; then
    color_echo "red" "This script is for macOS only."
    exit 1
fi

# Homebrew refuses to run as root
if [ "$EUID" -eq 0 ]; then
    color_echo "red" "Please run this script as your normal user, not with sudo."
    exit 1
fi

# Set variables
LOG_FILE="$HOME/Library/Logs/siemens_mac_things_to_do.log"
FAILED=()

# Function to generate timestamps
get_timestamp() {
    date +"%Y-%m-%d %H:%M:%S"
}

# Function to log messages
log_message() {
    local message="$1"
    echo "$(get_timestamp) - $message" | tee -a "$LOG_FILE"
}

# Install Homebrew formulae, skipping already installed ones
brew_formula() {
    local pkg
    for pkg in "$@"; do
        if brew list --formula "$pkg" &>/dev/null; then
            color_echo "green" "$pkg already installed, skipping."
        elif brew install "$pkg"; then
            log_message "Installed formula $pkg"
        else
            color_echo "red" "ERROR: failed to install $pkg"
            log_message "FAILED formula $pkg"
            FAILED+=("$pkg")
        fi
    done
}

# Install Homebrew casks, skipping already installed ones
brew_cask() {
    local pkg
    for pkg in "$@"; do
        if brew list --cask "$pkg" &>/dev/null; then
            color_echo "green" "$pkg already installed, skipping."
        elif brew install --cask "$pkg"; then
            log_message "Installed cask $pkg"
        else
            color_echo "red" "ERROR: failed to install $pkg"
            log_message "FAILED cask $pkg"
            FAILED+=("$pkg")
        fi
    done
}

# Clone a git repo if the target directory does not exist yet
git_clone_once() {
    local repo="$1"
    local dir="$2"
    if [ -d "$dir" ]; then
        color_echo "green" "$(basename "$dir") already present, skipping."
    else
        git clone --depth=1 "$repo" "$dir"
    fi
}

echo ""
echo "╔═════════════════════════════════════════════════╗"
echo "║                                                 ║"
echo "║     Siemens Mac  ·  Things To Do!               ║"
echo "║                                                 ║"
echo "╚═════════════════════════════════════════════════╝"
echo ""
echo "This script installs the tools and apps for a fresh Siemens Mac."
echo "Everything is installed with Homebrew. The script is safe to re-run."
echo ""
read -r -p "Press Enter to continue or CTRL+C to cancel..."

mkdir -p "$(dirname "$LOG_FILE")"


# Xcode Command Line Tools (git, compilers, needed by Homebrew)
# Full Xcode is only available from the App Store.
color_echo "yellow" "Checking Xcode Command Line Tools..."
if ! xcode-select -p &>/dev/null; then
    xcode-select --install
    color_echo "yellow" "Waiting for the Command Line Tools installer to finish..."
    until xcode-select -p &>/dev/null; do
        sleep 5
    done
    color_echo "green" "Xcode Command Line Tools installed successfully."
else
    color_echo "green" "Xcode Command Line Tools already installed, skipping."
fi


# Homebrew
color_echo "yellow" "Installing Homebrew..."
export HOMEBREW_NO_ANALYTICS=1
if [ -x /opt/homebrew/bin/brew ]; then
    BREW_BIN=/opt/homebrew/bin/brew
elif [ -x /usr/local/bin/brew ]; then
    BREW_BIN=/usr/local/bin/brew
else
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    if [ -x /opt/homebrew/bin/brew ]; then
        BREW_BIN=/opt/homebrew/bin/brew
    else
        BREW_BIN=/usr/local/bin/brew
    fi
fi
if [ ! -x "$BREW_BIN" ]; then
    color_echo "red" "ERROR: Homebrew installation failed."
    exit 1
fi
eval "$("$BREW_BIN" shellenv)"
SHELLENV_LINE="eval \"\$($BREW_BIN shellenv)\""
if ! grep -qsF "$SHELLENV_LINE" "$HOME/.zprofile"; then
    echo "$SHELLENV_LINE" >> "$HOME/.zprofile"
    color_echo "green" "Added Homebrew to ~/.zprofile"
fi
brew update
color_echo "green" "Homebrew ready."


# Essential command line tools (curl ships with macOS)
color_echo "yellow" "Installing essential command line tools..."
brew_formula rsync git wget


# Applications
color_echo "yellow" "Installing applications..."
brew_cask keeper-password-manager bitwarden visual-studio-code spotify raycast displaylink stats


# FiraCode NerdFont
color_echo "yellow" "Installing FiraCode NerdFont..."
brew_cask font-fira-code-nerd-font


# Development tools
color_echo "yellow" "Installing development tools..."
brew_formula asdf yarn fzf nnn git-delta starship
brew tap oven-sh/bun
brew_formula bun


# AI command line tools
color_echo "yellow" "Installing Claude Code and GitHub Copilot CLI..."
brew_cask claude-code
brew_formula copilot-cli


# Containers: Podman instead of Docker Desktop (Docker Desktop needs a paid licence in large companies)
color_echo "yellow" "Installing Podman..."
brew_formula podman
brew_cask podman-desktop
if command -v podman &>/dev/null; then
    if ! podman machine inspect &>/dev/null; then
        podman machine init
    fi
    podman machine start 2>/dev/null || true
    color_echo "green" "Podman ready. Tip: add 'alias docker=podman' to ~/.zshrc.local if you want the docker command."
fi


# Testing: apps under evaluation, easy to remove later
color_echo "yellow" "Installing apps for testing..."
brew tap manaflow-ai/cmux
brew_cask cmux


# Oh My Zsh and plugins (zsh is already the default shell on macOS)
color_echo "yellow" "Installing Oh My Zsh..."
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
    color_echo "green" "Oh My Zsh already installed, skipping."
fi
ZSH_CUSTOM_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
git_clone_once https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM_DIR/plugins/zsh-autosuggestions"
git_clone_once https://github.com/marlonrichert/zsh-autocomplete.git "$ZSH_CUSTOM_DIR/plugins/zsh-autocomplete"
git_clone_once https://github.com/zsh-users/zsh-history-substring-search "$ZSH_CUSTOM_DIR/plugins/zsh-history-substring-search"
git_clone_once https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM_DIR/plugins/zsh-syntax-highlighting"
color_echo "green" "Oh My Zsh and plugins installed successfully."


# The Ultimate vimrc
color_echo "yellow" "Installing The Ultimate vimrc..."
if [ ! -d "$HOME/.vim_runtime" ]; then
    git clone --depth=1 https://github.com/amix/vimrc.git "$HOME/.vim_runtime"
    sh "$HOME/.vim_runtime/install_awesome_vimrc.sh"
    color_echo "green" "The Ultimate vimrc installed successfully."
else
    color_echo "green" "The Ultimate vimrc already installed, skipping."
fi


# Finish
echo ""
echo "╔═════════════════════════════════════════════════╗"
echo "║                                                 ║"
echo "║     Welcome to your Siemens Mac!                ║"
echo "║                                                 ║"
echo "╚═════════════════════════════════════════════════╝"
echo ""
if [ ${#FAILED[@]} -gt 0 ]; then
    color_echo "red" "These packages failed to install: ${FAILED[*]}"
    color_echo "red" "See $LOG_FILE and re-run the script to retry."
else
    color_echo "green" "All steps completed. Enjoy!"
fi
echo ""
echo "Next steps:"
echo "  - Check out the dotfiles (see README.md, 'Install')"
echo "  - DisplayLink Manager: allow Screen Recording in System Settings > Privacy & Security"
echo "  - Set the terminal / VS Code font to 'FiraCode Nerd Font'"
echo "  - Open a new terminal to load the new shell setup"
