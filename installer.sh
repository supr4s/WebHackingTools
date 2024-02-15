#!/bin/bash -i
#Check if the script is executed with root privileges
if [ "$EUID" -ne 0 ]
  then echo -e ${RED}"Please execute this script with root privileges !"
  exit
fi

#Creating tools directory if not exist
source ./.env && mkdir -p $TOOLS_DIRECTORY;
clear;
cat ./banner/banner.txt;
echo "";

ENVIRONMENT () {
	echo -e ${BLUE}"[ENVIRONMENT]" ${RED}"Packages required installation in progress ...";
	#Check Operating System
	OS=$(lsb_release -i 2> /dev/null | sed 's/:\t/:/' | cut -d ':' -f 2-)
	if [ "$OS" == "Debian" ] || [ "$OS" == "Linuxmint" ]; then
		#Specific Debian
		#chromium
		apt-get update -y > /dev/null 2>&1;
		apt-get install chromium python2 python2.7 python3 python3-pip unzip make gcc libpcap-dev curl build-essential libcurl4-openssl-dev libxml2 libxml2-dev libxslt1-dev ruby-dev ruby libgmp-dev zlib1g-dev -y > /dev/null 2>&1;
		cd /tmp && curl https://bootstrap.pypa.io/pip/2.7/get-pip.py --output get-pip.py > /dev/null 2>&1 && python2 get-pip.py > /dev/null 2>&1;
		#Needed for NoSQLMap
		pip install couchdb pbkdf2 pymongo ipcalc six > /dev/null 2>&1;
	elif [ "$OS" == "Ubuntu" ]; then
		#Specific Ubuntu
		#Specificity : chromium-browser replace chromium
        	apt-get update -y > /dev/null 2>&1
        	apt-get install chromium-browser python2 python2.7 python3 python3-pip unzip make gcc libpcap-dev curl build-essential libcurl4-openssl-dev libxml2 libxml2-dev libxslt1-dev ruby-dev ruby libgmp-dev zlib1g-dev -y > /dev/null 2>&1;
        	cd /tmp && curl https://bootstrap.pypa.io/pip/2.7/get-pip.py --output get-pip.py > /dev/null 2>&1 && python2 get-pip.py > /dev/null 2>&1;
        	#Needed for NoSQLMap
        	pip install couchdb pbkdf2 pymongo ipcalc six > /dev/null 2>&1; 
	elif [ "$OS" == "Kali" ]; then
		#Specific Kali Linux
		#Specificity : no package name with "python"
        	apt-get update -y > /dev/null 2>&1;
        	apt-get install chromium python3 python3-pip unzip make gcc libpcap-dev curl build-essential libcurl4-openssl-dev libxml2 libxml2-dev libxslt1-dev ruby-dev ruby libgmp-dev zlib1g-dev -y > /dev/null 2>&1;
        	cd /tmp && curl https://bootstrap.pypa.io/pip/2.7/get-pip.py --output get-pip.py > /dev/null 2>&1 && python2 get-pip.py > /dev/null 2>&1;
        	pip install -U setuptools > /dev/null 2>&1;
        	#Needed for NoSQLMap
        	pip install couchdb pbkdf2 pymongo ipcalc > /dev/null 2>&1;    
	else
        	echo "OS unrecognized. Please check the compatibility with your system.";
        	echo "End of the script";
        exit;
	fi

unset OS
	#Bash colors
	sed -i '/^#.*force_color_prompt/s/^#//' ~/.bashrc && source ~/.bashrc
	echo -e ${BLUE}"[ENVIRONMENT]" ${GREEN}"Packages required installation is done !"; echo "";
	#Generic fot both OS - Golang environment
	echo -e ${BLUE}"[ENVIRONMENT]" ${RED}"Golang environment installation in progress ...";
    cd /tmp && curl -O https://dl.google.com/go/go"$GOVER".linux-amd64.tar.gz > /dev/null 2>&1 && tar -C /usr/local -xzf go"$GOVER".linux-amd64.tar.gz > /dev/null 2>&1 && echo "export PATH=$PATH:/usr/local/go/bin" >> ~/.bashrc;
    source ~/.bashrc;
	echo -e ${BLUE}"[ENVIRONMENT]" ${GREEN}"Golang environment installation is done !"; echo "";
}

