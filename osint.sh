#!/bin/bash
export PATH=$PATH:$HOME/go/bin:/usr/local/go/bin

TARGET=$1
WORK_DIR=$2

if [ -z "$TARGET" ] || [ -z "$WORK_DIR" ]; then
    echo -e "\e[31m[!] Usage: ./osint.sh <domain.com> <work_dir>\e[0m"
    exit 1
fi

echo "=========================================="
echo "🕵️  [2] OSINT Phase V8 — LEAKS & CLOUD"
echo "=========================================="

cd "$WORK_DIR" || exit 1
mkdir -p osint

# ==========================================
# Phase 1: GitHub Subdomain Leaks
# ==========================================
echo "[+] 1. GitHub Subdomain Hunting..."
if command -v github-subdomains &>/dev/null; then
    if [ -n "$GITHUB_TOKEN" ]; then
        github-subdomains -d "$ROOT_DOMAIN" -t "$GITHUB_TOKEN" -o osint/github_subs.txt 2>/dev/null || true
        # دمج النتائج الجديدة مع الـ recon
        if [ -s osint/github_subs.txt ]; then
            NEW_SUBS=$(comm -23 <(sort osint/github_subs.txt) <(sort all_valid_subs.txt 2>/dev/null) | wc -l)
            cat osint/github_subs.txt >> all_valid_subs.txt
            sort -u all_valid_subs.txt -o all_valid_subs.txt
            echo "    > GitHub New Subs: $NEW_SUBS (added to pool)"
        fi
    else
        echo "    > [!] GITHUB_TOKEN not set. Set it: export GITHUB_TOKEN=ghp_xxx"
        echo "    >     github-subdomains found but skipped (no token)"
    fi
else
    echo "    > [!] github-subdomains not installed."
    echo "    >     Install: go install github.com/gwen001/github-subdomains@latest"
fi

# ==========================================
# Phase 2: TruffleHog — GitHub Org Secrets
# ==========================================
echo "[+] 2. TruffleHog — Scanning GitHub for Leaked Secrets..."
if command -v trufflehog &>/dev/null; then
    # استخلص اسم الـ org من دومين (best-effort)
    ORG_NAME=$(echo "$ROOT_DOMAIN" | cut -d'.' -f1)

    trufflehog github \
        --org="$ORG_NAME" \
        --only-verified \
        --concurrency=5 \
        --no-update \
        --json 2>/dev/null \
        > osint/trufflehog_github.json || true

    SECRETS_FOUND=$(grep -c '"SourceMetadata"' osint/trufflehog_github.json 2>/dev/null || echo "0")
    echo "    > Verified Secrets Found: $SECRETS_FOUND"

    if [ "$SECRETS_FOUND" -gt 0 ]; then
        echo -e "\e[31m    > 🚨 SECRETS LEAKED! Check osint/trufflehog_github.json IMMEDIATELY!\e[0m"
    fi
else
    echo "    > [!] trufflehog not installed."
    echo "    >     Install: curl -sSfL https://raw.githubusercontent.com/trufflesecurity/trufflehog/main/scripts/install.sh | sh -s -- -b /usr/local/bin"
fi

# ==========================================
# Phase 3: Cloud Assets Enumeration
# ==========================================
echo "[+] 3. Cloud Assets (S3 + Azure + GCP)..."
if command -v cloud_enum &>/dev/null; then
    ORG_KEYWORD=$(echo "$ROOT_DOMAIN" | cut -d'.' -f1)
    cloud_enum -k "$ORG_KEYWORD" \
        --disable-brute \
        -s osint/cloud_storage.txt \
        2>/dev/null || true
    echo "    > Cloud Assets: $(wc -l < osint/cloud_storage.txt 2>/dev/null || echo 0)"
else
    echo "    > [!] cloud_enum not installed."
    echo "    >     Install: pip install cloud-enum"
    # Fallback: بحث يدوي بسيط عن S3 buckets
    echo "    > [~] Trying manual S3 check..."
    ORG_KEYWORD=$(echo "$ROOT_DOMAIN" | cut -d'.' -f1)
    for bucket in "$ORG_KEYWORD" "${ORG_KEYWORD}-backup" "${ORG_KEYWORD}-assets" "${ORG_KEYWORD}-static" "${ORG_KEYWORD}-dev" "${ORG_KEYWORD}-prod" "${ORG_KEYWORD}-staging"; do
        STATUS=$(curl -s -o /dev/null -w "%{http_code}" "https://${bucket}.s3.amazonaws.com/" 2>/dev/null)
        if [ "$STATUS" = "200" ] || [ "$STATUS" = "403" ]; then
            echo "    > 🪣 S3 Bucket Found: ${bucket}.s3.amazonaws.com [HTTP $STATUS]" | tee -a osint/s3_buckets.txt
        fi
    done
fi

# ==========================================
# Phase 4: Wayback Machine — لاقي قديم ومنسي
# ==========================================
echo "[+] 4. Wayback Machine — Old & Forgotten URLs..."
if command -v waybackurls &>/dev/null; then
    echo "$ROOT_DOMAIN" | waybackurls 2>/dev/null > osint/wayback_urls.txt
    # دمج مع الـ mining لو موجود
    echo "    > Wayback URLs: $(wc -l < osint/wayback_urls.txt)"
else
    echo "    > [!] waybackurls not installed."
    echo "    >     Install: go install github.com/tomnomnom/waybackurls@latest"
fi

# ==========================================
# Phase 5: Google Dorking Hints (manual)
# ==========================================
echo "[+] 5. Generating Google Dork List..."
cat > osint/google_dorks.txt <<EOF
# ===== GOOGLE DORKS FOR: $ROOT_DOMAIN =====
# Run these manually in your browser

site:$ROOT_DOMAIN ext:env OR ext:config OR ext:yml
site:$ROOT_DOMAIN ext:sql OR ext:db OR ext:backup
site:$ROOT_DOMAIN inurl:admin OR inurl:login OR inurl:dashboard
site:$ROOT_DOMAIN "api_key" OR "api_secret" OR "password"
site:$ROOT_DOMAIN inurl:api/v1 OR inurl:api/v2
site:$ROOT_DOMAIN filetype:pdf OR filetype:docx OR filetype:xlsx

# GitHub dorks
site:github.com "$ROOT_DOMAIN" password OR secret OR key OR token
site:github.com "$ROOT_DOMAIN" "api.${ROOT_DOMAIN}"

# Pastebin / leaks
site:pastebin.com "$ROOT_DOMAIN"
site:trello.com "$ROOT_DOMAIN"
EOF
echo "    > Dork list saved: osint/google_dorks.txt"

echo -e "\e[32m[✔] OSINT Phase Completed!\e[0m"
