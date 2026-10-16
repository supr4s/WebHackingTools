#!/usr/bin/env bash
#
# WebHackingTools installer
# https://github.com/supr4s/WebHackingTools
#
# Installs a curated set of web hacking / bug bounty tools.
#  - Idempotent: safe to re-run (symlinks refreshed, repos pulled).
#  - Resilient: each tool is installed independently; one failure never
#    aborts the rest. A success/failure summary is printed at the end.
#  - Self-updating: Go and GitHub releases are resolved to their latest
#    version at runtime (no versions to bump by hand).
#
set -uo pipefail

# --- Resolve script location so it works from any working directory ----------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Optional flags ----------------------------------------------------------
if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
    cat <<'EOF'
Usage: sudo ./installer.sh

Installs all web hacking / bug bounty tools listed in the README.
Configuration lives in .env (TOOLS_DIRECTORY, optional GITHUB_TOKEN).
A timestamped log is written next to the script (install_YYYYMMDD_HHMMSS.log).
EOF
    exit 0
fi

# --- Root check --------------------------------------------------------------
if [ "${EUID:-$(id -u)}" -ne 0 ]; then
    echo "Please execute this script with root privileges (sudo ./installer.sh)" >&2
    exit 1
fi

# --- Load configuration (.env: colors, TOOLS_DIRECTORY, fallbacks) -----------
if [ ! -f "$SCRIPT_DIR/.env" ]; then
    echo "Missing .env file next to installer.sh" >&2
    exit 1
fi
# shellcheck source=/dev/null
source "$SCRIPT_DIR/.env"
[ -n "${GITHUB_TOKEN:-}" ] && export GITHUB_TOKEN

: "${TOOLS_DIRECTORY:?TOOLS_DIRECTORY must be set in .env}"
: "${GO_FALLBACK_VERSION:=1.27.1}"
mkdir -p "$TOOLS_DIRECTORY"

# --- Go environment (used by every `go install`) -----------------------------
export GOPATH="${GOPATH:-$HOME/go}"
export GOBIN="$GOPATH/bin"
mkdir -p "$GOBIN"
export PATH="/usr/local/go/bin:$GOBIN:$PATH"
# /tmp is often a small, RAM-backed tmpfs; compiling big Go tools (nuclei, tlsx)
# there triggers "no space left on device". Put Go's build scratch on a
# disk-backed dir instead.
export GOTMPDIR="${GOTMPDIR:-/var/tmp/wht-go-build}"
mkdir -p "$GOTMPDIR"

# --- Logging -----------------------------------------------------------------
LOGFILE="$SCRIPT_DIR/install_$(date +%Y%m%d_%H%M%S).log"
declare -a OK_LIST=()
declare -a FAIL_LIST=()

_ts()      { date '+%Y-%m-%d %H:%M:%S'; }
log_info() { echo -e "${BLUE}[*]${RESTORE} $*";  echo "[$(_ts)] [INFO] $*" >>"$LOGFILE"; }
log_ok()   { echo -e "${GREEN}[+]${RESTORE} $*"; echo "[$(_ts)] [ OK ] $*" >>"$LOGFILE"; }
log_warn() { echo -e "${YELLOW}[!]${RESTORE} $*"; echo "[$(_ts)] [WARN] $*" >>"$LOGFILE"; }
log_err()  { echo -e "${RED}[-]${RESTORE} $*";   echo "[$(_ts)] [FAIL] $*" >>"$LOGFILE"; }
section()  { echo; echo -e "${LBLUE}==== $* ====${RESTORE}"; echo "" >>"$LOGFILE"; echo "[$(_ts)] ==== $* ====" >>"$LOGFILE"; }

# run "<Nice name>" <command...> : run quietly, log outcome, track OK/FAIL.
# The command is any function/binary below; all output goes to the logfile.
run() {
    local name="$1"; shift
    log_info "$name — installation in progress ..."
    if "$@" >>"$LOGFILE" 2>&1; then
        log_ok "$name installation is done !"
        OK_LIST+=("$name")
        return 0
    else
        log_err "$name installation FAILED (see $LOGFILE)"
        FAIL_LIST+=("$name")
        return 1
    fi
}

