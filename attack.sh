#!/bin/bash
export PATH=$PATH:$HOME/go/bin:/usr/local/go/bin

WORK_DIR=$1

if [ -z "$WORK_DIR" ]; then
    echo -e "\e[31m[!] Usage: ./attack.sh <work_dir>\e[0m"
    exit 1
fi

HEADER_OPTS=()
DALFOX_HEADER_OPTS=()
FFUF_HEADER_OPTS=()
if [ -n "$CUSTOM_BBP_HEADER" ]; then
    HEADER_OPTS=("-H" "$CUSTOM_BBP_HEADER")
    DALFOX_HEADER_OPTS=("--header" "$CUSTOM_BBP_HEADER")
    FFUF_HEADER_OPTS=("-H" "$CUSTOM_BBP_HEADER")
fi

echo -e "\e[31m==========================================\e[0m"
echo -e "\e[31m 🐉 [4] ATTACK Phase V8 — THE DRAGON FIRE\e[0m"
echo -e "\e[31m==========================================\e[0m"

cd "$WORK_DIR" || exit 1
mkdir -p vulns

# ==========================================
# 1. JS Secrets (Nuclei)
# ==========================================
echo "[+] 1. Hunting Secrets in JS Files..."
if [ -s mining/js_urls.txt ]; then
    nuclei -l mining/js_urls.txt "${HEADER_OPTS[@]}" \
        -tags exposure,token,key,secret \
        -severity info,low,medium,high,critical \
        -rl 50 -c 20 -silent \
        -o vulns/js_secrets.txt 2>/dev/null
    echo "    > JS Secrets: $(wc -l < vulns/js_secrets.txt 2>/dev/null || echo 0) findings"
fi

# ==========================================
# 2. XSS — Dalfox (أقوى من Nuclei في XSS)
# ==========================================
echo "[+] 2. XSS Testing (Dalfox — Advanced)..."
if [ -s mining/xss.txt ]; then
    if command -v dalfox &>/dev/null; then
        dalfox file mining/xss.txt \
            "${DALFOX_HEADER_OPTS[@]}" \
            --skip-bav \
            --silence \
            --no-spinner \
            --format json \
            -o vulns/xss_dalfox.json 2>/dev/null || true
        XSS_COUNT=$(grep -c '"type"' vulns/xss_dalfox.json 2>/dev/null || echo "0")
        echo "    > Dalfox XSS Found: $XSS_COUNT"
        [ "$XSS_COUNT" -gt 0 ] && echo -e "\e[31m    > 🚨 XSS CONFIRMED! Check vulns/xss_dalfox.json\e[0m"
    else
        echo "    > [!] dalfox not found, falling back to nuclei."
        echo "    >     Install: go install github.com/hahwul/dalfox/v2@latest"
        nuclei -l mining/xss.txt "${HEADER_OPTS[@]}" -tags xss,dast \
            -severity info,low,medium,high,critical -rl 50 -c 20 -silent \
            -o vulns/xss_vulns.txt 2>/dev/null
    fi
else
    # لو مفيش xss.txt، جرب على كل alive
    nuclei -l alive.txt "${HEADER_OPTS[@]}" -tags xss \
        -severity medium,high,critical -rl 30 -c 10 -silent \
        -o vulns/xss_vulns.txt 2>/dev/null
fi

# ==========================================
# 3. SQLi — Nuclei + SQLMap Confirmation
# ==========================================
echo "[+] 3. SQL Injection Testing..."
if [ -s mining/sqli.txt ]; then
    # Nuclei أولاً عشان سريع
    nuclei -l mining/sqli.txt "${HEADER_OPTS[@]}" -tags sqli,dast \
        -severity info,low,medium,high,critical -rl 50 -c 20 -silent \
        -o vulns/sqli_nuclei.txt 2>/dev/null

    NUCLEI_SQLI=$(wc -l < vulns/sqli_nuclei.txt 2>/dev/null || echo "0")
    echo "    > Nuclei SQLi: $NUCLEI_SQLI potential findings"

    # SQLMap على أول 20 URL للـ confirmation
    if command -v sqlmap &>/dev/null && [ -s mining/sqli.txt ]; then
        echo "    > SQLMap deep scan (top 20 targets)..."
        head -20 mining/sqli.txt > /tmp/sqli_top20.txt
        sqlmap -m /tmp/sqli_top20.txt \
            --batch \
            --level=2 \
            --risk=2 \
            --threads=5 \
            --output-dir="vulns/sqlmap_results" \
            $([ -n "$CUSTOM_BBP_HEADER" ] && echo "--headers=\"$CUSTOM_BBP_HEADER\"") \
            --forms \
            --crawl=2 \
            --smart \
            2>/dev/null || true
        echo "    > SQLMap results: vulns/sqlmap_results/"
    else
        echo "    > [!] sqlmap not found. Install: sudo apt install sqlmap"
    fi