SUBDOMAINS_ENUMERATION () {
	#Subfinder
	echo -e ${BLUE}"[SUBDOMAINS ENUMERATION]" ${RED}"Subfinder installation in progress ...";
	go install github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest > /dev/null 2>&1 && ln -s ~/go/bin/subfinder /usr/local/bin/;
	echo -e ${BLUE}"[SUBDOMAINS ENUMERATION]" ${GREEN}"Subfinder installation is done !"; echo "";
	#Assetfinder
	echo -e ${BLUE}"[SUBDOMAINS ENUMERATION]" ${RED}"Assetfinder installation in progress ...";
	go install github.com/tomnomnom/assetfinder@latest > /dev/null 2>&1 && ln -s ~/go/bin/assetfinder /usr/local/bin/;
	echo -e ${BLUE}"[SUBDOMAINS ENUMERATION]" ${GREEN}"Assetfinder installation is done !"; echo "";
	#Findomain
	echo -e ${BLUE}"[SUBDOMAINS ENUMERATION]" ${RED}"Findomain installation in progress ...";
	cd /tmp && wget https://github.com/Edu4rdSHL/findomain/releases/latest/download/findomain-linux.zip > /dev/null 2>&1 && unzip findomain-linux.zip > /dev/null 2>&1 && chmod +x findomain && mv ./findomain /usr/local/bin/findomain;
	echo -e ${BLUE}"[SUBDOMAINS ENUMERATION]" ${GREEN}"Findomain installation is done !"; echo "";
	#Github-subdomains
	echo -e ${BLUE}"[SUBDOMAINS ENUMERATION]" ${RED}"Github-subdomains installation in progress ...";
	go install github.com/gwen001/github-subdomains@latest > /dev/null 2>&1 && ln -s ~/go/bin/github-subdomains /usr/local/bin/;
	echo -e ${BLUE}"[SUBDOMAINS ENUMERATION]" ${GREEN}"Github-subdomains installation is done !"; echo "";
	#Gitlab-subdomains
	echo -e ${BLUE}"[SUBDOMAINS ENUMERATION]" ${RED}"Gitlab-subdomains installation in progress ...";
	go install github.com/gwen001/gitlab-subdomains@latest > /dev/null 2>&1 && ln -s ~/go/bin/gitlab-subdomains /usr/local/bin/;
	echo -e ${BLUE}"[SUBDOMAINS ENUMERATION]" ${GREEN}"Gitlab-subdomains installation is done !"; echo "";
	#Amass
	echo -e ${BLUE}"[SUBDOMAINS ENUMERATION]" ${RED}"Amass installation in progress ...";
	cd /tmp && wget https://github.com/owasp-amass/amass/releases/download/v4.2.0/amass_Linux_amd64.zip > /dev/null 2>&1 && unzip amass_Linux_amd64.zip > /dev/null 2>&1 && mv amass_Linux_amd64/amass /usr/local/bin/;
	echo -e ${BLUE}"[SUBDOMAINS ENUMERATION]" ${GREEN}"Amass installation is done !"; echo "";
	#Crobat
	echo -e ${BLUE}"[SUBDOMAINS ENUMERATION]" ${RED}"Crobat installation in progress ...";
	go install github.com/cgboal/sonarsearch/cmd/crobat@latest > /dev/null 2>&1 && ln -s ~/go/bin/crobat /usr/local/bin/;
	echo -e ${BLUE}"[SUBDOMAINS ENUMERATION]" ${GREEN}"Crobat installation is done !"; echo "";
}

DNS_RESOLVER () {
	#MassDNS
	echo -e ${BLUE}"[DNS RESOLVER]" ${RED}"MassDNS installation in progress ...";
	cd $TOOLS_DIRECTORY && git clone https://github.com/blechschmidt/massdns.git > /dev/null 2>&1 && cd massdns && make > /dev/null 2>&1 && ln -s $TOOLS_DIRECTORY/massdns/bin/massdns /usr/local/bin/;
	echo -e ${BLUE}"[DNS RESOLVER]" ${GREEN}"MassDNS installation is done !"; echo "";
	#dnsx
	echo -e ${BLUE}"[DNS RESOLVER]" ${RED}"dnsx installation in progress ...";
	go install github.com/projectdiscovery/dnsx/cmd/dnsx@latest > /dev/null 2>&1 && ln -s ~/go/bin/dnsx /usr/local/bin/;
	echo -e ${BLUE}"[DNS RESOLVER]" ${GREEN}"dnsx installation is done !"; echo "";
	#PureDNS
	echo -e ${BLUE}"[DNS RESOLVER]" ${RED}"PureDNS installation in progress ...";
	go install github.com/d3mondev/puredns/v2@latest > /dev/null 2>&1 && ln -s ~/go/bin/puredns /usr/local/bin;
	echo -e ${BLUE}"[DNS RESOLVER]" ${GREEN}"PureDNS installation is done !"; echo "";
}

HTTP_PROBE () {
	#httpx
	echo -e ${BLUE}"[HTTP PROBE]" ${RED}"httpx installation in progress ...";
	go install github.com/projectdiscovery/httpx/cmd/httpx@latest > /dev/null 2>&1 && ln -s ~/go/bin/httpx /usr/local/bin/;
	echo -e ${BLUE}"[HTTP PROBE]" ${GREEN}"Httpx installation is done !"; echo "";
	#httprobe
	echo -e ${BLUE}"[HTTP PROBE]" ${RED}"httprobe installation in progress ...";
	go install github.com/tomnomnom/httprobe@latest > /dev/null 2>&1 && ln -s ~/go/bin/httprobe /usr/local/bin/;
	echo -e ${BLUE}"[HTTP PROBE]" ${GREEN}"httprobe installation is done !"; echo "";
}