print_summary() {
    section "SUMMARY"
    echo -e "${GREEN}Installed : ${#OK_LIST[@]}${RESTORE}"
    echo -e "${RED}Failed    : ${#FAIL_LIST[@]}${RESTORE}"
    if [ "${#FAIL_LIST[@]}" -gt 0 ]; then
        echo -e "${YELLOW}The following tools failed:${RESTORE}"
        for t in "${FAIL_LIST[@]}"; do echo "   - $t"; done
    fi
    echo -e "${LIGHTGRAY}Full log: $LOGFILE${RESTORE}"
    echo "[$(_ts)] SUMMARY ok=${#OK_LIST[@]} fail=${#FAIL_LIST[@]}" >>"$LOGFILE"
}
trap print_summary EXIT

# =============================================================================
#  Generic install helpers
# =============================================================================

# apt-get install (quiet, non-interactive)
apt_install() { DEBIAN_FRONTEND=noninteractive apt-get install -y "$@"; }

# pip install honoring PEP 668 (externally-managed environments).
# All supported OS are externally-managed, so --break-system-packages is always
# the right call. If a tool's pinned requirements would require uninstalling a
# dpkg-managed lib (which pip refuses), retry with --ignore-installed. Errors are
# NOT silenced, so real failures land in the logfile.
pip_install() {
    pip3 install --break-system-packages -q "$@" && return 0
    pip3 install --break-system-packages --ignore-installed -q "$@"
}

# go install + idempotent symlink into /usr/local/bin
#   go_install <binary-name> <module@version>
go_install() {
    local bin="$1" pkg="$2"
    go install "$pkg" || return 1
    ln -sf "$GOBIN/$bin" "/usr/local/bin/$bin"
}

# git clone (shallow) or fast-forward pull if already present (idempotent)
#   git_get <repo-url> <destination>
git_get() {
    local repo="$1" dest="$2"
    if [ -d "$dest/.git" ]; then
        git -C "$dest" pull --quiet --ff-only || true
    else
        rm -rf "$dest"
        git clone --depth 1 --quiet "$repo" "$dest"
    fi
}

# git_get + install Python requirements if present
#   git_pip <repo-url> <destination>
git_pip() {
    local repo="$1" dest="$2"
    git_get "$repo" "$dest" || return 1
    if [ -f "$dest/requirements.txt" ]; then
        pip_install -r "$dest/requirements.txt" || return 1
    fi
    return 0
}

# curl against the GitHub API, authenticated if GITHUB_TOKEN is set
_gh_curl() {
    if [ -n "${GITHUB_TOKEN:-}" ]; then
        curl -fsSL -H "Authorization: Bearer $GITHUB_TOKEN" "$@"
    else
        curl -fsSL "$@"
    fi
}

# Download the latest release asset matching a regex
#   dl_asset <owner/repo> <asset-name-regex> <output-path>
dl_asset() {
    local repo="$1" pattern="$2" out="$3" url
    url="$(_gh_curl "https://api.github.com/repos/$repo/releases/latest" \
          | grep -Po '"browser_download_url":\s*"\K[^"]+' \
          | grep -E "$pattern" | head -n1)"
    if [ -z "$url" ]; then
        echo "No release asset matching /$pattern/ for $repo" >&2
        return 1
    fi
    curl -fsSL "$url" -o "$out"
}

# Append a line to ~/.bashrc only if not already present
add_bashrc() {
    local line="$1" file="$HOME/.bashrc"
    touch "$file"
    grep -qxF "$line" "$file" || echo "$line" >> "$file"
}

# =============================================================================
#  Tool-specific install functions (multi-step installs)
# =============================================================================

install_golang() {
    local gover
    # shellcheck disable=SC2016  # literal $PATH/$HOME wanted in .bashrc
    add_bashrc 'export PATH=/usr/local/go/bin:$HOME/go/bin:$PATH'
    # shellcheck disable=SC2016
    add_bashrc 'export GOPATH=$HOME/go'
    gover="$(curl -fsSL 'https://go.dev/VERSION?m=text' 2>/dev/null | head -n1 | sed 's/^go//')"
    [ -n "$gover" ] || gover="$GO_FALLBACK_VERSION"
    if [ -x /usr/local/go/bin/go ] && [ "$(/usr/local/go/bin/go env GOVERSION 2>/dev/null | sed 's/^go//')" = "$gover" ]; then
        return 0   # already on the latest version
    fi
    curl -fsSL "https://dl.google.com/go/go${gover}.linux-amd64.tar.gz" -o /tmp/go.tar.gz || return 1
    rm -rf /usr/local/go
    tar -C /usr/local -xzf /tmp/go.tar.gz || return 1
    rm -f /tmp/go.tar.gz
}

