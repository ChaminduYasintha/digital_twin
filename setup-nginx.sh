#!/bin/bash

# Setup nginx as reverse proxy for domain access

set -e

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔧 Setting up Nginx Reverse Proxy"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check if running as root or with sudo
if [ "$EUID" -ne 0 ]; then 
    echo -e "${YELLOW}⚠ This script needs sudo privileges. Please run with sudo.${NC}"
    exit 1
fi

# Install nginx
echo -e "${BLUE}[1/4]${NC} Installing nginx..."
apt update -qq
apt install -y nginx > /dev/null 2>&1
echo -e "${GREEN}✓ Nginx installed${NC}"

# Get project directory (try current dir first, then home)
if [ -f "nginx.conf" ]; then
    PROJECT_DIR="$(pwd)"
elif [ -f "$HOME/digital_twin/nginx.conf" ]; then
    PROJECT_DIR="$HOME/digital_twin"
else
    echo -e "${RED}❌ nginx.conf not found!${NC}"
    echo "Please run this script from the project directory or ensure nginx.conf exists."
    exit 1
fi

# Copy nginx config
echo -e "\n${BLUE}[2/4]${NC} Configuring nginx..."
cp "$PROJECT_DIR/nginx.conf" /etc/nginx/sites-available/digital_twin

# Ask for domain name (optional)
echo -e "\n${YELLOW}Enter your domain name (or press Enter to use IP address):${NC}"
read domain_name

if [ -n "$domain_name" ]; then
    # Replace server_name in config
    sed -i "s/server_name _;/server_name $domain_name;/" /etc/nginx/sites-available/digital_twin
    echo -e "${GREEN}✓ Domain name set to: $domain_name${NC}"
else
    echo -e "${YELLOW}⚠ Using default server (IP address)${NC}"
fi

# Enable site
ln -sf /etc/nginx/sites-available/digital_twin /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default 2>/dev/null || true

# Test nginx config
echo -e "\n${BLUE}[3/4]${NC} Testing nginx configuration..."
if nginx -t > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Nginx configuration is valid${NC}"
else
    echo -e "${RED}❌ Nginx configuration error!${NC}"
    nginx -t
    exit 1
fi

# Start and enable nginx
echo -e "\n${BLUE}[4/4]${NC} Starting nginx..."
systemctl enable nginx > /dev/null 2>&1
systemctl restart nginx
echo -e "${GREEN}✓ Nginx started and enabled${NC}"

# Update firewall
echo -e "\n${BLUE}[5/5]${NC} Updating firewall rules..."
if command -v ufw > /dev/null 2>&1; then
    ufw allow 'Nginx Full' > /dev/null 2>&1 || true
    echo -e "${GREEN}✓ Firewall updated${NC}"
fi

echo -e "\n${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ Nginx Setup Complete!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}📋 IMPORTANT:${NC}"
echo ""
echo "1. Make sure your app is running:"
echo -e "   ${BLUE}cd ~/digital_twin && ./start-all.sh${NC}"
echo ""
if [ -n "$domain_name" ]; then
    echo "2. Point your domain DNS to this server's IP:"
    echo -e "   ${BLUE}curl ifconfig.me${NC}"
    echo ""
    echo "3. Access your app at:"
    echo -e "   ${GREEN}http://$domain_name${NC}"
else
    echo "2. Access your app at:"
    EXTERNAL_IP=$(curl -s ifconfig.me 2>/dev/null || echo "YOUR_IP")
    echo -e "   ${GREEN}http://$EXTERNAL_IP${NC}"
fi
echo ""
echo -e "${YELLOW}💡 TIPS:${NC}"
echo "  • View nginx logs: sudo tail -f /var/log/nginx/error.log"
echo "  • Restart nginx: sudo systemctl restart nginx"
echo "  • Update domain: Edit /etc/nginx/sites-available/digital_twin and restart nginx"
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

