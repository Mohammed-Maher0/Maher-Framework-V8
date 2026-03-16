#!/bin/bash
export PATH=$PATH:$HOME/go/bin:/usr/local/go/bin

TARGET=""
CUSTOM_HEADER=""

# ==========================================
# 1. استقبال المدخلات
# ==========================================
while getopts "d:H:" opt; do
  case $opt in
    d) TARGET="$OPTARG" ;;
    H) CUSTOM_HEADER="$OPTARG" ;;
    \?) echo -e "\e[31m[!] Usage: $0 -d <domain.com> [-H \"Header: Value\"]\e[0m"; exit 1 ;;
  esac
done

if [ -z "$TARGET" ]; then
    echo -e "\e[31m[!] Error: Target domain is required!\e[0m"
    echo -e "\e[33m[?] Usage: ./pwn.sh -d <domain.com> [-H \"X-Bug-Bounty: HackerOne-username\"]\e[0m"
    exit 1
fi

# ==========================================
# 2. اكتشاف تلقائي: هل الهدف سب دومين؟
# ==========================================
DOT_COUNT=$(echo "$TARGET" | tr -cd '.' | wc -c)
if [ "$DOT_COUNT" -ge 2 ]; then
    IS_SUBDOMAIN=true
    # استخلص الـ root domain من السب دومين
    ROOT_DOMAIN=$(echo "$TARGET" | awk -F. '{print $(NF-1)"."$NF}')
    echo -e "\e[33m[~] Subdomain mode detected. Target: $TARGET | Root: $ROOT_DOMAIN\e[0m"
else
    IS_SUBDOMAIN=false
    ROOT_DOMAIN="$TARGET"
fi

export IS_SUBDOMAIN
export ROOT_DOMAIN

# ==========================================
# 3. تصدير الهيدر للـ Environment
# ==========================================
if [ -n "$CUSTOM_HEADER" ]; then
    export CUSTOM_BBP_HEADER="$CUSTOM_HEADER"
fi

TIMESTAMP=$(date +%F_%H-%M)
WORK_DIR="targets/${TARGET}_hunt_${TIMESTAMP}"
mkdir -p "$WORK_DIR"

# حفظ إعدادات الجلسة
cat > "$WORK_DIR/.session" <<EOF
TARGET=$TARGET
ROOT_DOMAIN=$ROOT_DOMAIN
IS_SUBDOMAIN=$IS_SUBDOMAIN
TIMESTAMP=$TIMESTAMP
CUSTOM_HEADER=$CUSTOM_HEADER
EOF

echo -e "\e[32m"
echo "================================================="
echo "    MAHER FRAMEWORK V8 — THE DRAGON              "
echo "================================================="
echo "🎯 TARGET  : $TARGET"
if [ "$IS_SUBDOMAIN" = "true" ]; then
echo "🌐 MODE    : Subdomain Hunt (Root: $ROOT_DOMAIN)"
else
echo "🌐 MODE    : Full Domain Hunt"
fi
echo "📁 FOLDER  : $WORK_DIR"
echo "🕒 TIME    : $TIMESTAMP"
[ -n "$CUSTOM_HEADER" ] && echo "🛡️  HEADER  : $CUSTOM_HEADER"
echo "================================================="
echo -e "\e[0m"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# ==========================================
# 4. تشغيل المراحل بالترتيب
# ==========================================

echo -e "\e[34m[>] Phase 1: RECON...\e[0m"
if ! "$SCRIPT_DIR/recon.sh" "$TARGET" "$WORK_DIR"; then
    echo -e "\e[31m[!] Mission Aborted: Recon failed.\e[0m"
    exit 1
fi

echo -e "\e[34m[>] Phase 2: OSINT & LEAKS...\e[0m"
"$SCRIPT_DIR/osint.sh" "$TARGET" "$WORK_DIR"

echo -e "\e[34m[>] Phase 3: MINING...\e[0m"
"$SCRIPT_DIR/mine.sh" "$WORK_DIR"

echo -e "\e[34m[>] Phase 4: ATTACK...\e[0m"
"$SCRIPT_DIR/attack.sh" "$WORK_DIR"

echo -e "\e[34m[>] Phase 5: REPORT...\e[0m"
"$SCRIPT_DIR/report.sh" "$TARGET" "$WORK_DIR"

echo -e "\e[32m"
echo "================================================="
echo "✅ MISSION COMPLETE!"
echo "📄 Results : $WORK_DIR"
echo "📋 Report  : $WORK_DIR/REPORT.txt"
echo "================================================="
echo -e "\e[0m"
