#!/usr/bin/env bash

set -e

echo "=== Neovim Config Installer ==="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Detect package manager
detect_package_manager() {
    if command -v pacman &> /dev/null; then
        echo "pacman"
    elif command -v apt &> /dev/null; then
        echo "apt"
    elif command -v dnf &> /dev/null; then
        echo "dnf"
    else
        echo "unknown"
    fi
}

PKG_MANAGER=$(detect_package_manager)

echo -e "${GREEN}Detected package manager: $PKG_MANAGER${NC}"
echo ""

# Check if nvim is installed
if ! command -v nvim &> /dev/null; then
    echo -e "${RED}Neovim not found!${NC}"
    echo "Install it first, then run this script again."
    exit 1
fi

# Check nvim version
NVIM_VERSION=$(nvim --version | head -n1 | grep -oP 'v\K[0-9]+\.[0-9]+' || echo "0.0")
echo -e "${GREEN}✓ Neovim found (version $NVIM_VERSION)${NC}"

if command -v bc &> /dev/null; then
    if (( $(echo "$NVIM_VERSION < 0.9" | bc -l) )); then
        echo -e "${YELLOW}⚠ Warning: Neovim 0.9+ recommended for best compatibility${NC}"
    fi
fi

# Backup existing config
if [ -d "$HOME/.config/nvim" ]; then
    BACKUP_DIR="$HOME/.config/nvim.backup.$(date +%Y%m%d_%H%M%S)"
    echo -e "${YELLOW}Backing up existing config to $BACKUP_DIR${NC}"
    mv "$HOME/.config/nvim" "$BACKUP_DIR"
fi

# Clean up old plugin data (important for noice issues)
if [ -d "$HOME/.local/share/nvim/lazy" ]; then
    echo -e "${YELLOW}Cleaning old lazy.nvim plugin data...${NC}"
    rm -rf "$HOME/.local/share/nvim/lazy"
fi

# Create config directory
mkdir -p "$HOME/.config/nvim"

# Copy init.lua (assumes it's in the same directory as the script)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/init.lua" ]; then
    cp "$SCRIPT_DIR/init.lua" "$HOME/.config/nvim/init.lua"
    echo -e "${GREEN}✓ Copied init.lua${NC}"
else
    echo -e "${RED}Error: init.lua not found in $SCRIPT_DIR${NC}"
    exit 1
fi

# Install dependencies based on package manager
echo ""
echo "=== Installing dependencies ==="
echo ""

install_arch_deps() {
    echo "Installing packages..."
    sudo pacman -S --needed base-devel git ripgrep fd lazygit \
        lua-language-server stylua luacheck \
        rust-analyzer \
        python-pyright python-ruff \
        clang \
        jdk-openjdk \
        nodejs npm
    
    # Formatters/linters via npm
    sudo npm install -g typescript typescript-language-server eslint
}

install_debian_deps() {
    echo "Installing packages..."
    sudo apt update
    sudo apt install -y build-essential git ripgrep fd-find lazygit \
        clang clangd \
        python3-pip \
        default-jdk \
        nodejs npm
    
    # Language servers and tools via npm/pip
    sudo npm install -g lua-language-server typescript typescript-language-server eslint
    pip3 install --user pyright ruff
    
    # stylua (if cargo available)
    if command -v cargo &> /dev/null; then
        cargo install stylua
    else
        echo -e "${YELLOW}Note: stylua requires Rust - install it manually if needed${NC}"
    fi
}

install_fedora_deps() {
    echo "Installing packages..."
    sudo dnf install -y @development-tools git ripgrep fd-find lazygit \
        clang clang-tools-extra \
        python3-pip \
        java-latest-openjdk-devel \
        nodejs npm
    
    # Language servers and tools
    sudo npm install -g lua-language-server typescript typescript-language-server eslint
    pip3 install --user pyright ruff
    
    # stylua (if cargo available)
    if command -v cargo &> /dev/null; then
        cargo install stylua
    else
        echo -e "${YELLOW}Note: stylua requires Rust - install it manually if needed${NC}"
    fi
}

case $PKG_MANAGER in
    pacman)
        install_arch_deps
        echo -e "${GREEN}✓ Dependencies installed${NC}"
        ;;
    apt)
        install_debian_deps
        echo -e "${GREEN}✓ Dependencies installed${NC}"
        ;;
    dnf)
        install_fedora_deps
        echo -e "${GREEN}✓ Dependencies installed${NC}"
        ;;
    *)
        echo -e "${RED}Unknown package manager. Install dependencies manually:${NC}"
        echo ""
        echo "Required:"
        echo "  - git, gcc, make"
        echo "  - ripgrep, fd, lazygit"
        echo ""
        echo "Language servers (Mason will auto-install most):"
        echo "  - lua-language-server"
        echo "  - rust-analyzer"
        echo "  - pyright"
        echo "  - clangd"
        echo "  - typescript-language-server"
        echo ""
        echo "Formatters:"
        echo "  - stylua (lua)"
        echo "  - nixfmt (nix)"
        echo ""
        echo "Linters:"
        echo "  - luacheck"
        echo "  - ruff (python)"
        echo "  - cppcheck"
        echo "  - eslint"
        ;;
esac

echo ""
echo "=== Setup complete! ==="
echo ""
echo "Next steps:"
echo "  1. Open Neovim: nvim"
echo "  2. Wait for lazy.nvim to auto-install plugins"
echo "  3. Close Neovim (:q) and reopen it"
echo "  4. Run :checkhealth to verify everything works"
echo ""
echo -e "${YELLOW}Important: First launch will take a minute while plugins install.${NC}"
echo -e "${YELLOW}You might see some errors initially - this is normal!${NC}"
echo -e "${YELLOW}Everything will work after the initial plugin sync completes.${NC}"
echo ""
echo "Useful keybindings:"
echo "  <Space>ff - Find files (Telescope)"
echo "  <Space>fg - Live grep"
echo "  <Space>fb - Buffer list"
echo "  <Space>e  - File explorer (Neo-tree)"
echo "  <Space>o  - Oil (directory editor)"
echo "  <Space>lg - Lazygit"
echo "  <Space>h  - Harpoon menu"
echo "  <Space>a  - Harpoon add file"
echo "  <C-\\>    - Toggle terminal"
echo ""
echo "LSP keybindings (when in a file with LSP):"
echo "  gd        - Go to definition"
echo "  gr        - Go to references"
echo "  K         - Hover documentation"
echo "  <Space>ca - Code actions"
echo ""
echo "Happy vimming! 🚀"