fi

# ==========================================
# 4. LFI & Path Traversal
# ==========================================
echo "[+] 4. LFI & Path Traversal..."
if [ -s mining/lfi.txt ]; then
    nuclei -l mining/lfi.txt "${HEADER_OPTS[@]}" -tags lfi,dast \
        -severity info,low,medium,high,critical -rl 50 -c 20 -silent \
        -o vulns/lfi_vulns.txt 2>/dev/null
    echo "    > LFI findings: $(wc -l < vulns/lfi_vulns.txt 2>/dev/null || echo 0)"
fi

# ==========================================
# 5. SSRF & Open Redirect
# ==========================================
echo "[+] 5. SSRF & Open Redirect..."
if [ -s mining/ssrf_redirect.txt ]; then
    nuclei -l mining/ssrf_redirect.txt "${HEADER_OPTS[@]}" -tags ssrf,redirect,oast \
        -severity info,low,medium,high,critical -rl 50 -c 20 -silent \
        -o vulns/ssrf_vulns.txt 2>/dev/null
    echo "    > SSRF/Redirect findings: $(wc -l < vulns/ssrf_vulns.txt 2>/dev/null || echo 0)"
fi

# ==========================================
# 6. RCE & Command Injection
# ==========================================
echo "[+] 6. RCE & Command Injection..."
if [ -s mining/rce.txt ]; then
    nuclei -l mining/rce.txt "${HEADER_OPTS[@]}" -tags rce,oast \
        -severity info,low,medium,high,critical -rl 50 -c 20 -silent \
        -o vulns/rce_vulns.txt 2>/dev/null
    echo "    > RCE findings: $(wc -l < vulns/rce_vulns.txt 2>/dev/null || echo 0)"
    [ -s vulns/rce_vulns.txt ] && echo -e "\e[31m    > 🚨 POTENTIAL RCE FOUND!\e[0m"
fi

# ==========================================
# 7. CORS Misconfiguration
# ==========================================
echo "[+] 7. CORS Misconfiguration..."
if [ -s alive.txt ]; then
    nuclei -l alive.txt "${HEADER_OPTS[@]}" -tags cors \
        -severity info,low,medium,high,critical -rl 50 -c 20 -silent \
        -o vulns/cors_vulns.txt 2>/dev/null
    echo "    > CORS findings: $(wc -l < vulns/cors_vulns.txt 2>/dev/null || echo 0)"
fi

# ==========================================
# 8. 403 Bypass
# ==========================================
echo "[+] 8. 403 Bypass Attempts..."
if [ -s mining/forbidden.txt ]; then
    nuclei -l mining/forbidden.txt "${HEADER_OPTS[@]}" -tags bypass \
        -severity info,low,medium,high,critical -rl 30 -c 10 -silent \
        -o vulns/bypass_403.txt 2>/dev/null
    BYPASSED=$(wc -l < vulns/bypass_403.txt 2>/dev/null || echo "0")
    echo "    > 403 Bypassed: $BYPASSED"
    [ "$BYPASSED" -gt 0 ] && echo -e "\e[33m    > 🔓 403 BYPASSED! Check vulns/bypass_403.txt\e[0m"
fi

# ==========================================
# 9. Tech-Targeted Attacks
# ==========================================
echo "[+] 9. Tech-Targeted Attacks..."
for tech in wordpress php nginx apache tomcat nodejs react spring django laravel; do
    if [ -s "technologies/${tech}.txt" ]; then
        echo "    > 🎯 Attacking $tech targets..."
        nuclei -l "technologies/${tech}.txt" "${HEADER_OPTS[@]}" \
            -tags "${tech},cve,misconfig" \
            -severity info,low,medium,high,critical \
            -rl 50 -c 20 -silent \
            -o "vulns/tech_${tech}_vulns.txt" 2>/dev/null
    fi
