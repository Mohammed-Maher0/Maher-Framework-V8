<div align="center">

```
███╗   ███╗ █████╗ ██╗  ██╗███████╗██████╗     
████╗ ████║██╔══██╗██║  ██║██╔════╝██╔══██╗    
██╔████╔██║███████║███████║█████╗  ██████╔╝    
██║╚██╔╝██║██╔══██║██╔══██║██╔══╝  ██╔══██╗    
██║ ╚═╝ ██║██║  ██║██║  ██║███████╗██║  ██║    
╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝   
███████╗██████╗  █████╗ ███╗   ███╗███████╗    
██╔════╝██╔══██╗██╔══██╗████╗ ████║██╔════╝    
█████╗  ██████╔╝███████║██╔████╔██║█████╗      
██╔══╝  ██╔══██╗██╔══██║██║╚██╔╝██║██╔══╝      
██║     ██║  ██║██║  ██║██║ ╚═╝ ██║███████╗    
╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝╚══════╝   
```

# 🐉 Maher Framework V8

**An automated, smart, and WAF-evasive Bug Bounty pipeline — built for hunters who want results, not noise.**

[![Version](https://img.shields.io/badge/version-8.0-red?style=for-the-badge)](https://github.com/Mohammed-Maher0/Maher-Framework)
[![Language](https://img.shields.io/badge/language-Bash-green?style=for-the-badge&logo=gnubash)](https://github.com/Mohammed-Maher0/Maher-Framework)
[![License](https://img.shields.io/badge/license-MIT-blue?style=for-the-badge)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Linux%20%7C%20macOS-lightgrey?style=for-the-badge)](https://github.com/Mohammed-Maher0/Maher-Framework)

</div>

---

## 📖 What is Maher Framework?

Maher Framework is a **fully automated bug bounty hunting pipeline** written in Bash. It chains the best open-source tools together in a smart, ordered flow — from deep reconnaissance all the way to confirmed vulnerability findings — while staying under the radar of WAFs and rate limiters.

**V8 "The Dragon"** is a complete rewrite introducing 5 attack phases, a dedicated OSINT engine, GitHub leak detection, cloud asset enumeration, advanced XSS/SQLi confirmation, Telegram live alerts, and auto-detection of subdomain targets.

---

## ✨ What's New in V8

| Feature | V7 | V8 |
|---|---|---|
| Subdomain Mode (auto-detect) | ❌ | ✅ |
| ASN / IP Range Enumeration | ❌ | ✅ |
| DNS Deep Extraction (dnsx) | ❌ | ✅ |
| GitHub Leak Hunting | ❌ | ✅ |
| TruffleHog (Verified Secrets) | ❌ | ✅ |
| Cloud Asset Enumeration (S3/GCP/Azure) | ❌ | ✅ |
| Wayback Machine Mining | ❌ | ✅ |
| Smart URL Dedup (uro) | ❌ | ✅ |
| Dalfox XSS Engine | ❌ | ✅ |
| SQLMap Confirmation | ❌ | ✅ |
| CORS Misconfiguration | ❌ | ✅ |
| 403/401 Bypass | ❌ | ✅ |
| FFUF with Custom Wordlist | ❌ | ✅ |
| Login Page Attacks | ❌ | ✅ |
| API Endpoint Testing | ❌ | ✅ |
| Google Dorks Generator | ❌ | ✅ |
| Telegram Live Notifications | ❌ | ✅ |
| Final Aggregated Report | ❌ | ✅ |
| One-Click Installer | ❌ | ✅ |
| Tech Coverage | 6 stacks | 10 stacks |

---

## 🗺️ Pipeline Architecture

```
pwn.sh  ──────────────────────────────────────────────────────
         │
         ├──► [1] recon.sh      🔍 THE EYE
         │         Passive enum (subfinder + cero + crt.sh)
         │         DNS deep extraction (dnsx)
         │         ASN / IP Range discovery (asnmap)
         │         Permutations (alterx) + Wildcard filtering (puredns)
         │         Port scanning (naabu)
         │         Live host detection + Tech fingerprinting (httpx)
         │         Builds: alive.txt / technologies/ / login_pages.txt
         │
         ├──► [2] osint.sh      🕵️ THE GHOST
         │         GitHub subdomain leaks (github-subdomains)
         │         TruffleHog — org-wide verified secret scan
         │         Cloud asset discovery: S3, GCP, Azure (cloud_enum)
         │         Wayback Machine historical URLs
         │         Auto-generated Google Dorks list
         │
         ├──► [3] mine.sh       ⛏️ THE MINER
         │         URL collection: GAU + Katana + Waybackurls
         │         Smart deduplication (uro)
         │         JS isolation + TruffleHog on JS
         │         Target-specific wordlist generation
         │         Parameter extraction + Regex categorization
         │         Categories: XSS / SQLi / LFI / SSRF / RCE / IDOR / 403 / API
         │
         ├──► [4] attack.sh     🔥 THE DRAGON FIRE
         │         JS Secrets (Nuclei)
         │         XSS — Dalfox (advanced DOM + reflected + stored)
         │         SQLi — Nuclei + SQLMap confirmation
         │         LFI / Path Traversal
         │         SSRF + Open Redirect
         │         RCE + Command Injection
         │         CORS Misconfiguration
         │         403/401 Bypass
         │         Tech-targeted attacks (10 stacks)
         │         Login Pages — Default credentials
         │         FFUF fuzzing with custom wordlist
         │         Subdomain Takeover
         │         API Endpoint testing
         │         General Nuclei sweep (final wave)
         │
         └──► [5] report.sh     📋 THE SCRIBE
                   Aggregated REPORT.txt
                   Severity-sorted findings
                   Manual testing checklist
                   Telegram live notifications
                   Critical alert for RCE + Leaked Secrets
```

---

## ⚡ Quick Start

### 1. Clone & Install

```bash
git clone https://github.com/Mohammed-Maher0/Maher-Framework.git
cd Maher-Framework
chmod +x *.sh
./install.sh
```

### 2. Hunt

```bash
# Public target (no header needed)
./pwn.sh -d target.com

# Private Bug Bounty Program (with custom header)
./pwn.sh -d target.com -H "X-Bug-Bounty: HackerOne-your_username"

# Single subdomain (auto-detected, faster mode)
./pwn.sh -d api.target.com

# With Telegram notifications
export TG_TOKEN="your_bot_token"
export TG_CHAT="your_chat_id"
./pwn.sh -d target.com
```

---

## 🛠️ Tools Required

The `install.sh` script handles everything automatically. Below is the full list for reference.

### Core Recon
| Tool | Purpose | Install |
|---|---|---|
| `subfinder` | Passive subdomain enumeration | `go install github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest` |
| `cero` | SSL cert transparency | `go install github.com/glebarez/cero@latest` |
| `puredns` | DNS resolution + wildcard filter | `go install github.com/d3mondev/puredns/v2@latest` |
| `alterx` | Subdomain permutations | `go install github.com/projectdiscovery/alterx/cmd/alterx@latest` |
| `dnsx` | DNS record extraction | `go install github.com/projectdiscovery/dnsx/cmd/dnsx@latest` |
| `asnmap` | ASN / IP range discovery | `go install github.com/projectdiscovery/asnmap/cmd/asnmap@latest` |
| `naabu` | Port scanner | `go install github.com/projectdiscovery/naabu/cmd/naabu@latest` |
| `httpx` | HTTP probing + tech detection | `go install github.com/projectdiscovery/httpx/cmd/httpx@latest` |

### Mining
| Tool | Purpose | Install |
|---|---|---|
| `gau` | Historical URL fetching | `go install github.com/lc/gau/v2/cmd/gau@latest` |
| `katana` | Active web crawling | `go install github.com/projectdiscovery/katana/cmd/katana@latest` |
| `waybackurls` | Wayback Machine URLs | `go install github.com/tomnomnom/waybackurls@latest` |
| `uro` | Smart URL deduplication | `pip install uro` |

### OSINT
| Tool | Purpose | Install |
|---|---|---|
| `github-subdomains` | GitHub subdomain leaks | `go install github.com/gwen001/github-subdomains@latest` |
| `trufflehog` | Verified secret scanning | [Install script](https://github.com/trufflesecurity/trufflehog) |
| `cloud_enum` | S3 / GCP / Azure discovery | `pip install cloud-enum` |

### Attack
| Tool | Purpose | Install |
|---|---|---|
| `nuclei` | Template-based scanning | `go install github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest` |
| `dalfox` | Advanced XSS scanner | `go install github.com/hahwul/dalfox/v2@latest` |
| `sqlmap` | SQL injection testing | `sudo apt install sqlmap` |
| `ffuf` | Directory + parameter fuzzing | `go install github.com/ffuf/ffuf/v2@latest` |

---

## 🔧 Optional Configuration

```bash
# GitHub token — enables GitHub subdomain leak hunting
export GITHUB_TOKEN="ghp_xxxxxxxxxxxx"

# Telegram bot — enables live notifications
export TG_TOKEN="your_telegram_bot_token"
export TG_CHAT="your_telegram_chat_id"

# BBP custom header — auto-injected into all tools
# (pass via -H flag, no need to export manually)
./pwn.sh -d target.com -H "X-HackerOne-Research: your_username"
```

> **How to get a Telegram Bot:** Talk to [@BotFather](https://t.me/BotFather) on Telegram → `/newbot` → copy your token. Get your Chat ID from [@userinfobot](https://t.me/userinfobot).

---

## 📂 Output Structure

After a hunt, your work directory will look like this:

```
targets/target.com_hunt_2025-01-01_12-00/
│
├── 📄 REPORT.txt                  ← Start here — full summary
│
├── alive.txt                      ← All live HTTP hosts
├── all_valid_subs.txt             ← All resolved subdomains
├── all_urls.txt                   ← All collected URLs (deduped)
├── all_params.txt                 ← All parameterized URLs
├── login_pages.txt                ← Detected login pages
├── dns_records.txt                ← A / CNAME / MX / TXT records
├── live_tech.txt                  ← httpx full output with tech info
│
├── technologies/
│   ├── wordpress.txt
│   ├── php.txt
│   ├── nginx.txt
│   └── ...                        ← 10 tech categories
│
├── mining/
│   ├── xss.txt                    ← XSS candidate URLs
│   ├── sqli.txt                   ← SQLi candidate URLs
│   ├── lfi.txt                    ← LFI candidate URLs
│   ├── ssrf_redirect.txt          ← SSRF / Open Redirect URLs
│   ├── rce.txt                    ← RCE candidate URLs
│   ├── idor.txt                   ← IDOR endpoints (manual!)
│   ├── forbidden.txt              ← 403/401 endpoints
│   ├── api_endpoints.txt          ← API routes
│   ├── js_urls.txt                ← Isolated JS files
│   ├── custom_wordlist.txt        ← Target-specific wordlist
│   └── js_secrets_trufflehog.json
│
├── osint/
│   ├── github_subs.txt            ← GitHub leaked subdomains
│   ├── trufflehog_github.json     ← Verified GitHub secrets
│   ├── cloud_storage.txt          ← Open cloud buckets
│   ├── wayback_urls.txt           ← Historical URLs
│   └── google_dorks.txt           ← Ready-to-use dork list
│
└── vulns/
    ├── js_secrets.txt
    ├── xss_dalfox.json            ← Confirmed XSS (Dalfox)
    ├── sqli_nuclei.txt
    ├── sqlmap_results/            ← SQLMap confirmation
    ├── lfi_vulns.txt
    ├── ssrf_vulns.txt
    ├── rce_vulns.txt              ← 🚨 CHECK THIS FIRST
    ├── cors_vulns.txt
    ├── bypass_403.txt
    ├── takeovers.txt
    ├── api_vulns.txt
    ├── login_vulns.txt
    ├── tech_wordpress_vulns.txt
    ├── ffuf_*.json
    └── general_scan.txt
```

---

## 🎯 Subdomain Mode

The framework auto-detects whether your target is a subdomain or a full domain.

```bash
# Full domain — complete pipeline (enum + permutations + ASN)
./pwn.sh -d example.com

# Subdomain — focused mode (skips heavy enum, still hunts siblings)
./pwn.sh -d api.example.com
./pwn.sh -d dev.example.com -H "X-Bug-Bounty: Bugcrowd-username"
```

In subdomain mode, the framework:
- Skips full passive enumeration (saves 5–10 min)
- Skips alterx permutations
- Still discovers sibling subdomains of the root domain
- Runs the full mining + attack pipeline on your target

---

## 🛡️ WAF Evasion

The `-H` flag injects your custom header into **every single request** made by httpx, katana, and nuclei. This is the standard approach for private Bug Bounty Programs on HackerOne, Bugcrowd, and Intigriti to whitelist your traffic and avoid IP bans.

```bash
# HackerOne
./pwn.sh -d target.com -H "X-Bug-Bounty: HackerOne-your_username"

# Bugcrowd
./pwn.sh -d target.com -H "X-Bugcrowd-Username: your_username"

# Intigriti  
./pwn.sh -d target.com -H "X-Intigriti-User: your_username"
```

---

## 📲 Telegram Notifications

Get real-time alerts on your phone the moment something critical is found.

```bash
export TG_TOKEN="110201543:AAHdqTcvCH1vGWJxfSeofSAs0K5PALDsaw"
export TG_CHAT="1234567890"
./pwn.sh -d target.com
```

You'll receive alerts for:
- 🚨 **RCE confirmed** — immediate alert
- 🔑 **Verified secrets leaked** on GitHub
- 📋 **Full REPORT.txt** sent as a file when hunt completes
- 📊 **Stats summary** — live hosts, total findings, critical count

---

## ⚠️ Disclaimer

> This tool is intended for **educational purposes** and **authorized security testing only**.
> 
> Only use Maher Framework against targets you have **explicit written permission** to test — such as targets listed in an official Bug Bounty Program scope, your own infrastructure, or dedicated lab environments.
> 
> The author is **not responsible** for any misuse, damage, or legal consequences arising from unauthorized use of this tool.
> 
> **Always hack responsibly. Always stay in scope.**

---

## 👤 Author

**Mohammed Maher**

[![GitHub](https://img.shields.io/badge/GitHub-Mohammed--Maher0-black?style=flat-square&logo=github)](https://github.com/Mohammed-Maher0)

---

## 🤝 Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

1. Fork the repo
2. Create your feature branch: `git checkout -b feature/new-module`
3. Commit your changes: `git commit -m 'Add new module'`
4. Push to the branch: `git push origin feature/new-module`
5. Open a Pull Request

---

<div align="center">

**If this framework helped you find a bounty, consider giving it a ⭐**

*Happy Hunting 🐉*

</div>
