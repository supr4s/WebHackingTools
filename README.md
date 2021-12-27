# VPS-web-hacking-tools

Automatically install some web hacking/bug bounty tools for your VPS.

<b>O.S supported :heavy_check_mark: </b>

- Ubuntu20.04 x64 

- Debian 10/11 x64 

- Linux Mint 20.2 x64

- Kali Linux 2021.4 x64



[![asciicast](https://asciinema.org/a/ZjvDJJ6ZJsQvk4tuUbplaTf8a.svg)](https://asciinema.org/a/ZjvDJJ6ZJsQvk4tuUbplaTf8a)



## Installation 

```
apt-get update -y && apt-get install git -y
cd /tmp && git clone https://github.com/supr4s/VPS-web-hacking-tools && cd VPS-web-hacking-tools && ./installer.sh
```

## Available tools list

### Subdomains enumeration

- [Amass](https://github.com/OWASP/Amass)
- [Assetfinder](https://github.com/tomnomnom/assetfinder)
- [Crobat](https://github.com/Cgboal/SonarSearch)
- [Findomain](https://github.com/Findomain/Findomain)
- [Github-subdomains](https://github.com/gwen001/github-subdomains)
- [Subfinder](https://github.com/projectdiscovery/subfinder)

### DNS resolver

- [dnsx](https://github.com/projectdiscovery/dnsx)
- [MassDNS](https://github.com/blechschmidt/massdns)
- [PureDNS](https://github.com/d3mondev/puredns)

### Visual recon

- [Aquatone](https://github.com/michenriksen/aquatone)
- [Gowitness](https://github.com/sensepost/gowitness)

### HTTP probe

- [httprobe](https://github.com/tomnomnom/httprobe)
- [httpx](https://github.com/projectdiscovery/httpx)

### Web crawler

- [Gospider](https://github.com/jaeles-project/gospider)
- [Hakrawler](https://github.com/hakluke/hakrawler)

### Network scanner

- [Masscan](https://github.com/robertdavidgraham/masscan)
- [Naabu](https://github.com/projectdiscovery/naabu)
- [Nmap](https://nmap.org/)

### HTTP parameter

- [Arjun](https://github.com/s0md3v/Arjun)
- [x8](https://github.com/Sh1Yo/x8/) *

### Fuzzing tools

- [ffuf](https://github.com/ffuf/ffuf)
- [Gobuster](https://github.com/OJ/gobuster)
- [wfuzz](https://github.com/xmendez/wfuzz) *

### LFI tools

- [LFISuite](https://github.com/D35m0nd142/LFISuite) *

### SSRF tools

- [SSRFmap](https://github.com/swisskyrepo/SSRFmap)
- [Gopherus](https://github.com/tarunkant/Gopherus)
- [Interactsh](https://github.com/projectdiscovery/interactsh)

### SSTI tools

- [tplmap](https://github.com/epinna/tplmap) *

### API hacking tools

- [Kiterunner + API routes](https://github.com/assetnote/kiterunner)

### Wordlists

- [SecLists](https://github.com/danielmiessler/SecLists)

### Vulns - XSS

- [Dalfox](https://github.com/hahwul/dalfox)
- [kxss](https://github.com/tomnomnom/hacks/tree/master/kxss)
- [XSStrike](https://github.com/s0md3v/XSStrike)

### Vulns - SQL Injection

- [NoSQLMap](https://github.com/codingo/NoSQLMap)
- [SQLMap](https://github.com/sqlmapproject/sqlmap)

### CMS Scanner

- [WPscan](https://github.com/wpscanteam/wpscan)
- [droopescan](https://github.com/droope/droopescan)
- [AEM-Hacker](https://github.com/0ang3el/aem-hacker)

### Vulns - Scanner

- [Jaeles](https://github.com/jaeles-project/jaeles)
- [Nikto](https://github.com/sullo/nikto) **
- [Nuclei](https://github.com/projectdiscovery/nuclei)

### JavaScript hunting

- [LinkFinder](https://github.com/GerbenJavado/LinkFinder)
- [SecretFinder](https://github.com/m4ll0k/SecretFinder)
- [subjs](https://github.com/lc/subjs)

### Git hunting

- [GitDorker](https://github.com/obheda12/GitDorker) *
- [gitGraber](https://github.com/hisxo/gitGraber) *
- [GitHacker](https://github.com/WangYihang/GitHacker) *
- [GitTools](https://github.com/internetwache/GitTools) *

### Sensitive stuff finding

- [DumpsterDiver](https://github.com/securing/DumpsterDiver) *
- [EarlyBird](https://github.com/americanexpress/earlybird) *
- [Ripgrep](https://github.com/BurntSushi/ripgrep)

### Useful tools

- [anew](https://github.com/tomnomnom/anew)
- [anti-burl](https://github.com/tomnomnom/hacks/tree/master/anti-burl)
- [getallurls](https://github.com/lc/hacks/tree/master/getallurls)
- [gron](https://github.com/tomnomnom/gron)
- [Interlace](https://github.com/codingo/Interlace)
- [jq](https://github.com/stedolan/jq) *
- [qsreplace](https://github.com/tomnomnom/qsreplace)
- [Tmux](https://github.com/tmux/tmux)
- [unfurl](https://github.com/tomnomnom/unfurl)
- [Uro](https://github.com/s0md3v/uro) *

### Note

- Refer to the usage of the tools as most of them require configuration (especially for subdomains enumeration).
- Please be careful with these tools and only use them on targets you have explicitly authorized.

**N.B** : * = added in the last update

** For Nikto and Debian 10, you need to have the non-free contrib sources in addition. e.g : 
```
deb http://deb.debian.org/debian/ buster main contrib non-free
deb-src http://deb.debian.org/debian/ buster main contrib non-free
```