# commonspeak2 ships no go.mod (glide-based), install from the release binary.
install_commonspeak2() {
    dl_asset "assetnote/commonspeak2" 'Linux_x86_64\.tar\.gz$' /tmp/commonspeak2.tar.gz || return 1
    tar -xzf /tmp/commonspeak2.tar.gz -C /tmp commonspeak2 || return 1
    install -m 0755 /tmp/commonspeak2 /usr/local/bin/commonspeak2
}

# hopgoblin is a Python3 AEM toolkit with no shebang: install deps + a launcher.
install_hopgoblin() {
    local src="$TOOLS_DIRECTORY/hopgoblin"
    git_get https://github.com/assetnote/hopgoblin.git "$src" || return 1
    pip_install -r "$src/requirements.txt" || return 1
    printf '#!/bin/sh\nexec python3 "%s/hopgoblin.py" "$@"\n' "$src" > /usr/local/bin/hopgoblin
    chmod 0755 /usr/local/bin/hopgoblin
}

# jwt_tool: py3 script (shebang) + requirements, symlink into PATH.
install_jwt_tool() {
    local src="$TOOLS_DIRECTORY/jwt_tool"
    git_pip https://github.com/ticarpi/jwt_tool.git "$src" || return 1
    chmod +x "$src/jwt_tool.py"
    ln -sf "$src/jwt_tool.py" /usr/local/bin/jwt_tool
}

# smuggler: single self-contained py3 script (stdlib only), symlink into PATH.
install_smuggler() {
    local src="$TOOLS_DIRECTORY/smuggler"
    git_get https://github.com/defparam/smuggler.git "$src" || return 1
    chmod +x "$src/smuggler.py"
    ln -sf "$src/smuggler.py" /usr/local/bin/smuggler
}

install_findomain() {
    dl_asset "findomain/findomain" 'findomain-linux\.zip$' /tmp/findomain-linux.zip || return 1
    unzip -o -q /tmp/findomain-linux.zip -d /tmp || return 1
    install -m 0755 /tmp/findomain /usr/local/bin/findomain
}

install_massdns() {
    git_get https://github.com/blechschmidt/massdns.git "$TOOLS_DIRECTORY/massdns" || return 1
    make -C "$TOOLS_DIRECTORY/massdns" || return 1
    ln -sf "$TOOLS_DIRECTORY/massdns/bin/massdns" /usr/local/bin/massdns
}

install_masscan() {
    git_get https://github.com/robertdavidgraham/masscan.git "$TOOLS_DIRECTORY/masscan" || return 1
    make -C "$TOOLS_DIRECTORY/masscan" -j"$(nproc)" || return 1
    install -m 0755 "$TOOLS_DIRECTORY/masscan/bin/masscan" /usr/local/bin/masscan
}

install_x8() {
    dl_asset "Sh1Yo/x8" 'x86_64-linux-x8\.gz$' /tmp/x8.gz || return 1
    gzip -df /tmp/x8.gz || return 1
    install -m 0755 /tmp/x8 /usr/local/bin/x8
}

install_linkfinder() {
    git_get https://github.com/GerbenJavado/LinkFinder.git "$TOOLS_DIRECTORY/LinkFinder" || return 1
    pip_install "$TOOLS_DIRECTORY/LinkFinder"
}

install_ppfuzz() {
    dl_asset "dwisiswant0/ppfuzz" 'x86_64-unknown-linux-musl\.tar\.gz$' /tmp/ppfuzz.tar.gz || return 1
    tar -xzf /tmp/ppfuzz.tar.gz -C /tmp || return 1
    install -m 0755 /tmp/ppfuzz /usr/local/bin/ppfuzz
}

# ppmap's setup.sh no longer compiles against current chromedp and relies on
# sudo; upstream publishes a prebuilt Linux binary, use it (needs chromium).
install_ppmap() {
    dl_asset "kleiton0x00/ppmap" '/ppmap$' /tmp/ppmap || return 1
    install -m 0755 /tmp/ppmap /usr/local/bin/ppmap
}

