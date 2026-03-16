#!/bin/bash

TARGET=$1
WORK_DIR=$2

if [ -z "$TARGET" ] || [ -z "$WORK_DIR" ]; then
    echo -e "\e[31m[!] Usage: ./report.sh <target> <work_dir>\e[0m"
    exit 1
fi

# ==========================================
# Telegram Config (اختياري — ضع الـ token والـ chat id)
# export TG_TOKEN="your_bot_token"
# export TG_CHAT="your_chat_id"
# ==========================================

send_tg() {
    local MSG=$1
    if [ -n "$TG_TOKEN" ] && [ -n "$TG_CHAT" ]; then
        curl -s -X POST "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" \
            -d "chat_id=${TG_CHAT}" \
            -d "parse_mode=HTML" \
            -d "text=${MSG}" > /dev/null 2>&1
    fi
}

send_tg_file() {
    local FILE=$1
    local CAPTION=$2
    if [ -n "$TG_TOKEN" ] && [ -n "$TG_CHAT" ] && [ -f "$FILE" ]; then
        curl -s -X POST "https://api.telegram.org/bot${TG_TOKEN}/sendDocument" \
            -F "chat_id=${TG_CHAT}" \
            -F "document=@${FILE}" \
            -F "caption=${CAPTION}" > /dev/null 2>&1
    fi
}

echo "=========================================="
echo "📋 [5] REPORT Phase V8 — FINAL SUMMARY"
echo "=========================================="

cd "$WORK_DIR" || exit 1
REPORT="REPORT.txt"
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

# ==========================================
# بناء الريبورت
# ==========================================
cat > "$REPORT" <<EOF
╔══════════════════════════════════════════════════════════╗
║          MAHER FRAMEWORK V8 — HUNT REPORT                ║
╚══════════════════════════════════════════════════════════╝
  Target  : $TARGET
  Date    : $TIMESTAMP
  Folder  : $WORK_DIR
══════════════════════════════════════════════════════════

[1] RECON SUMMARY
──────────────────
EOF

# Recon stats
LIVE_HOSTS=$(wc -l < alive.txt 2>/dev/null || echo "0")
TOTAL_SUBS=$(wc -l < all_valid_subs.txt 2>/dev/null || echo "0")
TOTAL_URLS=$(wc -l < all_urls.txt 2>/dev/null || echo "0")
TOTAL_PARAMS=$(wc -l < all_params.txt 2>/dev/null || echo "0")

cat >> "$REPORT" <<EOF
  Total Subdomains : $TOTAL_SUBS
  Live Hosts       : $LIVE_HOSTS
  Total URLs       : $TOTAL_URLS
  Parameterized    : $TOTAL_PARAMS

[2] MINING SUMMARY
──────────────────
  XSS targets   : $(wc -l < mining/xss.txt 2>/dev/null || echo 0)
  SQLi targets  : $(wc -l < mining/sqli.txt 2>/dev/null || echo 0)
  LFI targets   : $(wc -l < mining/lfi.txt 2>/dev/null || echo 0)
  SSRF targets  : $(wc -l < mining/ssrf_redirect.txt 2>/dev/null || echo 0)
  RCE targets   : $(wc -l < mining/rce.txt 2>/dev/null || echo 0)
  IDOR targets  : $(wc -l < mining/idor.txt 2>/dev/null || echo 0)
  Forbidden     : $(wc -l < mining/forbidden.txt 2>/dev/null || echo 0)
  API endpoints : $(wc -l < mining/api_endpoints.txt 2>/dev/null || echo 0)

[3] VULNERABILITY FINDINGS
───────────────────────────
EOF

# إضافة كل vulns مع عدد النتائج
TOTAL_VULNS=0
CRITICAL_VULNS=0

