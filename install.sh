#!/bin/bash
# ============================================
# MAHER FRAMEWORK V8 — INSTALLER
# ============================================
export PATH=$PATH:$HOME/go/bin:/usr/local/go/bin

echo "=========================================="
echo "🛠️  MAHER V8 — Tool Installer"
echo "=========================================="

# تأكد إن Go موجودة
if ! command -v go &>/dev/null; then
    echo "[!] Go is not installed! Install it first:"
    echo "    https://go.dev/doc/install"
    exit 1
fi

echo "[+] Go found: $(go version)"
echo ""

install_go_tool() {
    local NAME=$1
    local PKG=$2
    if command -v "$NAME" &>/dev/null; then
        echo "  ✅ $NAME already installed"
    else
        echo "  📦 Installing $NAME..."
        go install "$PKG" 2>/dev/null && echo "  ✅ $NAME installed" || echo "  ❌ Failed to install $NAME"
    fi
}

install_pip_tool() {
    local NAME=$1
    local PKG=$2
    if command -v "$NAME" &>/dev/null; then
        echo "  ✅ $NAME already installed"
    else
        echo "  📦 Installing $NAME..."
        pip3 install "$PKG" --break-system-packages --quiet 2>/dev/null && echo "  ✅ $NAME installed" || echo "  ❌ Failed: $NAME"
    fi
}

echo "[1] Core Recon Tools"
install_go_tool "subfinder"   "github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest"
install_go_tool "cero"        "github.com/glebarez/cero@latest"
install_go_tool "puredns"     "github.com/d3mondev/puredns/v2@latest"
install_go_tool "alterx"      "github.com/projectdiscovery/alterx/cmd/alterx@latest"
install_go_tool "dnsx"        "github.com/projectdiscovery/dnsx/cmd/dnsx@latest"
install_go_tool "asnmap"      "github.com/projectdiscovery/asnmap/cmd/asnmap@latest"
install_go_tool "naabu"       "github.com/projectdiscovery/naabu/cmd/naabu@latest"
install_go_tool "httpx"       "github.com/projectdiscovery/httpx/cmd/httpx@latest"

echo ""
echo "[2] URL Mining Tools"
install_go_tool "gau"              "github.com/lc/gau/v2/cmd/gau@latest"
install_go_tool "katana"           "github.com/projectdiscovery/katana/cmd/katana@latest"
install_go_tool "waybackurls"      "github.com/tomnomnom/waybackurls@latest"
install_go_tool "github-subdomains" "github.com/gwen001/github-subdomains@latest"
install_pip_tool "uro"             "uro"

echo ""
echo "[3] Attack Tools"
install_go_tool "nuclei"    "github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest"
install_go_tool "dalfox"    "github.com/hahwul/dalfox/v2@latest"
install_go_tool "ffuf"      "github.com/ffuf/ffuf/v2@latest"

# sqlmap
if command -v sqlmap &>/dev/null; then
    echo "  ✅ sqlmap already installed"
else
    echo "  📦 Installing sqlmap..."
    sudo apt-get install -y sqlmap -qq 2>/dev/null || pip3 install sqlmap --quiet 2>/dev/null
    command -v sqlmap &>/dev/null && echo "  ✅ sqlmap installed" || echo "  ❌ Install manually: sudo apt install sqlmap"
fi

echo ""
echo "[4] OSINT Tools"
# TruffleHog
if command -v trufflehog &>/dev/null; then
    echo "  ✅ trufflehog already installed"
else
    echo "  📦 Installing TruffleHog..."
    curl -sSfL https://raw.githubusercontent.com/trufflesecurity/trufflehog/main/scripts/install.sh \
        | sudo sh -s -- -b /usr/local/bin 2>/dev/null \
        && echo "  ✅ trufflehog installed" \
        || echo "  ❌ Failed: trufflehog — install manually from https://github.com/trufflesecurity/trufflehog"
fi

# cloud_enum
install_pip_tool "cloud_enum" "cloud-enum"

echo ""
echo "[5] Updating Nuclei Templates..."
nuclei -update-templates -silent 2>/dev/null && echo "  ✅ Templates updated" || echo "  ⚠️  Template update failed (run: nuclei -update-templates)"

echo ""
echo "[6] Setting executable permissions..."
chmod +x pwn.sh recon.sh osint.sh mine.sh attack.sh report.sh 2>/dev/null
echo "  ✅ Done"

echo ""
echo "=========================================="
echo "✅ Installation Complete!"
echo ""
echo "OPTIONAL SETUP:"
echo "  export GITHUB_TOKEN=ghp_xxx          # for GitHub subdomain hunting"
echo "  export TG_TOKEN=xxx                  # for Telegram notifications"
echo "  export TG_CHAT=xxx                   # your Telegram chat ID"
echo ""
echo "USAGE:"
echo "  ./pwn.sh -d target.com"
echo "  ./pwn.sh -d target.com -H \"X-Bug-Bounty: HackerOne-username\""
echo "  ./pwn.sh -d sub.target.com           # subdomain mode auto-detected"
echo "=========================================="