VISUAL_RECON () {
	#Aquatone
	echo -e ${BLUE}"[VISUAL RECON]" ${RED}"Aquatone installation in progress ...";
	cd /tmp && wget https://github.com/michenriksen/aquatone/releases/download/v$AQUATONEVER/aquatone_linux_amd64_$AQUATONEVER.zip > /dev/null 2>&1 && unzip aquatone_linux_amd64_$AQUATONEVER.zip > /dev/null 2>&1 && mv aquatone /usr/local/bin/;
	echo -e ${BLUE}"[VISUAL RECON]" ${GREEN}"Aquatone installation is done !"; echo "";
	#Gowitness
	echo -e ${BLUE}"[VISUAL RECON]" ${RED}"Gowitness installation in progress ...";
	cd /tmp && wget https://github.com/sensepost/gowitness/releases/download/$GOWITNESSVER/gowitness-$GOWITNESSVER-linux-amd64 > /dev/null 2>&1 && mv gowitness-$GOWITNESSVER-linux-amd64 /usr/local/bin/gowitness && chmod +x /usr/local/bin/gowitness;
	echo -e ${BLUE}"[VISUAL RECON]" ${GREEN}"Gowitness installation is done !"; echo "";
}

NETWORK_SCANNER () {
	#Nmap
	echo -e ${BLUE}"[NETWORK SCANNER]" ${RED}"Nmap installation in progress ...";
	apt-get install nmap -y > /dev/null 2>&1;
	echo -e ${BLUE}"[NETWORK SCANNER]" ${GREEN}"Nmap installation is done !"; echo "";
	#masscan
	echo -e ${BLUE}"[NETWORK SCANNER]" ${RED}"Masscan installation in progress ...";
	cd $TOOLS_DIRECTORY && git clone https://github.com/robertdavidgraham/masscan > /dev/null 2>&1 && cd masscan && make > /dev/null 2>&1 && make install > /dev/null 2>&1 && mv bin/masscan /usr/local/bin/;
	echo -e ${BLUE}"[NETWORK SCANNER]" ${GREEN}"Masscan installation is done !"; echo "";
	#naabu
	echo -e ${BLUE}"[NETWORK SCANNER]" ${RED}"Naabu installation in progress ...";
	go install -v github.com/projectdiscovery/naabu/v2/cmd/naabu@latest > /dev/null 2>&1 && ln -s ~/go/bin/naabu /usr/local/bin/;
	echo -e ${BLUE}"[NETWORK SCANNER]" ${GREEN}"Naabu installation is done !"; echo "";
	#Smap
	echo -e ${BLUE}"[NETWORK SCANNER]" ${RED}"Smap installation in progress ...";
	go install -v github.com/s0md3v/smap/cmd/smap@latest > /dev/null 2>&1 && ln -s ~/go/bin/smap /usr/local/bin/;
	echo -e ${BLUE}"[NETWORK SCANNER]" ${GREEN}"Smap installation is done !"; echo "";
}

WEB_CRAWLING () {
	#Gospider
	echo -e ${BLUE}"[WEB CRAWLING]" ${RED}"Gospider installation in progress ...";
	go install github.com/jaeles-project/gospider@latest > /dev/null 2>&1 && ln -s ~/go/bin/gospider /usr/local/bin/;
	echo -e ${BLUE}"[WEB CRAWLING]" ${GREEN}"Gospider installation is done !"; echo "";
	#Hakrawler
	echo -e ${BLUE}"[WEB CRAWLING]" ${RED}"Hakrawler installation in progress ...";
	go install github.com/hakluke/hakrawler@latest > /dev/null 2>&1 && ln -s ~/go/bin/hakrawler /usr/local/bin/;
	echo -e ${BLUE}"[WEB CRAWLING]" ${GREEN}"Hakrawler installation is done !"; echo "";
	#Katana
	echo -e ${BLUE}"[WEB CRAWLING]" ${RED}"Katana installation in progress ...";
	go install github.com/projectdiscovery/katana/cmd/katana@latest > /dev/null 2>&1 && ln -s ~/go/bin/katana /usr/local/bin/;
	echo -e ${BLUE}"[WEB CRAWLING]" ${GREEN}"Katana installation is done !"; echo "";
}

HTTP_PARAMETER () {
	#Arjun
	echo -e ${BLUE}"[HTTP PARAMETER DISCOVERY]" ${RED}"Arjun installation in progress ...";
	pip3 install arjun > /dev/null 2>&1;
	echo -e ${BLUE}"[HTTP PARAMETER DISCOVERY]" ${GREEN}"Arjun installation is done !"; echo "";
	#x8
	echo -e ${BLUE}"[HTTP PARAMETER DISCOVERY]" ${RED}"x8 installation in progress ...";
	cd /tmp && wget https://github.com/Sh1Yo/x8/releases/download/v"$X8VER"/x86_64-linux-x8.gz > /dev/null 2>&1 && gzip -d x86_64-linux-x8.gz > /dev/null 2>&1 && chmod +x x86_64-linux-x8 && mv x86_64-linux-x8 /usr/local/bin/x8;
	echo -e ${BLUE}"[HTTP PARAMETER DISCOVERY]" ${GREEN}"x8 installation is done !"; echo "";
}