install_gopherus() {
    # Python3 maintained fork of tarunkant/Gopherus
    git_pip https://github.com/Esonhugh/Gopherus3.git "$TOOLS_DIRECTORY/Gopherus3"
}

install_kiterunner() {
    dl_asset "assetnote/kiterunner" 'linux_amd64\.tar\.gz$' /tmp/kiterunner.tar.gz || return 1
    tar -xzf /tmp/kiterunner.tar.gz -C /tmp || return 1
    install -m 0755 /tmp/kr /usr/local/bin/kr
    local wl="$TOOLS_DIRECTORY/kiterunner-wordlists"
    mkdir -p "$wl"
    ( cd "$wl" \
        && curl -fsSL -O https://wordlists-cdn.assetnote.io/data/kiterunner/routes-large.kite.tar.gz \
        && curl -fsSL -O https://wordlists-cdn.assetnote.io/data/kiterunner/routes-small.kite.tar.gz \
        && for f in *.kite.tar.gz; do tar xf "$f" && rm -f "$f"; done )
}

install_nuclei() {
    go_install nuclei github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest || return 1
    nuclei -update-templates || true
}

# Upstream build.sh runs the whole test-suite and 4 cross-compiles; build
# the Linux binary directly and mirror what install.sh does (config dir).
install_earlybird() {
    local src="$TOOLS_DIRECTORY/earlybird"
    git_get https://github.com/americanexpress/earlybird.git "$src" || return 1
    ( cd "$src" && go build -o /usr/local/bin/go-earlybird . ) || return 1
    mkdir -p "$HOME/.go-earlybird"
    cp -a "$src/config/." "$HOME/.go-earlybird/"
    cp "$src/.ge_ignore" "$HOME/.ge_ignore"
}

# unKover is a single self-contained bash script (bash + curl only).
install_unkover() {
    git_get https://github.com/BruteLogic/unKover.git "$TOOLS_DIRECTORY/unKover" || return 1
    install -m 0755 "$TOOLS_DIRECTORY/unKover/unkover" /usr/local/bin/unkover
}

# trufflehog's go.mod now carries `replace` directives, so `go install` is
# refused by Go; use the official release binary instead.
install_trufflehog() {
    dl_asset "trufflesecurity/trufflehog" 'linux_amd64\.tar\.gz$' /tmp/trufflehog.tar.gz || return 1
    tar -xzf /tmp/trufflehog.tar.gz -C /tmp trufflehog || return 1
    install -m 0755 /tmp/trufflehog /usr/local/bin/trufflehog
}

# gobypass403 / depx ship a go.mod with `replace` directives, so `go install`
# is not allowed by Go; use the prebuilt release binaries instead.
install_gobypass403() {
    dl_asset "slicingmelon/gobypass403" 'linux_amd64$' /tmp/gobypass403 || return 1
    install -m 0755 /tmp/gobypass403 /usr/local/bin/gobypass403
}

install_depx() {
    dl_asset "projectdiscovery/depx" 'linux_amd64\.zip$' /tmp/depx.zip || return 1
    rm -rf /tmp/depx-extract
    unzip -o -q /tmp/depx.zip -d /tmp/depx-extract || return 1
    install -m 0755 /tmp/depx-extract/depx /usr/local/bin/depx
}

# =============================================================================
#  Environment
# =============================================================================

detect_os() {
    OS="$(lsb_release -i 2>/dev/null | cut -d ':' -f2 | tr -d '\t ')"
    if [ -z "$OS" ] && [ -f /etc/os-release ]; then
        OS="$( . /etc/os-release; echo "${ID^}" )"
    fi
    case "$OS" in
        Debian|Kali|Ubuntu|Linuxmint) : ;;
        *) log_warn "OS '$OS' not officially tested — proceeding on a Debian/apt basis." ;;
    esac
    ARCH="$(dpkg --print-architecture 2>/dev/null || uname -m)"
    case "$ARCH" in
        amd64|x86_64) : ;;
        *) log_warn "Architecture '$ARCH' is not supported: Go and prebuilt release binaries are fetched for amd64 only." ;;
    esac
}