done

# ==========================================
# 10. Login Pages — Default Creds + Brute Hints
# ==========================================
echo "[+] 10. Login Page Attacks (Default Creds)..."
if [ -s login_pages.txt ]; then
    nuclei -l login_pages.txt "${HEADER_OPTS[@]}" \
        -tags "default-login,default-credentials,auth-bypass" \
        -severity info,low,medium,high,critical \
        -rl 30 -c 10 -silent \
        -o vulns/login_vulns.txt 2>/dev/null
    echo "    > Login findings: $(wc -l < vulns/login_vulns.txt 2>/dev/null || echo 0)"
fi

# ==========================================
# 11. FFUF — Custom Wordlist Fuzzing
# ==========================================
echo "[+] 11. FFUF Directory Fuzzing (Custom Wordlist)..."
if command -v ffuf &>/dev/null && [ -s mining/custom_wordlist.txt ]; then
    # خذ أهم 5 hosts وضربهم بالـ wordlist
    head -5 alive.txt | while IFS= read -r url; do
        SAFE_NAME=$(echo "$url" | sed 's|https\?://||;s|/|_|g;s|:||g')
        ffuf -w mining/custom_wordlist.txt \
            -u "${url}/FUZZ" \
            ${FFUF_HEADER_OPTS[@]+"${FFUF_HEADER_OPTS[@]}"} \
            -mc 200,201,204,301,302,307,401,403 \
            -t 40 \
            -rate 50 \
            -s \
            -o "vulns/ffuf_${SAFE_NAME}.json" \
            -of json \
            2>/dev/null || true
    done
    echo "    > FFUF results in vulns/ffuf_*.json"
else
    [ ! -s mining/custom_wordlist.txt ] && echo "    > [!] Custom wordlist is empty, skipping FFUF"
    command -v ffuf &>/dev/null || echo "    > [!] ffuf not found. Install: go install github.com/ffuf/ffuf/v2@latest"
fi

# ==========================================
# 12. Subdomain Takeover
# ==========================================
echo "[+] 12. Subdomain Takeover Check..."
if [ -s all_valid_subs.txt ]; then
    nuclei -l all_valid_subs.txt "${HEADER_OPTS[@]}" -tags takeover \
        -severity info,low,medium,high,critical -rl 50 -c 20 -silent \
        -o vulns/takeovers.txt 2>/dev/null
    echo "    > Takeover findings: $(wc -l < vulns/takeovers.txt 2>/dev/null || echo 0)"
fi

# ==========================================
# 13. API Endpoints
# ==========================================
echo "[+] 13. API Endpoint Testing..."
if [ -s mining/api_endpoints.txt ]; then
    nuclei -l mining/api_endpoints.txt "${HEADER_OPTS[@]}" \
        -tags "api,exposure,misconfig" \
        -severity info,low,medium,high,critical \
        -rl 50 -c 20 -silent \
        -o vulns/api_vulns.txt 2>/dev/null
    echo "    > API findings: $(wc -l < vulns/api_vulns.txt 2>/dev/null || echo 0)"
fi

# ==========================================
# 14. IDOR Reminder
# ==========================================
if [ -s mining/idor.txt ]; then
    echo -e "\e[33m[⚠️] IDOR endpoints in mining/idor.txt — MANUAL TESTING REQUIRED!\e[0m"
    echo "    > Count: $(wc -l < mining/idor.txt) endpoints"
fi

# ==========================================
# 15. General Nuclei Scan (Final Wave)
# ==========================================
echo "[+] 15. General Nuclei Scan (Final Wave)..."
if [ -s alive.txt ]; then
    nuclei -l alive.txt "${HEADER_OPTS[@]}" \
        -tags "cve,misconfig,exposure" \
        -severity low,medium,high,critical \
        -rl 50 -c 20 -silent \
        -o vulns/general_scan.txt 2>/dev/null
    echo "    > General findings: $(wc -l < vulns/general_scan.txt 2>/dev/null || echo 0)"
fi

echo -e "\e[32m[✔] Attack Phase Completed! Check 'vulns/' folder 💰\e[0m"