JS_HUNTING () {
	#Linkfinder
	echo -e ${BLUE}"[JS FILES HUNTING]" ${RED}"Linkfinder installation in progress ...";
	cd $TOOLS_DIRECTORY && git clone https://github.com/GerbenJavado/LinkFinder.git > /dev/null 2>&1 && cd LinkFinder && pip3 install -r requirements.txt > /dev/null 2>&1 && python3 setup.py install > /dev/null 2>&1;
	echo -e ${BLUE}"[JS FILES HUNTING]" ${GREEN}"Linkfinder installation is done !"; echo "";
	#SecretFinder
	echo -e ${BLUE}"[JS FILES HUNTING]" ${RED}"SecretFinder installation in progress ...";
	cd $TOOLS_DIRECTORY && git clone https://github.com/m4ll0k/SecretFinder.git > /dev/null 2>&1 && cd SecretFinder && pip3 install -r requirements.txt > /dev/null 2>&1;
	echo -e ${BLUE}"[JS FILES HUNTING]" ${GREEN}"SecretFinder installation is done !"; echo "";
	#subjs
	echo -e ${BLUE}"[JS FILES HUNTING]" ${RED}"subjs installation in progress ...";
	go install github.com/lc/subjs@latest > /dev/null 2>&1 && ln -s ~/go/bin/subjs /usr/local/bin/;
	echo -e ${BLUE}"[JS FILES HUNTING]" ${GREEN}"subjs installation is done !"; echo "";
	#xnLinkFinder
	echo -e ${BLUE}"[JS FILES HUNTING]" ${RED}"xnLinkFinder installation in progress ...";
	cd $TOOLS_DIRECTORY && git clone https://github.com/xnl-h4ck3r/xnLinkFinder.git > /dev/null 2>&1 && cd xnLinkFinder && python3 setup.py install > /dev/null 2>&1;
	echo -e ${BLUE}"[JS FILES HUNTING]" ${GREEN}"xnLinkFinder installation is done !"; echo "";
}

BYPASS_40X () {
	#dontgo403
	echo -e ${BLUE}"[BYPASS 40X]" ${RED}"dontgo403 installation in progress ...";
	cd /tmp && wget https://github.com/devploit/dontgo403/releases/download/0.5/dontgo403_linux_amd64 > /dev/null 2>&1 && chmod +x dontgo403_linux_amd64 && mv dontgo403_linux_amd64 /usr/local/bin/dontgo403;
	echo -e ${BLUE}"[BYPASS 40X]" ${GREEN}"dontgo403 installation is done !"; echo "";
}

CORS_TOOLS () {
	#Corsy
	echo -e ${BLUE}"[CORS MISCONFIGURATION]" ${RED}"Corsy installation in progress ...";
	cd $TOOLS_DIRECTORY && git clone https://github.com/s0md3v/Corsy > /dev/null 2>&1; cd Corsy && pip3 install requests > /dev/null 2>&1;
	echo -e ${BLUE}"[CORS MISCONFIGURATION]" ${GREEN}"Corsy installation is done !"; echo "";
	#CORScanner
	echo -e ${BLUE}"[CORS MISCONFIGURATION]" ${RED}"CORScanner installation in progress ...";
	pip install corscanner > /dev/null 2>&1;
	echo -e ${BLUE}"[CORS MISCONFIGURATION]" ${GREEN}"CORScanner installation is done !"; echo "";
}

FUZZING_TOOLS () {
	#ffuf
	echo -e ${BLUE}"[FUZZING TOOLS]" ${RED}"ffuf installation in progress ...";
	go install github.com/ffuf/ffuf@latest > /dev/null 2>&1 && ln -s ~/go/bin/ffuf /usr/local/bin/;
	echo -e ${BLUE}"[FUZZING TOOLS]" ${GREEN}"ffuf installation is done !"; echo "";
	#gobuster
	echo -e ${BLUE}"[FUZZING TOOLS]" ${RED}"Gobuster installation in progress ...";
	go install github.com/OJ/gobuster/v3@latest > /dev/null 2>&1 && ln -s ~/go/bin/gobuster /usr/local/bin/;
	echo -e ${BLUE}"[FUZZING TOOLS]" ${GREEN}"Gobuster installation is done !"; echo "";
	#wfuzz
	echo -e ${BLUE}"[FUZZING TOOLS]" ${RED}"wfuzz installation in progress ...";
	apt-get install wfuzz -y > /dev/null 2>&1;
	echo -e ${BLUE}"[FUZZING TOOLS]" ${GREEN}"wfuzz installation is done !"; echo "";
	#fuzzuli
	echo -e ${BLUE}"[FUZZING TOOLS]" ${RED}"fuzzuli installation in progress ...";
	go install github.com/musana/fuzzuli@latest > /dev/null 2>&1 && ln -s ~/go/bin/fuzzuli /usr/local/bin/;
	echo -e ${BLUE}"[FUZZING TOOLS]" ${GREEN}"fuzzuli installation is done !"; echo "";
}

