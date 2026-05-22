#!/bin/bash
# "Things To Do!" script for a fresh Fedora Workstation installation



# Check if the script is run with sudo
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script with sudo"
    exit 1
fi

# Funtion to echo colored text
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

# Set variables
ACTUAL_USER=$SUDO_USER
ACTUAL_HOME=$(eval echo ~$SUDO_USER)
LOG_FILE="/var/log/fedora_things_to_do.log"
INITIAL_DIR=$(pwd)

# Function to generate timestamps
get_timestamp() {
    date +"%Y-%m-%d %H:%M:%S"
}

# Function to log messages
log_message() {
    local message="$1"
    echo "$(get_timestamp) - $message" | tee -a "$LOG_FILE"
}

# Function to handle errors
handle_error() {
    local exit_code=$?
    local message="$1"
    if [ $exit_code -ne 0 ]; then
        color_echo "red" "ERROR: $message"
        exit $exit_code
    fi
}

# Function to prompt for reboot
prompt_reboot() {
    sudo -u $ACTUAL_USER bash -c 'read -p "It is time to reboot the machine. Would you like to do it now? (y/n): " choice; [[ $choice == [yY] ]]'
    if [ $? -eq 0 ]; then
        color_echo "green" "Rebooting..."
        reboot
    else
        color_echo "red" "Reboot canceled."
    fi
}

# Function to backup configuration files
backup_file() {
    local file="$1"
    if [ -f "$file" ]; then
        cp "$file" "$file.bak"
        handle_error "Failed to backup $file"
        color_echo "green" "Backed up $file"
    fi
}

echo "";
echo "╔═════════════════════════════════════════════════════════════════════════════╗";
echo "║                                                                             ║";
echo "║   ░█▀▀░█▀▀░█▀▄░█▀█░█▀▄░█▀█░░░█░█░█▀█░█▀▄░█░█░█▀▀░▀█▀░█▀█░▀█▀░▀█▀░█▀█░█▀█░   ║";
echo "║   ░█▀▀░█▀▀░█░█░█░█░█▀▄░█▀█░░░█▄█░█░█░█▀▄░█▀▄░▀▀█░░█░░█▀█░░█░░░█░░█░█░█░█░   ║";
echo "║   ░▀░░░▀▀▀░▀▀░░▀▀▀░▀░▀░▀░▀░░░▀░▀░▀▀▀░▀░▀░▀░▀░▀▀▀░░▀░░▀░▀░░▀░░▀▀▀░▀▀▀░▀░▀░   ║";
echo "║   ░░░░░░░░░░░░▀█▀░█░█░▀█▀░█▀█░█▀▀░█▀▀░░░▀█▀░█▀█░░░█▀▄░█▀█░█░░░░░░░░░░░░░░   ║";
echo "║   ░░░░░░░░░░░░░█░░█▀█░░█░░█░█░█░█░▀▀█░░░░█░░█░█░░░█░█░█░█░▀░░░░░░░░░░░░░░   ║";
echo "║   ░░░░░░░░░░░░░▀░░▀░▀░▀▀▀░▀░▀░▀▀▀░▀▀▀░░░░▀░░▀▀▀░░░▀▀░░▀▀▀░▀░░░░░░░░░░░░░░   ║";
echo "║                                                                             ║";
echo "╚═════════════════════════════════════════════════════════════════════════════╝";
echo "";
echo "This script automates \"Things To Do!\" steps after a fresh Fedora Workstation installation"
echo "ver. 25.08 / 100 Stars Edition"
echo ""
echo "Don't run this script if you didn't build it yourself or don't know what it does."
echo ""
read -p "Press Enter to continue or CTRL+C to cancel..."

# System Upgrade
color_echo "blue" "Performing system upgrade... This may take a while..."
dnf upgrade -y


# System Configuration
# Set the system hostname to uniquely identify the machine on the network
color_echo "yellow" "Setting hostname..."
hostnamectl set-hostname 

# Optimize DNF package manager for faster downloads and efficient updates
color_echo "yellow" "Configuring DNF Package Manager..."
backup_file "/etc/dnf/dnf.conf"
dnf -y install dnf-plugins-core
# Max Parallel Downloads
echo "max_parallel_downloads=10" | tee -a /etc/dnf/dnf.conf > /dev/null
# Select Fastest Mirror
echo "fastestmirror=True" | tee -a /etc/dnf/dnf.conf > /dev/null
# Default Yes
echo "defaultyes=True" | tee -a /etc/dnf/dnf.conf > /dev/null

# Replace Fedora Flatpak Repo with Flathub for better package management and apps stability
color_echo "yellow" "Replacing Fedora Flatpak Repo with Flathub..."
dnf install -y flatpak
flatpak remote-delete fedora --force || true
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
sudo flatpak repair
flatpak update

# Check and apply firmware updates to improve hardware compatibility and performance
color_echo "yellow" "Checking for firmware updates..."
fwupdmgr refresh --force
fwupdmgr get-updates
fwupdmgr update -y

