#!/bin/bash
export PATH=$PATH:$HOME/go/bin:/usr/local/go/bin

TARGET=$1
WORK_DIR=$2

if [ -z "$TARGET" ] || [ -z "$WORK_DIR" ]; then
    echo -e "\e[31m[!] Usage: ./recon.sh <domain.com> <work_dir>\e[0m"
    exit 1
fi

# ==========================================
# 0. تجهيز الـ Custom Header
# ==========================================
HEADER_OPTS=()
if [ -n "$CUSTOM_BBP_HEADER" ]; then
    HEADER_OPTS=("-H" "$CUSTOM_BBP_HEADER")
fi

echo "=========================================="
echo "🔍 [1] RECON Phase V8 — THE DRAGON EYE"
echo "=========================================="

mkdir -p "$WORK_DIR"
cd "$WORK_DIR" || exit 1

# ==========================================
# Phase 0: Subdomain Mode Detection
# ==========================================
if [ "$IS_SUBDOMAIN" = "true" ]; then
    echo -e "\e[33m[~] Subdomain Mode: Skipping full enum, focusing on: $TARGET\e[0m"
    echo "$TARGET" > passive_subs.txt
    echo "$TARGET" > resolved_subs.txt
    echo "$TARGET" > all_valid_subs.txt

    # في subdomain mode، كمان نجيب الـ root domain سابدومينز عشان نشوف إخواته
    echo -e "\e[36m[+] Fetching sibling subdomains for root: $ROOT_DOMAIN\e[0m"
    subfinder -d "$ROOT_DOMAIN" -all -silent 2>/dev/null | grep "\.$ROOT_DOMAIN$" >> passive_subs.txt || true
    cat passive_subs.txt | sort -u > passive_subs.txt.tmp && mv passive_subs.txt.tmp passive_subs.txt
    echo "    > Siblings found: $(wc -l < passive_subs.txt)"
else
    # ==========================================
    # Phase 1: Passive Recon (Full Domain Mode)
    # ==========================================
    echo "[+] 1. Passive Enumeration (subfinder + cero + crt.sh)..."
    echo "$TARGET" > subs_raw.txt

    # subfinder
    subfinder -d "$TARGET" -all -silent 2>/dev/null >> subs_raw.txt

    # cero (SSL certs)
    cero "$TARGET" 2>/dev/null | sed 's/^\*\.//' | grep "\.$TARGET$" >> subs_raw.txt

    # crt.sh API (backup source)
    curl -s --max-time 20 "https://crt.sh/?q=%25.$TARGET&output=json" 2>/dev/null \
        | grep -o '"name_value":"[^"]*"' \
        | sed 's/"name_value":"//;s/"//' \
        | sed 's/^\*\.//' \
        | grep "\.$TARGET$" >> subs_raw.txt || true

    cat subs_raw.txt | sort -u > passive_subs.txt
    echo "    > Subdomains Found Passively: $(wc -l < passive_subs.txt)"
fi

# ==========================================
# Phase 2: Resolving & Wildcard Filtering
# ==========================================
echo "[+] 2. Downloading Fresh Resolvers & Resolving..."
wget -q https://raw.githubusercontent.com/trickest/resolvers/main/resolvers-trusted.txt -O resolvers.txt
puredns resolve passive_subs.txt -r resolvers.txt --write resolved_subs.txt -q 2>/dev/null
[ ! -s resolved_subs.txt ] && cp passive_subs.txt resolved_subs.txt
echo "    > Valid Subs: $(wc -l < resolved_subs.txt)"

# ==========================================
# Phase 3: Permutations (Alterx) — skip في subdomain mode لتوفير الوقت
# ==========================================
if [ "$IS_SUBDOMAIN" = "true" ]; then
    cp resolved_subs.txt all_valid_subs.txt
    echo "[~] Skipping permutations in subdomain mode."
else
    echo "[+] 3. Generating & Resolving Permutations (alterx)..."
    cat resolved_subs.txt | alterx -silent 2>/dev/null > alterx_subs.txt
    puredns resolve alterx_subs.txt -r resolvers.txt --write resolved_alterx.txt -q 2>/dev/null
    cat resolved_subs.txt resolved_alterx.txt | sort -u > all_valid_subs.txt
    echo "    > Total Valid Subdomains (+ Permutations): $(wc -l < all_valid_subs.txt)"
fi

# Fallback لو مفيش دومينات
if [ ! -s all_valid_subs.txt ]; then
    echo "$TARGET" > all_valid_subs.txt
    echo -e "\e[33m[!] No subdomains found. Switching to Single Domain mode.\e[0m"