PROTO_POLLUTION () {
	#ppfuzz
	echo -e ${BLUE}"[PROTOTYPE POLLUTION]" ${RED}"ppfuzz installation in progress ...";
	cd /tmp && wget https://github.com/dwisiswant0/ppfuzz/releases/download/v"$PPFUZZVER"/ppfuzz-v"$PPFUZZVER"-x86_64-unknown-linux-musl.tar.gz > /dev/null 2>&1 && tar -zxvf ppfuzz-v"$PPFUZZVER"-x86_64-unknown-linux-musl.tar.gz > /dev/null 2>&1 && mv ppfuzz /usr/local/bin/ppfuzz;
	echo -e ${BLUE}"[PROTOTYPE POLLUTION]" ${GREEN}"ppfuzz installation is done !"; echo "";
	#ppmap
	echo -e ${BLUE}"[PROTOTYPE POLLUTION]" ${RED}"ppmap installation in progress ...";
	cd $TOOLS_DIRECTORY && git clone https://github.com/kleiton0x00/ppmap.git > /dev/null 2>&1 && cd ppmap && bash setup.sh > /dev/null 2>&1;
	echo -e ${BLUE}"[PROTOTYPE POLLUTION]" ${GREEN}"ppmap installation is done !"; echo "";
}

LFI_TOOLS () {
	#LFISuite
	echo -e ${BLUE}"[LFI TOOLS]" ${RED}"LFISuite installation in progress ...";
	cd $TOOLS_DIRECTORY && git clone https://github.com/D35m0nd142/LFISuite.git > /dev/null 2>&1;
	echo -e ${BLUE}"[LFI TOOLS]" ${GREEN}"LFISuite installation is done !"; echo "";
}

SSRF_TOOLS () {
	#SSRFmap
	echo -e ${BLUE}"[SSRF TOOLS]" ${RED}"SSRFmap installation in progress ...";
	cd $TOOLS_DIRECTORY && git clone https://github.com/swisskyrepo/SSRFmap > /dev/null 2>&1 && cd SSRFmap && pip3 install -r requirements.txt > /dev/null 2>&1;
	echo -e ${BLUE}"[SSRF TOOLS]" ${GREEN}"SSRFmap installation is done !"; echo "";
	#Gopherus
	echo -e ${BLUE}"[SSRF TOOLS]" ${RED}"Gopherus installation in progress ...";
	cd $TOOLS_DIRECTORY && git clone https://github.com/tarunkant/Gopherus.git > /dev/null 2>&1 && cd Gopherus && chmod +x install.sh && ./install.sh > /dev/null 2>&1;
	echo -e ${BLUE}"[SSRF TOOLS]" ${GREEN}"Gopherus installation is done !"; echo "";
	#Interactsh
	echo -e ${BLUE}"[SSRF TOOLS]" ${RED}"Interactsh installation in progress ...";
	go install -v github.com/projectdiscovery/interactsh/cmd/interactsh-client@latest > /dev/null 2>&1 && ln -s ~/go/bin/interactsh-client /usr/local/bin/;
	echo -e ${BLUE}"[SSRF TOOLS]" ${GREEN}"Interactsh installation is done !"; echo "";
	#AutoSSRF
	echo -e ${BLUE}"[SSRF TOOLS]" ${RED}"AutoSSRF installation in progress ...";
	cd $TOOLS_DIRECTORY && git clone https://github.com/Th0h0/autossrf.git > /dev/null 2>&1 && cd autossrf && pip3 install -r requirements.txt > /dev/null 2>&1;
	echo -e ${BLUE}"[SSRF TOOLS]" ${GREEN}"AutoSSRF installation is done !"; echo "";
}

SSTI_TOOLS () {
	#tplmap
	echo -e ${BLUE}"[SSTI TOOLS]" ${RED}"tplmap installation in progress ...";
	cd $TOOLS_DIRECTORY && git clone https://github.com/epinna/tplmap.git > /dev/null 2>&1 && cd tplmap && pip install -r requirements.txt > /dev/null 2>&1;
	echo -e ${BLUE}"[SSTI TOOLS]" ${GREEN}"tplmap installation is done !"; echo "";
}

