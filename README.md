# WebHackingTools

________
**NOTE** : Initially coded 100% by hand, I used AI as an assistant for the latest version to facilitate deployment, code review, and the addition of new features.
______________

Automatically install some web hacking/bug bounty tools for your VPS/hacking station.

- **Idempotent**: safe to re-run, every tool is refreshed to its latest version (repos pulled, Go tools rebuilt, GitHub releases re-resolved).
- **Resilient**: each tool is installed independently, one failure never aborts the rest. A summary of what succeeded/failed is printed at the end and a full log is written next to the script.
- **No version to bump**: Go, Go tools and GitHub release binaries are resolved to `latest` at run time.

<b>O.S supported :heavy_check_mark: </b>

- Debian 13 x64 

- Kali Linux (rolling) x64

- Linux Mint 22 x64

- Ubuntu 24.04 LTS x64 



[![asciicast](https://asciinema.org/a/E2xfEuuvWhuO3RzlDnSdebCZR.svg)](https://asciinema.org/a/E2xfEuuvWhuO3RzlDnSdebCZR)



# Installation
## 💻 Manual: laptop/VPS/other 

```
apt-get update -y && apt-get install git -y
cd /tmp && git clone https://github.com/supr4s/WebHackingTools && cd WebHackingTools && sudo ./installer.sh
```

## ⚙️ Configuration

Everything lives in `.env`, next to the script:

| Variable | Default | Purpose |
|---|---|---|
| `TOOLS_DIRECTORY` | `/home/hack/tools` | Where git-cloned tools and wordlists are stored |
| `GO_FALLBACK_VERSION` | `1.27.1` | Go version used only if `https://go.dev/VERSION` is unreachable |
| `GITHUB_TOKEN` | *(unset)* | Optional. Raises the GitHub API rate limit used to resolve latest releases |

Go tools are installed in `/root/go/bin` and symlinked into `/usr/local/bin`. A timestamped log (`install_YYYYMMDD_HHMMSS.log`) is written next to the script; failed tools are listed in the final summary.

Requirements: `amd64` only (Go toolchain and prebuilt release binaries are fetched for `linux-amd64`).

## 🐳 Docker

The image is built straight from `installer.sh` using the provided
[`Dockerfile`](Dockerfile) (base: Debian 13), so it always matches this repo.

Build it:

```
git clone https://github.com/supr4s/WebHackingTools && cd WebHackingTools
docker build -t webhackingtools .
```

> Expect a large image (several GB): it compiles ~100 tools and ships
> wordlists. The build is long.

A build makes only a handful of GitHub API calls, so no token is needed. If you
rebuild many times in an hour (or build behind a shared IP) and hit the API rate
limit, you can pass one: `docker build --build-arg GITHUB_TOKEN=ghp_xxx .`

Run it:

```
docker run --name webhackingtools -it webhackingtools
```

Tools that take screenshots (AIquatone, Gowitness, ppmap) drive Chromium and
need an extra flag in a container:

```
docker run --name webhackingtools --cap-add=SYS_ADMIN -it webhackingtools
# then pass --no-sandbox to the screenshotting tool
```

Detach without stopping the container with `ctrl + p` then `ctrl + q`, and
re-attach later with `docker attach webhackingtools`.


## Available tools list

### Subdomains enumeration

- [Amass](https://github.com/owasp-amass/amass)
- [Assetfinder](https://github.com/tomnomnom/assetfinder)
- [Findomain](https://github.com/Findomain/Findomain)
- [Github-subdomains](https://github.com/gwen001/github-subdomains)
- [Gitlab-subdomains](https://github.com/gwen001/gitlab-subdomains)
- [Subfinder](https://github.com/projectdiscovery/subfinder)

### DNS resolver

- [dnsgen](https://github.com/ProjectAnte/dnsgen) *
- [dnsx](https://github.com/projectdiscovery/dnsx)
- [MassDNS](https://github.com/blechschmidt/massdns)
- [PureDNS](https://github.com/d3mondev/puredns)
- [shuffledns](https://github.com/projectdiscovery/shuffledns) *

### HTTP probe

- [httprobe](https://github.com/tomnomnom/httprobe)
- [httpx](https://github.com/projectdiscovery/httpx)

### Visual recon

- [AIquatone](https://github.com/supr4s/AIquatone) *
- [Gowitness](https://github.com/sensepost/gowitness)

### Network scanner

- [mapcidr](https://github.com/projectdiscovery/mapcidr) *
- [Masscan](https://github.com/robertdavidgraham/masscan)
- [Naabu](https://github.com/projectdiscovery/naabu)
- [Nmap](https://nmap.org/)
- [Smap](https://github.com/s0md3v/Smap)

### Subdomain takeover

- [subzy](https://github.com/PentestPad/subzy) *

### Web crawler

- [cariddi](https://github.com/edoardottt/cariddi) *
- [Gospider](https://github.com/jaeles-project/gospider)
- [Hakrawler](https://github.com/hakluke/hakrawler)
- [Katana](https://github.com/projectdiscovery/katana)

### HTTP parameter

- [Arjun](https://github.com/s0md3v/Arjun)
- [ParamSpider](https://github.com/devanshbatham/ParamSpider) *
- [x8](https://github.com/Sh1Yo/x8/)

### JavaScript hunting

- [LinkFinder](https://github.com/GerbenJavado/LinkFinder)
- [SecretFinder](https://github.com/m4ll0k/SecretFinder)
- [jsluice](https://github.com/BishopFox/jsluice) *
- [subjs](https://github.com/lc/subjs)
- [xnLinkFinder](https://github.com/xnl-h4ck3r/xnLinkFinder)

### Bypass 40X

- [nomore403](https://github.com/devploit/nomore403)
- [gobypass403](https://github.com/slicingmelon/gobypass403) *
- [unKover](https://github.com/BruteLogic/unKover) *

### CORS tools

- [Corsy](https://github.com/s0md3v/Corsy)
- [CORScanner](https://github.com/chenjj/CORScanner)

### Fuzzing tools

- [ffuf](https://github.com/ffuf/ffuf)
- [Gobuster](https://github.com/OJ/gobuster)
- [wfuzz](https://github.com/xmendez/wfuzz)
- [fuzzuli](https://github.com/musana/fuzzuli)

### Prototype pollution

- [ppfuzz](https://github.com/dwisiswant0/ppfuzz)
- [ppmap](https://github.com/kleiton0x00/ppmap)

### SSRF tools

- [SSRFmap](https://github.com/swisskyrepo/SSRFmap)
- [Gopherus3](https://github.com/Esonhugh/Gopherus3) *
- [Interactsh](https://github.com/projectdiscovery/interactsh)
- [AutoSSRF](https://github.com/Th0h0/autossrf)
- [surf](https://github.com/assetnote/surf) *

### SSTI tools

- [SSTImap](https://github.com/vladko312/SSTImap) *

### API hacking tools

- [Kiterunner + API routes](https://github.com/assetnote/kiterunner)

### Vulns - XSS

- [Dalfox](https://github.com/hahwul/dalfox)
- [kxss](https://github.com/tomnomnom/hacks/tree/master/kxss)
- [XSStrike](https://github.com/s0md3v/XSStrike)

### Vulns - SQL Injection

- [Ghauri](https://github.com/r0oth3x49/ghauri) *
- [nosqli](https://github.com/Charlie-belmer/nosqli) *
- [SQLMap](https://github.com/sqlmapproject/sqlmap)

### Open redirect

- [Oralyzer](https://github.com/r0075h3ll/Oralyzer) *

### CRLF injection

- [crlfuzz](https://github.com/dwisiswant0/crlfuzz) *

### HTTP request smuggling

- [smuggler](https://github.com/defparam/smuggler) *

### JWT

- [jwt_tool](https://github.com/ticarpi/jwt_tool) *

### Vulns - Scanner

- [Nuclei](https://github.com/projectdiscovery/nuclei)

### CMS Scanner

- [WPscan](https://github.com/wpscanteam/wpscan)
- [droopescan](https://github.com/droope/droopescan)
- [AEM-Hacker](https://github.com/0ang3el/aem-hacker)
- [hopgoblin](https://github.com/assetnote/hopgoblin) *

### Dependency confusion / Supply chain

- [confused](https://github.com/visma-prodsec/confused) *
- [depx](https://github.com/projectdiscovery/depx) *
- [dustilock](https://github.com/Checkmarx/dustilock) *

### Wordlists

- [commonspeak2](https://github.com/assetnote/commonspeak2) *
- [OneListForAll](https://github.com/six2dez/OneListForAll)

### Git hunting

- [GitDorker](https://github.com/obheda12/GitDorker)
- [gitGraber](https://github.com/hisxo/gitGraber)
- [GitHacker](https://github.com/WangYihang/GitHacker)
- [GitTools](https://github.com/internetwache/GitTools)

### Sensitive stuff finding

- [EarlyBird](https://github.com/americanexpress/earlybird)
- [gitleaks](https://github.com/gitleaks/gitleaks) *
- [Ripgrep](https://github.com/BurntSushi/ripgrep)
- [Trufflehog](https://github.com/trufflesecurity/trufflehog)

### Useful tools

- [anew](https://github.com/tomnomnom/anew)
- [anti-burl](https://github.com/tomnomnom/hacks/tree/master/anti-burl)
- [gau](https://github.com/lc/gau)
- [gf](https://github.com/tomnomnom/gf) *
- [gron](https://github.com/tomnomnom/gron)
- [jq](https://github.com/stedolan/jq)
- [notify](https://github.com/projectdiscovery/notify) *
- [qsreplace](https://github.com/tomnomnom/qsreplace)
- [Tmux](https://github.com/tmux/tmux)
- [unfurl](https://github.com/tomnomnom/unfurl)
- [urlfinder](https://github.com/projectdiscovery/urlfinder) *
- [Uro](https://github.com/s0md3v/uro)
- [waybackurls](https://github.com/tomnomnom/waybackurls) *
- [waymore](https://github.com/xnl-h4ck3r/waymore) *

### Note

- Refer to the usage of the tools as most of them require configuration (especially for subdomains enumeration).
- Please be careful with these tools and only use them on targets you have explicitly authorized.

**N.B** : * = added in the last update