ENVIRONMENT() {
    section "ENVIRONMENT"
    local common="python3 python3-pip python3-venv unzip make gcc curl wget git jq \
build-essential libpcap-dev libcurl4-openssl-dev libxml2 libxml2-dev libxslt1-dev \
ruby-dev ruby libgmp-dev zlib1g-dev"
    local chromium_pkg="chromium"
    [ "$OS" = "Ubuntu" ] && chromium_pkg="chromium-browser"

    log_info "APT — updating package index ($OS) ..."
    apt-get update -y >>"$LOGFILE" 2>&1
    # shellcheck disable=SC2086
    run "APT base packages" apt_install $common
    run "Chromium ($chromium_pkg)" apt_install "$chromium_pkg"

    # Colored bash prompt
    sed -i '/^#.*force_color_prompt/s/^#//' ~/.bashrc 2>/dev/null || true

    run "Golang" install_golang
}

# =============================================================================
#  Tool categories
# =============================================================================

SUBDOMAINS_ENUMERATION() {
    section "SUBDOMAINS ENUMERATION"
    run "Subfinder"         go_install subfinder         github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
    run "Assetfinder"       go_install assetfinder       github.com/tomnomnom/assetfinder@latest
    run "Findomain"         install_findomain
    run "Github-subdomains" go_install github-subdomains  github.com/gwen001/github-subdomains@latest
    run "Gitlab-subdomains" go_install gitlab-subdomains  github.com/gwen001/gitlab-subdomains@latest
    run "Amass"             go_install amass             github.com/owasp-amass/amass/v4/cmd/amass@latest
}

DNS_RESOLVER() {
    section "DNS RESOLVER"
    run "MassDNS"    install_massdns
    run "dnsx"       go_install dnsx       github.com/projectdiscovery/dnsx/cmd/dnsx@latest
    run "PureDNS"    go_install puredns    github.com/d3mondev/puredns/v2@latest
    run "shuffledns" go_install shuffledns github.com/projectdiscovery/shuffledns/cmd/shuffledns@latest
    run "dnsgen"     pip_install dnsgen
}

HTTP_PROBE() {
    section "HTTP PROBE"
    run "httpx"    go_install httpx    github.com/projectdiscovery/httpx/cmd/httpx@latest
    run "httprobe" go_install httprobe github.com/tomnomnom/httprobe@latest
}

VISUAL_RECON() {
    section "VISUAL RECON"
    run "Gowitness"  go_install gowitness github.com/sensepost/gowitness@latest
    run "AIquatone"  go_install aiquatone github.com/supr4s/aiquatone@latest
}

NETWORK_SCANNER() {
    section "NETWORK SCANNER"
    run "Nmap"    apt_install nmap
    run "Masscan" install_masscan
    run "Naabu"   go_install naabu   github.com/projectdiscovery/naabu/v2/cmd/naabu@latest
    run "Smap"    go_install smap    github.com/s0md3v/smap/cmd/smap@latest
    run "mapcidr" go_install mapcidr github.com/projectdiscovery/mapcidr/cmd/mapcidr@latest
}

WEB_CRAWLING() {
    section "WEB CRAWLING"
    run "Gospider"  go_install gospider  github.com/jaeles-project/gospider@latest
    run "Hakrawler" go_install hakrawler github.com/hakluke/hakrawler@latest
    run "Katana"    go_install katana    github.com/projectdiscovery/katana/cmd/katana@latest
    run "cariddi"   go_install cariddi   github.com/edoardottt/cariddi/cmd/cariddi@latest
}

HTTP_PARAMETER() {
    section "HTTP PARAMETER DISCOVERY"
    run "Arjun"       pip_install arjun
    run "x8"          install_x8
    run "ParamSpider" pip_install "git+https://github.com/devanshbatham/ParamSpider.git"
}

JS_HUNTING() {
    section "JS FILES HUNTING"
    run "LinkFinder"   install_linkfinder
    run "SecretFinder" git_pip https://github.com/m4ll0k/SecretFinder.git "$TOOLS_DIRECTORY/SecretFinder"
    run "subjs"        go_install subjs github.com/lc/subjs@latest
    run "xnLinkFinder" pip_install xnLinkFinder
    run "jsluice"      go_install jsluice github.com/BishopFox/jsluice/cmd/jsluice@latest
}