fi

# ==========================================
# Phase 3.5: DNS Deep Dive (dnsx) — استخراج A/CNAME/MX/TXT
# ==========================================
echo "[+] 3.5. DNS Deep Extraction (dnsx)..."
if command -v dnsx &>/dev/null; then
    dnsx -l all_valid_subs.txt -a -cname -mx -txt -resp -silent 2>/dev/null -o dns_records.txt || true
    # استخلاص أهداف جديدة من الـ CNAME (ممكن تكون takeover candidates)
    grep "\[CNAME\]" dns_records.txt 2>/dev/null | awk '{print $1}' > cname_targets.txt || true
    echo "    > DNS Records saved: $(wc -l < dns_records.txt 2>/dev/null || echo 0)"
    echo "    > CNAME targets: $(wc -l < cname_targets.txt 2>/dev/null || echo 0)"
else
    echo "    > [!] dnsx not found, skipping. Install: go install github.com/projectdiscovery/dnsx/cmd/dnsx@latest"
fi

# ==========================================
# Phase 3.8: ASN Enumeration — IP Ranges للشركة (Full mode only)
# ==========================================
if [ "$IS_SUBDOMAIN" = "false" ]; then
    echo "[+] 3.8. ASN Enumeration (asnmap)..."
    if command -v asnmap &>/dev/null; then
        asnmap -d "$TARGET" -silent 2>/dev/null > asn_ranges.txt || true
        echo "    > IP Ranges Found: $(wc -l < asn_ranges.txt 2>/dev/null || echo 0)"
        # Port scan على الـ IP ranges (عشان نلاقي hosts مش في الـ DNS)
        if [ -s asn_ranges.txt ]; then
            echo "    > Scanning ASN IP ranges (top ports)..."
            naabu -list asn_ranges.txt -top-ports 100 -rate 500 -c 30 -silent -o asn_ports.txt 2>/dev/null || true
            echo "    > ASN Live Hosts: $(wc -l < asn_ports.txt 2>/dev/null || echo 0)"
        fi
    else
        echo "    > [!] asnmap not found, skipping. Install: go install github.com/projectdiscovery/asnmap/cmd/asnmap@latest"
    fi
fi

# ==========================================
# Phase 4: Port Scanning (Naabu)
# ==========================================
echo "[+] 4. Port Scanning Top 100 (naabu)..."
touch active_ports.txt
naabu -l all_valid_subs.txt -top-ports 100 -rate 1000 -c 50 -silent -o active_ports.txt 2>/dev/null || true
echo "    > Extra Ports Found: $(wc -l < active_ports.txt)"

# دمج كل الأهداف مع بعض
cat all_valid_subs.txt active_ports.txt asn_ports.txt 2>/dev/null | sort -u > final_targets.txt

# ==========================================
# Phase 5: Deep Tech Extraction (httpx)
# ==========================================
echo "[+] 5. Deep Tech Extraction (httpx)..."
httpx -l final_targets.txt "${HEADER_OPTS[@]}" -silent -sc -title -td -rl 50 -t 20 -o live_tech.txt 2>/dev/null

if [ ! -s live_tech.txt ]; then
    echo -e "\e[31m[!] No live hosts found. Exiting recon.\e[0m"
    exit 1
fi

awk '{print $1}' live_tech.txt > alive.txt
echo "    > Live Hosts: $(wc -l < alive.txt)"

# استخلاص الـ 403/401 endpoints
httpx -l final_targets.txt "${HEADER_OPTS[@]}" -silent -mc 403,401 -o forbidden_hosts.txt 2>/dev/null || true
echo "    > Forbidden (403/401) Hosts: $(wc -l < forbidden_hosts.txt 2>/dev/null || echo 0)"

# استخلاص login pages
grep -iE "login|signin|admin|dashboard|portal|auth" live_tech.txt 2>/dev/null | awk '{print $1}' > login_pages.txt || true
echo "    > Login Pages Found: $(wc -l < login_pages.txt 2>/dev/null || echo 0)"

# ==========================================
# Phase 6: Building Tech Database
# ==========================================
echo "[+] 6. Building Tech Database..."
mkdir -p technologies
for tech in wordpress php react nginx apache tomcat nodejs spring django laravel; do
    grep -i "$tech" live_tech.txt 2>/dev/null | awk '{print $1}' > "technologies/${tech}.txt"
done
echo "    > Tech DB created in 'technologies/'"

echo -e "\e[32m[✔] Recon Phase Completed!\e[0m"