API_TOOLS () {
	#Kiterunner
	echo -e ${BLUE}"[API TOOLS]" ${RED}"Kiterunner installation in progress ...";
	cd /tmp && wget https://github.com/assetnote/kiterunner/releases/download/v"$KITERUNNERVER"/kiterunner_"$KITERUNNERVER"_linux_amd64.tar.gz > /dev/null 2>&1 && tar xvf kiterunner_"$KITERUNNERVER"_linux_amd64.tar.gz > /dev/null 2>&1 && mv kr /usr/local/bin;
	cd $TOOLS_DIRECTORY && mkdir -p kiterunner-wordlists && cd kiterunner-wordlists && wget https://wordlists-cdn.assetnote.io/data/kiterunner/routes-large.kite.tar.gz > /dev/null 2>&1 && wget https://wordlists-cdn.assetnote.io/data/kiterunner/routes-small.kite.tar.gz > /dev/null 2>&1 && for f in *.tar.gz; do tar xf "$f"; rm -Rf "$f"; done
	echo -e ${BLUE}"[API TOOLS]" ${GREEN}"Kiterunner installation is done !"; echo "";
}

XSS_TOOLS () {
	#Dalfox
	echo -e ${BLUE}"[XSS]" ${RED}"Dalfox installation in progress ...";
	go install github.com/hahwul/dalfox/v2@latest > /dev/null 2>&1 && ln -s ~/go/bin/dalfox /usr/local/bin/;
	echo -e ${BLUE}"[XSS]" ${GREEN}"Dalfox installation is done !"; echo "";
	#XSStrike
	echo -e ${BLUE}"[XSS]" ${RED}"XSStrike installation in progress ...";
	cd $TOOLS_DIRECTORY && git clone https://github.com/s0md3v/XSStrike > /dev/null 2>&1 && cd XSStrike && pip3 install -r requirements.txt > /dev/null 2>&1;
	echo -e ${BLUE}"[XSS]" ${GREEN}"XSStrike installation is done !"; echo "";
	#kxss
	echo -e ${BLUE}"[XSS]" ${RED}"kxss installation in progress ...";
	go install github.com/tomnomnom/hacks/kxss@latest > /dev/null 2>&1 && ln -s ~/go/bin/kxss /usr/local/bin/;
	echo -e ${BLUE}"[XSS]" ${GREEN}"kxss installation is done !"; echo "";
}

SQLI_TOOLS () {
	#SQLmap
	echo -e ${BLUE}"[SQL Injection]" ${RED}"SQLMap installation in progress ...";
	apt-get install -y sqlmap > /dev/null 2>&1
	echo -e ${BLUE}"[SQL Injection]" ${GREEN}"SQLMap installation is done !"; echo "";
	#NoSQLMap
	echo -e ${BLUE}"[SQL Injection]" ${RED}"NoSQLMap installation in progress ...";
	cd $TOOLS_DIRECTORY && git clone https://github.com/codingo/NoSQLMap.git > /dev/null 2>&1 && cd NoSQLMap && python setup.py install > /dev/null 2>&1;
	echo -e ${BLUE}"[SQL Injection]" ${GREEN}"NoSQLMap installation is done !"; echo "";
}

VULNS_SCANNER () {
	#Nuclei + nuclei templates
	echo -e ${BLUE}"[VULNERABILITY SCANNER]" ${RED}"Nuclei installation in progress ...";
	go install -v github.com/projectdiscovery/nuclei/v2/cmd/nuclei@latest > /dev/null 2>&1 && ln -s ~/go/bin/nuclei /usr/local/bin/;
	nuclei -update-templates > /dev/null 2>&1;
	echo -e ${BLUE}"[VULNERABILITY SCANNER]" ${GREEN}"Nuclei installation is done !"; echo "";
	#Jaeles
	echo -e ${BLUE}"[VULNERABILITY SCANNER]" ${RED}"Jaeles installation in progress ...";
	GO111MODULE=on go install github.com/jaeles-project/jaeles@latest  > /dev/null 2>&1 && ln -s ~/go/bin/jaeles /usr/local/bin/;
	cd $TOOLS_DIRECTORY && git clone https://github.com/jaeles-project/jaeles-signatures.git > /dev/null 2>&1;
	echo -e ${BLUE}"[VULNERABILITY SCANNER]" ${GREEN}"Jaeles installation is done !"; echo "";
	#Nikto
	echo -e ${BLUE}"[VULNERABILITY SCANNER]" ${RED}"Nikto installation in progress ...";
	apt-get install -y nikto > /dev/null 2>&1;
	echo -e ${BLUE}"[VULNERABILITY SCANNER]" ${GREEN}"Nikto installation is done !"; echo "";
}

CMS_SCANNER () {
	#WPScan
	echo -e ${BLUE}"[CMS SCANNER]" ${RED}"WPScan installation in progress ...";
	gem install wpscan > /dev/null 2>&1;
	echo -e ${BLUE}"[CMS SCANNER]" ${GREEN}"WPScan installation is done !"; echo "";
	#Droopescan
	echo -e ${BLUE}"[CMS SCANNER]" ${RED}"Droopescan installation in progress ...";
	pip3 install droopescan > /dev/null 2>&1;
	echo -e ${BLUE}"[CMS SCANNER]" ${GREEN}"Droopescan installation is done !"; echo "";
	#AEM-Hacking
	echo -e ${BLUE}"[CMS SCANNER]" ${RED}"AEM-Hacking installation in progress ...";
	cd $TOOLS_DIRECTORY && git clone https://github.com/0ang3el/aem-hacker.git > /dev/null 2>&1 && cd aem-hacker && pip3 install -r requirements.txt > /dev/null 2>&1;
	echo -e ${BLUE}"[CMS SCANNER]" ${GREEN}"AEM-Hacking installation is done !"; echo "";
}

