#!/bin/bash
export PATH=$PATH:$HOME/go/bin:/usr/local/go/bin

WORK_DIR=$1

if [ -z "$WORK_DIR" ]; then
    echo -e "\e[31m[!] Usage: ./mine.sh <work_dir>\e[0m"
    exit 1
fi

HEADER_OPTS=()
if [ -n "$CUSTOM_BBP_HEADER" ]; then
    HEADER_OPTS=("-H" "$CUSTOM_BBP_HEADER")
fi

echo "=========================================="
echo "⛏️  [3] MINING Phase V8 — DEEP DIG"
echo "=========================================="

cd "$WORK_DIR" || exit 1
mkdir -p mining

# ==========================================
# Phase 1: تجميع الروابط من كل المصادر
# ==========================================
echo "[+] Phase 1: URL Collection — GAU + Katana + Wayback..."

# GAU (historical URLs)
cat alive.txt | gau --threads 10 2>/dev/null > mining/gau_urls.txt

# Katana (active crawler)
katana -list alive.txt -silent "${HEADER_OPTS[@]}" -depth 5 -jc 2>/dev/null > mining/katana_urls.txt

# Wayback (تاريخي تاني)
if [ -f osint/wayback_urls.txt ] && [ -s osint/wayback_urls.txt ]; then
    cp osint/wayback_urls.txt mining/wayback_urls.txt
else
    cat alive.txt | while read url; do
        domain=$(echo "$url" | sed 's|https\?://||' | cut -d/ -f1)
        waybackurls "$domain" 2>/dev/null
    done > mining/wayback_urls.txt
fi

# دمج الكل بدون تكرار
cat mining/gau_urls.txt mining/katana_urls.txt mining/wayback_urls.txt 2>/dev/null \
    | sort -u > mining/raw_urls_all.txt

echo "    > Raw URLs (before dedup): $(wc -l < mining/raw_urls_all.txt)"

# ==========================================
# Phase 2: URO — تنظيف ذكي للـ URLs
# ==========================================
echo "[+] Phase 2: Smart Deduplication (uro)..."
if command -v uro &>/dev/null; then
    cat mining/raw_urls_all.txt | uro 2>/dev/null > all_urls.txt
    echo "    > After uro dedup: $(wc -l < all_urls.txt) (was $(wc -l < mining/raw_urls_all.txt))"
else
    cp mining/raw_urls_all.txt all_urls.txt
    echo "    > [!] uro not installed (falling back to sort -u)."
    echo "    >     Install: pip install uro"
fi

# ==========================================
# Phase 3: JS Extraction + TruffleHog
# ==========================================
echo "[+] Phase 3: JS Extraction & Secret Hunting..."
grep -iE "\.js(\?.*)?$" all_urls.txt | sort -u > mining/js_urls.txt
echo "    > JS Files: $(wc -l < mining/js_urls.txt)"

# TruffleHog على الـ JS files
if command -v trufflehog &>/dev/null && [ -s mining/js_urls.txt ]; then
    echo "    > Running TruffleHog on JS files..."
    trufflehog filesystem --directory="." \
        --only-verified \
        --no-update \
        --json 2>/dev/null > mining/js_secrets_trufflehog.json || true
    JS_SECRETS=$(grep -c '"SourceMetadata"' mining/js_secrets_trufflehog.json 2>/dev/null || echo "0")
    echo "    > Verified JS Secrets: $JS_SECRETS"
fi

# SecretFinder/nuclei على الـ JS (backup)
echo "    > Nuclei JS scan will run in attack phase."

# ==========================================
# Phase 4: Custom Wordlist من الـ JS والـ URLs
# ==========================================
echo "[+] Phase 4: Building Target-Specific Wordlist..."
cat all_urls.txt \
    | awk -F/ '{for(i=3;i<=NF;i++) print $i}' \
    | sed 's/?.*//' \
    | tr "[:punct:]" "\n" \
    | sort -u \
    | grep -v "^[0-9]*$" \
    | awk '{ if (length($0) > 3 && length($0) < 20) print $0 }' \
    > mining/custom_wordlist.txt