BYPASS_40X() {
    section "BYPASS 40X"
    run "nomore403"   go_install nomore403 github.com/devploit/nomore403@latest
    run "gobypass403" install_gobypass403
    run "unKover"     install_unkover
}

DEPENDENCY_CONFUSION() {
    section "DEPENDENCY CONFUSION / SUPPLY CHAIN"
    run "confused"  go_install confused  github.com/visma-prodsec/confused@latest
    run "depx"      install_depx
    run "dustilock" go_install dustilock github.com/checkmarx/dustilock@latest
}

CORS_TOOLS() {
    section "CORS MISCONFIGURATION"
    run "Corsy"      git_pip https://github.com/s0md3v/Corsy.git "$TOOLS_DIRECTORY/Corsy"
    run "CORScanner" pip_install corscanner
}

FUZZING_TOOLS() {
    section "FUZZING TOOLS"
    run "ffuf"     go_install ffuf     github.com/ffuf/ffuf/v2@latest
    run "Gobuster" go_install gobuster github.com/OJ/gobuster/v3@latest
    run "wfuzz"     apt_install wfuzz
    run "fuzzuli"   go_install fuzzuli  github.com/musana/fuzzuli@latest
    run "dirsearch" pip_install dirsearch
}

PROTO_POLLUTION() {
    section "PROTOTYPE POLLUTION"
    run "ppfuzz" install_ppfuzz
    run "ppmap"  install_ppmap
}

SSRF_TOOLS() {
    section "SSRF TOOLS"
    run "SSRFmap"    git_pip https://github.com/swisskyrepo/SSRFmap.git "$TOOLS_DIRECTORY/SSRFmap"
    run "Gopherus3"  install_gopherus
    run "Interactsh" go_install interactsh-client github.com/projectdiscovery/interactsh/cmd/interactsh-client@latest
    run "AutoSSRF"   git_pip https://github.com/Th0h0/autossrf.git "$TOOLS_DIRECTORY/autossrf"
    run "surf"       go_install surf github.com/assetnote/surf/cmd/surf@latest
}

SSTI_TOOLS() {
    section "SSTI TOOLS"
    run "SSTImap" git_pip https://github.com/vladko312/SSTImap.git "$TOOLS_DIRECTORY/SSTImap"
}

API_TOOLS() {
    section "API TOOLS"
    run "Kiterunner" install_kiterunner
}

XSS_TOOLS() {
    section "XSS"
    run "Dalfox"   go_install dalfox github.com/hahwul/dalfox/v2@latest
    run "XSStrike" git_pip https://github.com/s0md3v/XSStrike.git "$TOOLS_DIRECTORY/XSStrike"
    run "kxss"     go_install kxss   github.com/tomnomnom/hacks/kxss@latest
}

SQLI_TOOLS() {
    section "SQL INJECTION"
    run "SQLMap" apt_install sqlmap
    run "nosqli" go_install nosqli github.com/Charlie-belmer/nosqli@latest
    run "Ghauri" pip_install "git+https://github.com/r0oth3x49/ghauri.git"
}

VULNS_SCANNER() {
    section "VULNERABILITY SCANNER"
    run "Nuclei" install_nuclei
}

CMS_SCANNER() {
    section "CMS SCANNER"
    run "WPScan"     gem install wpscan
    run "droopescan" pip_install droopescan
    run "AEM-hacker" git_pip https://github.com/0ang3el/aem-hacker.git "$TOOLS_DIRECTORY/aem-hacker"
    run "hopgoblin"  install_hopgoblin
}

WORDLISTS() {
    section "WORDLISTS"
    run "OneListForAll" git_get https://github.com/six2dez/OneListForAll.git "$TOOLS_DIRECTORY/OneListForAll"
    run "commonspeak2"  install_commonspeak2
}

GIT_HUNTING() {
    section "GIT HUNTING"
    run "GitDorker" git_pip https://github.com/obheda12/GitDorker.git "$TOOLS_DIRECTORY/GitDorker"
    run "gitGraber" git_pip https://github.com/hisxo/gitGraber.git "$TOOLS_DIRECTORY/gitGraber"
    run "GitHacker" pip_install GitHacker
    run "GitTools"  git_get https://github.com/internetwache/GitTools.git "$TOOLS_DIRECTORY/GitTools"
}