WORDLISTS () {
	echo -e ${BLUE}"[WORDLISTS]" ${RED}"SecLists installation in progress ...";
	cd $TOOLS_DIRECTORY && git clone https://github.com/danielmiessler/SecLists.git > /dev/null 2>&1;
	echo -e ${BLUE}"[WORDLISTS]" ${GREEN}"SecLists installation is done !"; echo "";
	echo -e ${BLUE}"[WORDLISTS]" ${RED}"OneListForAll installation in progress ...";
	cd $TOOLS_DIRECTORY && git clone https://github.com/six2dez/OneListForAll > /dev/null 2>&1;
	echo -e ${BLUE}"[WORDLISTS]" ${GREEN}"OneListForAll installation is done !"; echo "";
}

GIT_HUNTING() {
	#GitDorker
	echo -e ${BLUE}"[GIT HUNTING]" ${RED}"GitDorker installation in progress ...";
	cd $TOOLS_DIRECTORY && git clone https://github.com/obheda12/GitDorker.git > /dev/null 2>&1 && cd GitDorker && pip3 install -r requirements.txt > /dev/null 2>&1;
	echo -e ${BLUE}"[GIT HUNTING]" ${GREEN}"GitDorker installation is done !"; echo "";
	#gitGraber
	echo -e ${BLUE}"[GIT HUNTING]" ${RED}"gitGraber installation in progress ...";
	cd $TOOLS_DIRECTORY && git clone https://github.com/hisxo/gitGraber.git > /dev/null 2>&1 && cd gitGraber && pip3 install -r requirements.txt > /dev/null 2>&1;
	echo -e ${BLUE}"[GIT HUNTING]" ${GREEN}"gitGraber installation is done !"; echo "";
	#GitHacker
	echo -e ${BLUE}"[GIT HUNTING]" ${RED}"GitHacker installation in progress ...";
	pip3 install GitHacker > /dev/null 2>&1;
	echo -e ${BLUE}"[GIT HUNTING]" ${GREEN}"GitHacker installation is done !"; echo "";
	#GitTools
	echo -e ${BLUE}"[GIT HUNTING]" ${RED}"GitTools installation in progress ...";
	cd $TOOLS_DIRECTORY && git clone https://github.com/internetwache/GitTools.git > /dev/null 2>&1;
	echo -e ${BLUE}"[GIT HUNTING]" ${GREEN}"GitTools installation is done !"; echo "";
}

SENSITIVE_FINDING() {
	#DumpsterDiver
	echo -e ${BLUE}"[SENSITIVE FINDING TOOLS]" ${RED}"gitGraber installation in progress ...";
	cd $TOOLS_DIRECTORY && git clone https://github.com/securing/DumpsterDiver.git > /dev/null 2>&1 && cd DumpsterDiver && pip3 install -r requirements.txt > /dev/null 2>&1;
	echo -e ${BLUE}"[SENSITIVE FINDING TOOLS]" ${GREEN}"gitGraber installation is done !"; echo "";
	#EarlyBird
	echo -e ${BLUE}"[SENSITIVE FINDING TOOLS]" ${RED}"EarlyBird installation in progress ...";
	cd $TOOLS_DIRECTORY && git clone https://github.com/americanexpress/earlybird.git > /dev/null 2>&1 && cd earlybird && ./build.sh > /dev/null 2>&1 && ./install.sh > /dev/null 2>&1;
	echo -e ${BLUE}"[SENSITIVE FINDING TOOLS]" ${GREEN}"EarlyBird installation is done !"; echo "";
	#Ripgrep
	echo -e ${BLUE}"[SENSITIVE FINDING TOOLS]" ${RED}"Ripgrep installation in progress ...";
	apt-get install -y ripgrep > /dev/null 2>&1
	echo -e ${BLUE}"[SENSITIVE FINDING TOOLS]" ${GREEN}"Ripgrep installation is done !" ${RESTORE}; echo "";
	#Trufflehog
	echo -e ${BLUE}"[SENSITIVE FINDING TOOLS]" ${RED}"Trufflehog installation in progress ...";
	cd /tmp && wget https://github.com/trufflesecurity/trufflehog/releases/download/v"$TRUFFLEHOGVER"/trufflehog_"$TRUFFLEHOGVER"_linux_amd64.tar.gz > /dev/null 2>&1 && tar -zxvf trufflehog_"$TRUFFLEHOGVER"_linux_amd64.tar.gz > /dev/null 2>&1 && mv trufflehog /usr/local/bin/trufflehog;
	echo -e ${BLUE}"[SENSITIVE FINDING TOOLS]" ${GREEN}"Trufflehog installation is done !" ${RESTORE}; echo "";
}