echo "    > Custom Wordlist: $(wc -l < mining/custom_wordlist.txt) words"

# ==========================================
# Phase 5: Parameter Extraction
# ==========================================
echo "[+] Phase 5: Extracting Parameterized URLs..."
grep "=" all_urls.txt | sort -u > all_params.txt
echo "    > Params URLs: $(wc -l < all_params.txt)"

# ==========================================
# Phase 6: Smart Parameter Categorization (Regex Engine)
# ==========================================
echo "[+] Phase 6: Categorizing Parameters..."

grep -iE "[?&](q|s|search|lang|keyword|query|page|view|id|name|callback|jsonp|input|text|html)=" all_params.txt \
    | sort -u > mining/xss.txt

grep -iE "[?&](id|page|dir|category|sort|user|item|cat|p|article|product|num|limit|offset|order)=" all_params.txt \
    | sort -u > mining/sqli.txt

grep -iE "[?&](file|page|dir|doc|folder|path|include|template|layout|load|read|fetch|content)=" all_params.txt \
    | sort -u > mining/lfi.txt

grep -iE "[?&](url|dest|path|uri|domain|site|out|redirect|next|return|go|target|window|location|link|src|href|from)=" all_params.txt \
    | sort -u > mining/ssrf_redirect.txt

grep -iE "[?&](cmd|exec|ping|run|do|shell|query|eval|daemon|system|proc|process|execute|command)=" all_params.txt \
    | sort -u > mining/rce.txt

grep -iE "[?&](id|user_id|account|profile|order|invoice|doc|receipt|bill|ticket|report|uid|pid|cid)=" all_params.txt \
    | sort -u > mining/idor.txt

# ==========================================
# Phase 7: 403/401 Endpoints للـ Bypass
# ==========================================
echo "[+] Phase 7: Collecting 403/401 Endpoints for Bypass..."
if [ -f forbidden_hosts.txt ] && [ -s forbidden_hosts.txt ]; then
    cp forbidden_hosts.txt mining/forbidden.txt
else
    # جرب تجيبهم من الـ URLs
    httpx -l alive.txt "${HEADER_OPTS[@]}" -mc 403,401 -silent 2>/dev/null > mining/forbidden.txt || true
fi
echo "    > Forbidden Endpoints: $(wc -l < mining/forbidden.txt 2>/dev/null || echo 0)"

# ==========================================
# Phase 8: API Endpoints
# ==========================================
echo "[+] Phase 8: Extracting API Endpoints..."
grep -iE "/api/|/v[0-9]+/|/rest/|/graphql|/swagger|/openapi" all_urls.txt \
    | sort -u > mining/api_endpoints.txt
echo "    > API Endpoints: $(wc -l < mining/api_endpoints.txt)"

echo ""
echo "    ╔══════════════════════════════════╗"
echo "    ║     MINING SUMMARY               ║"
printf "    ║  %-10s : %-18s ║\n" "XSS"     "$(wc -l < mining/xss.txt) URLs"
printf "    ║  %-10s : %-18s ║\n" "SQLi"    "$(wc -l < mining/sqli.txt) URLs"
printf "    ║  %-10s : %-18s ║\n" "LFI"     "$(wc -l < mining/lfi.txt) URLs"
printf "    ║  %-10s : %-18s ║\n" "SSRF"    "$(wc -l < mining/ssrf_redirect.txt) URLs"
printf "    ║  %-10s : %-18s ║\n" "RCE"     "$(wc -l < mining/rce.txt) URLs"
printf "    ║  %-10s : %-18s ║\n" "IDOR"    "$(wc -l < mining/idor.txt) URLs"
printf "    ║  %-10s : %-18s ║\n" "403/401" "$(wc -l < mining/forbidden.txt 2>/dev/null || echo 0) URLs"
printf "    ║  %-10s : %-18s ║\n" "API"     "$(wc -l < mining/api_endpoints.txt) endpoints"
echo "    ╚══════════════════════════════════╝"

echo -e "\e[32m[✔] Mining Phase Completed!\e[0m"