SENSITIVE_FINDING() {
    section "SENSITIVE FINDING TOOLS"
    run "EarlyBird"     install_earlybird
    run "Ripgrep"       apt_install ripgrep
    run "Trufflehog"    install_trufflehog
    run "gitleaks"      go_install gitleaks   github.com/zricethezav/gitleaks/v8@latest
}

USEFUL_TOOLS() {
    section "USEFUL TOOLS"
    run "getallurls"  go_install gau         github.com/lc/gau/v2/cmd/gau@latest
    run "urlfinder"   go_install urlfinder   github.com/projectdiscovery/urlfinder/cmd/urlfinder@latest
    run "anti-burl"   go_install anti-burl   github.com/tomnomnom/hacks/anti-burl@latest
    run "unfurl"      go_install unfurl      github.com/tomnomnom/unfurl@latest
    run "anew"        go_install anew        github.com/tomnomnom/anew@latest
    run "gron"        go_install gron        github.com/tomnomnom/gron@latest
    run "qsreplace"   go_install qsreplace   github.com/tomnomnom/qsreplace@latest
    run "waybackurls" go_install waybackurls github.com/tomnomnom/waybackurls@latest
    run "waymore"     pip_install waymore
    run "gf"          go_install gf          github.com/tomnomnom/gf@latest
    run "notify"      go_install notify      github.com/projectdiscovery/notify/cmd/notify@latest
    run "jq"          apt_install jq
    run "Tmux"        apt_install tmux
    run "Uro"         pip_install uro
}

SUBDOMAIN_TAKEOVER() {
    section "SUBDOMAIN TAKEOVER"
    run "subzy" go_install subzy github.com/PentestPad/subzy@latest
}

OPEN_REDIRECT() {
    section "OPEN REDIRECT"
    run "Oralyzer" pip_install oralyzer
}

CRLF_INJECTION() {
    section "CRLF INJECTION"
    run "crlfuzz" go_install crlfuzz github.com/dwisiswant0/crlfuzz/cmd/crlfuzz@latest
}

HTTP_SMUGGLING() {
    section "HTTP REQUEST SMUGGLING"
    run "smuggler" install_smuggler
}

JWT_TOOLS() {
    section "JWT"
    run "jwt_tool" install_jwt_tool
}

# =============================================================================
#  Cleanup
# =============================================================================

# Go's build cache ($GOCACHE) and module cache ($GOPATH/pkg/mod) can hold several
# GB after building ~45 tools. The installed binaries live in /usr/local/bin, so
# these caches are pure disk cost afterwards — reclaim them.
reclaim_disk() {
    section "CLEANUP"
    log_info "Reclaiming disk space (Go build/module caches, scratch) ..."
    go clean -cache    >>"$LOGFILE" 2>&1 || true
    go clean -modcache >>"$LOGFILE" 2>&1 || true
    rm -rf "$GOTMPDIR" /tmp/go.tar.gz >>"$LOGFILE" 2>&1 || true
    log_ok "Disk cleanup done"
}

# =============================================================================
#  Main
# =============================================================================

clear
cat "$SCRIPT_DIR/banner/banner.txt" 2>/dev/null || true
echo
log_info "Logging to $LOGFILE"

detect_os

# ESSENTIALS
ENVIRONMENT

# RECON - 1
SUBDOMAINS_ENUMERATION
DNS_RESOLVER
HTTP_PROBE
VISUAL_RECON
NETWORK_SCANNER
SUBDOMAIN_TAKEOVER

# RECON - 2
WEB_CRAWLING
HTTP_PARAMETER
JS_HUNTING

# VULNS
BYPASS_40X
CORS_TOOLS
FUZZING_TOOLS
PROTO_POLLUTION
SSRF_TOOLS
SSTI_TOOLS
API_TOOLS
XSS_TOOLS
SQLI_TOOLS
OPEN_REDIRECT
CRLF_INJECTION
HTTP_SMUGGLING
JWT_TOOLS

# VULNS - GENERIC
VULNS_SCANNER
CMS_SCANNER
DEPENDENCY_CONFUSION

# WORDLISTS
WORDLISTS

# SENSITIVE STUFF
GIT_HUNTING
SENSITIVE_FINDING

# IN ADDITION
USEFUL_TOOLS

# FREE DISK SPACE
reclaim_disk

# print_summary runs automatically via the EXIT trap