USEFUL_TOOLS () {
	#getallurls
	echo -e ${BLUE}"[USEFUL TOOLS]" ${RED}"getallurls installation in progress ...";
	go install github.com/lc/gau/v2/cmd/gau@latest > /dev/null 2>&1 && ln -s ~/go/bin/gau /usr/local/bin/;
	echo -e ${BLUE}"[USEFUL TOOLS]" ${GREEN}"getallurls installation is done !"; echo "";
	#anti-burl
	echo -e ${BLUE}"[USEFUL TOOLS]" ${RED}"anti-burl installation in progress ...";
	go install github.com/tomnomnom/hacks/anti-burl@latest > /dev/null 2>&1 && ln -s ~/go/bin/anti-burl /usr/local/bin/;
	echo -e ${BLUE}"[USEFUL TOOLS]" ${GREEN}"anti-burl installation is done !"; echo "";
	#unfurl
	echo -e ${BLUE}"[USEFUL TOOLS]" ${RED}"unfurl installation in progress ...";
	go install github.com/tomnomnom/unfurl@latest > /dev/null 2>&1 && ln -s ~/go/bin/unfurl /usr/local/bin/;
	echo -e ${BLUE}"[USEFUL TOOLS]" ${GREEN}"unfurl installation is done !"; echo "";
	#anew
	echo -e ${BLUE}"[USEFUL TOOLS]" ${RED}"anew installation in progress ...";
	go install github.com/tomnomnom/anew@latest > /dev/null 2>&1 && ln -s ~/go/bin/anew /usr/local/bin/;
	echo -e ${BLUE}"[USEFUL TOOLS]" ${GREEN}"anew installation is done !"; echo "";
	#gron
	echo -e ${BLUE}"[USEFUL TOOLS]" ${RED}"gron installation in progress ...";
	go install github.com/tomnomnom/gron@latest > /dev/null 2>&1 && ln -s ~/go/bin/gron /usr/local/bin/;
	echo -e ${BLUE}"[USEFUL TOOLS]" ${GREEN}"gron installation is done !"; echo "";
	#qsreplace
	echo -e ${BLUE}"[USEFUL TOOLS]" ${RED}"qsreplace installation in progress ...";
	go install github.com/tomnomnom/qsreplace@latest > /dev/null 2>&1 && ln -s ~/go/bin/qsreplace /usr/local/bin/;
	echo -e ${BLUE}"[USEFUL TOOLS]" ${GREEN}"qsreplace installation is done !"; echo "";
	#Interlace
	echo -e ${BLUE}"[USEFUL TOOLS]" ${RED}"Interlace installation in progress ...";
	cd $TOOLS_DIRECTORY && git clone https://github.com/codingo/Interlace.git > /dev/null 2>&1 && cd Interlace && python3 setup.py install > /dev/null 2>&1;
	echo -e ${BLUE}"[USEFUL TOOLS]" ${GREEN}"Interlace installation is done !"; echo "";
	#Jq
	echo -e ${BLUE}"[USEFUL TOOLS]" ${RED}"jq installation in progress ...";
	apt-get install -y jq > /dev/null 2>&1;
	echo -e ${BLUE}"[USEFUL TOOLS]" ${GREEN}"jq installation is done !"; echo "";
	#Tmux
	echo -e ${BLUE}"[USEFUL TOOLS]" ${RED}"Tmux installation in progress ...";
	apt-get install tmux -y > /dev/null 2>&1;
	echo -e ${BLUE}"[USEFUL TOOLS]" ${GREEN}"Tmux installation is done !"; echo "";
	#Uro
	echo -e ${BLUE}"[USEFUL TOOLS]" ${RED}"Uro installation in progress ...";
	pip3 install uro > /dev/null 2>&1;
	echo -e ${BLUE}"[USEFUL TOOLS]" ${GREEN}"Uro installation is done !" ${RESTORE}; echo "";
}

#ESSENTIALS
ENVIRONMENT;

#RECON - 1
SUBDOMAINS_ENUMERATION && DNS_RESOLVER && HTTP_PROBE && VISUAL_RECON && NETWORK_SCANNER;

#RECON - 2
WEB_CRAWLING && HTTP_PARAMETER && JS_HUNTING;

#VULNS
BYPASS_40X && CORS_TOOLS && FUZZING_TOOLS && PROTO_POLLUTION && LFI_TOOLS && SSRF_TOOLS && SSTI_TOOLS && API_TOOLS && XSS_TOOLS && SQLI_TOOLS;

#VULNS - GENERIC
VULNS_SCANNER && CMS_SCANNER

#WORDLISTS
WORDLISTS;

#SENSITIVE STUFF
GIT_HUNTING && SENSITIVE_FINDING;

#IN ADDITION
USEFUL_TOOLS;