# Enable RPM Fusion repositories to access additional software packages and codecs
color_echo "yellow" "Enabling RPM Fusion repositories..."
dnf install -y https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
dnf install -y https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
dnf update @core -y

# Install multimedia codecs to enhance multimedia capabilities
color_echo "yellow" "Installing multimedia codecs..."
dnf swap ffmpeg-free ffmpeg --allowerasing -y
dnf update @multimedia --setopt="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin -y
dnf update @sound-and-video -y

# Install Hardware Accelerated Codecs for Intel integrated GPUs. This improves video playback and encoding performance on systems with Intel graphics.
color_echo "yellow" "Installing Intel Hardware Accelerated Codecs..."
dnf -y install intel-media-driver

# Install virtualization tools to enable virtual machines and containerization
color_echo "yellow" "Installing virtualization tools..."
dnf install -y @virtualization

# Configure power settings to prevent system sleep and hibernation
color_echo "yellow" "Configuring power settings..."
sudo -u $ACTUAL_USER gsettings set org.gnome.desktop.session idle-delay 0
sudo -u $ACTUAL_USER gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing'
sudo -u $ACTUAL_USER gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type 'nothing'
sudo -u $ACTUAL_USER gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-timeout 0
sudo -u $ACTUAL_USER gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-timeout 0
sudo -u $ACTUAL_USER gsettings set org.gnome.settings-daemon.plugins.power power-button-action 'suspend'


# App Installation
# Install essential applications
color_echo "yellow" "Installing essential applications..."
dnf install -y btop rsync unzip git wget curl gnome-tweaks dolphin
color_echo "green" "Essential applications installed successfully."

# Install Internet & Communication applications
color_echo "yellow" "Installing Google Chrome..."
if command -v dnf4 &>/dev/null; then
  dnf4 config-manager --set-enabled google-chrome
else
  dnf config-manager setopt google-chrome.enabled=1
fi
dnf install -y google-chrome-stable
color_echo "green" "Google Chrome installed successfully."
color_echo "yellow" "Installing Brave..."
dnf install -y dnf-plugins-core
if command -v dnf4 &>/dev/null; then
  dnf4 config-manager --add-repo https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo
else
  dnf config-manager --add-repo https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo
fi
rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc
dnf install -y brave-browser
color_echo "green" "Brave installed successfully."
color_echo "yellow" "Installing Discord..."
dnf install -y discord
color_echo "green" "Discord installed successfully."
color_echo "yellow" "Installing Signal Desktop..."
flatpak install -y flathub org.signal.Signal
color_echo "green" "Signal Desktop installed successfully."

# Install Office Productivity applications
color_echo "yellow" "Installing LibreOffice..."
dnf remove -y libreoffice*
flatpak install -y flathub org.libreoffice.LibreOffice
flatpak install -y --reinstall org.freedesktop.Platform.Locale/x86_64/24.08
flatpak install -y --reinstall org.libreoffice.LibreOffice.Locale
color_echo "green" "LibreOffice installed successfully."
color_echo "yellow" "Installing Bitwarden..."
flatpak install -y flathub com.bitwarden.desktop
color_echo "green" "Bitwarden installed successfully."

# Install Coding and DevOps applications
color_echo "yellow" "Installing Visual Studio Code..."
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
echo -e "[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/yum.repos.d/vscode.repo > /dev/null
dnf check-update
dnf install -y code
color_echo "green" "Visual Studio Code installed successfully."
color_echo "yellow" "Installing Docker..."
dnf remove -y docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-selinux docker-engine-selinux docker-engine --noautoremove
dnf -y install dnf-plugins-core
if command -v dnf4 &>/dev/null; then
  dnf4 config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
else
  dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
fi
dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
systemctl enable --now docker
systemctl enable --now containerd
groupadd docker
usermod -aG docker $ACTUAL_USER
rm -rf $ACTUAL_HOME/.docker
echo "Docker installed successfully. Please log out and back in for the group changes to take effect."
color_echo "green" "Docker installed successfully."
# Note: Docker group changes will take effect after logging out and back in
color_echo "yellow" "Installing Zsh and Oh My Zsh..."
dnf install -y zsh
sudo -u $ACTUAL_USER sh -c "RUNZSH=no $(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
chsh -s $(which zsh) $ACTUAL_USER
sudo -u $ACTUAL_USER bash << EOF
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-$ACTUAL_HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/marlonrichert/zsh-autocomplete.git ${ZSH_CUSTOM:-$ACTUAL_HOME/.oh-my-zsh/custom}/plugins/zsh-autocomplete
git clone https://github.com/zsh-users/zsh-history-substring-search ${ZSH_CUSTOM:-$ACTUAL_HOME/.oh-my-zsh/custom}/plugins/zsh-history-substring-search
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-$ACTUAL_HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
sed -i 's/plugins=(git)/plugins=(dnf aliases genpass git zsh-autosuggestions zsh-autocomplete zsh-history-substring-search z zsh-syntax-highlighting)/' $ACTUAL_HOME/.zshrc
sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="jonathan"/' $ACTUAL_HOME/.zshrc
EOF
color_echo "green" "Zsh and Oh My Zsh installed successfully."