if [ -d vulns ]; then
    for vuln_file in vulns/*.txt vulns/*.json; do
        [ -f "$vuln_file" ] || continue
        COUNT=$(wc -l < "$vuln_file" 2>/dev/null || echo "0")
        [ "$COUNT" -eq 0 ] && continue
        TOTAL_VULNS=$((TOTAL_VULNS + COUNT))
        FNAME=$(basename "$vuln_file")
        printf "  %-45s : %s findings\n" "$FNAME" "$COUNT" >> "$REPORT"

        # تصنيف critical
        if grep -qiE "critical|rce|sqli.*confirmed" "$vuln_file" 2>/dev/null; then
            CRITICAL_VULNS=$((CRITICAL_VULNS + COUNT))
        fi
    done
fi

cat >> "$REPORT" <<EOF

  ────────────────────────────────
  TOTAL FINDINGS  : $TOTAL_VULNS
  CRITICAL (est.) : $CRITICAL_VULNS
  ────────────────────────────────

[4] CRITICAL FILES — CHECK THESE FIRST
────────────────────────────────────────
EOF

# أهم الملفات اللي فيها نتائج
for priority_file in \
    "vulns/rce_vulns.txt" \
    "vulns/xss_dalfox.json" \
    "vulns/sqli_nuclei.txt" \
    "vulns/bypass_403.txt" \
    "vulns/takeovers.txt" \
    "vulns/js_secrets.txt" \
    "mining/js_secrets_trufflehog.json" \
    "osint/trufflehog_github.json"; do

    if [ -f "$priority_file" ] && [ -s "$priority_file" ]; then
        PCOUNT=$(wc -l < "$priority_file" 2>/dev/null || echo "?")
        echo "  🔴 $priority_file ($PCOUNT lines)" >> "$REPORT"
    fi
done

cat >> "$REPORT" <<EOF

[5] MANUAL TESTING NEEDED
──────────────────────────
  📌 IDOR     : mining/idor.txt
  📌 FFUF     : ffuf -w mining/custom_wordlist.txt -u https://TARGET/FUZZ
  📌 Google   : osint/google_dorks.txt
  📌 SQLMap   : sqlmap -m mining/sqli.txt --batch --level=3
  📌 API fuzz : ffuf -w /path/to/api-wordlist.txt -u https://api.TARGET/FUZZ

══════════════════════════════════════════════════════════
EOF

echo "    > Report saved: $WORK_DIR/$REPORT"

# ==========================================
# Telegram Notifications
# ==========================================
echo "[+] Sending Telegram Notifications..."

if [ -n "$TG_TOKEN" ] && [ -n "$TG_CHAT" ]; then

    # رسالة ملخص
    TG_MSG="🐉 <b>MAHER V8 — HUNT COMPLETE</b>

🎯 Target: <code>$TARGET</code>
🕒 Time: $TIMESTAMP

📊 Stats:
• Live Hosts: $LIVE_HOSTS
• Total URLs: $TOTAL_URLS
• Total Findings: $TOTAL_VULNS

🚨 High Priority:
• RCE: $(wc -l < vulns/rce_vulns.txt 2>/dev/null || echo 0) findings
• XSS: $(grep -c '"type"' vulns/xss_dalfox.json 2>/dev/null || wc -l < vulns/xss_vulns.txt 2>/dev/null || echo 0) findings
• SQLi: $(wc -l < vulns/sqli_nuclei.txt 2>/dev/null || echo 0) findings
• Takeover: $(wc -l < vulns/takeovers.txt 2>/dev/null || echo 0) findings
• 403 Bypass: $(wc -l < vulns/bypass_403.txt 2>/dev/null || echo 0) findings

📁 Results: $WORK_DIR"

    send_tg "$TG_MSG"

    # ابعت الريبورت كـ file
    send_tg_file "$REPORT" "📋 Full Report — $TARGET"

    # تنبيه للـ RCE لو موجود
    if [ -s vulns/rce_vulns.txt ]; then
        send_tg "🚨🚨 <b>RCE FOUND ON $TARGET</b> 🚨🚨
Check: vulns/rce_vulns.txt"
    fi

    # تنبيه للـ secrets
    if [ -s osint/trufflehog_github.json ] && grep -q '"SourceMetadata"' osint/trufflehog_github.json 2>/dev/null; then
        send_tg "🔑 <b>SECRETS LEAKED — $TARGET</b>
TruffleHog found verified secrets on GitHub!
Check: osint/trufflehog_github.json"
    fi

    echo "    > Telegram notifications sent ✅"
else
    echo "    > [~] Telegram not configured."
    echo "    >     Set: export TG_TOKEN=xxx && export TG_CHAT=xxx"
fi

# ==========================================
# عرض ملخص في الـ terminal
# ==========================================
echo ""
echo -e "\e[32m╔══════════════════════════════════════╗\e[0m"
echo -e "\e[32m║         HUNT STATS SUMMARY           ║\e[0m"
echo -e "\e[32m╠══════════════════════════════════════╣\e[0m"
printf "\e[32m║  %-20s : %-13s ║\e[0m\n" "Live Hosts"    "$LIVE_HOSTS"
printf "\e[32m║  %-20s : %-13s ║\e[0m\n" "Total Findings" "$TOTAL_VULNS"
printf "\e[32m║  %-20s : %-13s ║\e[0m\n" "RCE"           "$(wc -l < vulns/rce_vulns.txt 2>/dev/null || echo 0)"
printf "\e[32m║  %-20s : %-13s ║\e[0m\n" "XSS (Dalfox)"  "$(grep -c '"type"' vulns/xss_dalfox.json 2>/dev/null || echo 0)"
printf "\e[32m║  %-20s : %-13s ║\e[0m\n" "Takeovers"     "$(wc -l < vulns/takeovers.txt 2>/dev/null || echo 0)"
printf "\e[32m║  %-20s : %-13s ║\e[0m\n" "403 Bypassed"  "$(wc -l < vulns/bypass_403.txt 2>/dev/null || echo 0)"
echo -e "\e[32m╚══════════════════════════════════════╝\e[0m"

echo -e "\e[32m[✔] Report Phase Completed!\e[0m"