# Install Media & Graphics applications
color_echo "yellow" "Installing VLC..."
dnf install -y vlc
color_echo "green" "VLC installed successfully."
color_echo "yellow" "Installing Spotify..."
flatpak install -y flathub com.spotify.Client
color_echo "green" "Spotify installed successfully."
color_echo "yellow" "Installing Inkscape..."
dnf install -y inkscape
color_echo "green" "Inkscape installed successfully."

# Install Gaming & Emulation applications
color_echo "yellow" "Installing Steam..."
dnf install -y steam
color_echo "green" "Steam installed successfully."

# Install Remote Networking applications
color_echo "yellow" "Installing RustDesk..."
flatpak install -y flathub com.rustdesk.RustDesk
color_echo "green" "RustDesk installed successfully."

# Install File Sharing & Download applications
color_echo "yellow" "Installing qBittorrent..."
dnf install -y qbittorrent
color_echo "green" "qBittorrent installed successfully."

# Install System Tools applications
color_echo "yellow" "Installing Extension Manager..."
flatpak install -y flathub com.mattjakeman.ExtensionManager
color_echo "green" "Extension Manager installed successfully."


# Customization

# Install FiraCode NerdFont
color_echo "yellow" "Installing FiraCode NerdFont..."
FONT_DIR="$ACTUAL_HOME/.local/share/fonts/FiraCode"
if [ ! -d "$FONT_DIR" ] || ! ls "$FONT_DIR"/*.ttf &>/dev/null; then
    FONT_TMP=$(mktemp -d)
    curl -fsSL https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/FiraCode.zip -o "$FONT_TMP/FiraCode.zip"
    unzip -q "$FONT_TMP/FiraCode.zip" -d "$FONT_TMP/FiraCode"
    mkdir -p "$FONT_DIR"
    cp "$FONT_TMP/FiraCode/"*.ttf "$FONT_DIR/"
    rm -rf "$FONT_TMP"
    chown -R $ACTUAL_USER:$ACTUAL_USER "$FONT_DIR"
    color_echo "green" "FiraCode NerdFont installed successfully."
else
    color_echo "green" "FiraCode NerdFont already installed, skipping download."
fi
fc-cache -fv

# Install The Ultimate vimrc
color_echo "yellow" "Installing The Ultimate vimrc..."
if [ ! -d "$ACTUAL_HOME/.vim_runtime" ]; then
    sudo -u $ACTUAL_USER git clone --depth=1 https://github.com/amix/vimrc.git $ACTUAL_HOME/.vim_runtime
    sudo -u $ACTUAL_USER sh $ACTUAL_HOME/.vim_runtime/install_awesome_vimrc.sh
    color_echo "green" "The Ultimate vimrc installed successfully."
else
    color_echo "green" "The Ultimate vimrc already installed, skipping."
fi

# Install Homebrew
color_echo "yellow" "Installing Homebrew..."
if ! sudo -u $ACTUAL_USER bash -c 'command -v brew &>/dev/null'; then
    sudo -u $ACTUAL_USER /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    color_echo "green" "Homebrew installed successfully."
else
    color_echo "green" "Homebrew already installed, skipping."
fi

# Install Homebrew packages
color_echo "yellow" "Installing Homebrew packages..."
sudo -u $ACTUAL_USER bash -c 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)" && brew install asdf node yarn fzf nnn delta starship'
color_echo "green" "Homebrew packages installed successfully."

# Custom user-defined commands
# Custom user-defined commands
echo "Created with ❤️ for Open Source"


# Before finishing, ensure we're in a safe directory
cd /tmp || cd $ACTUAL_HOME || cd /

# Finish
echo "";
echo "╔═════════════════════════════════════════════════════════════════════════╗";
echo "║                                                                         ║";
echo "║   ░█░█░█▀▀░█░░░█▀▀░█▀█░█▄█░█▀▀░░░▀█▀░█▀█░░░█▀▀░█▀▀░█▀▄░█▀█░█▀▄░█▀█░█░   ║";
echo "║   ░█▄█░█▀▀░█░░░█░░░█░█░█░█░█▀▀░░░░█░░█░█░░░█▀▀░█▀▀░█░█░█░█░█▀▄░█▀█░▀░   ║";
echo "║   ░▀░▀░▀▀▀░▀▀▀░▀▀▀░▀▀▀░▀░▀░▀▀▀░░░░▀░░▀▀▀░░░▀░░░▀▀▀░▀▀░░▀▀▀░▀░▀░▀░▀░▀░   ║";
echo "║                                                                         ║";
echo "╚═════════════════════════════════════════════════════════════════════════╝";
echo "";
color_echo "green" "All steps completed. Enjoy!"

# Prompt for reboot
prompt_reboot
