#!/bin/bash

# 🚀 ONE-COMMAND DEPLOYMENT SCRIPT
# This script does EVERYTHING - just run it!

set -e

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚀 RAG App - One-Command Deployment"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check if running on GCP VM (has metadata server)
if curl -s -f -m 2 http://169.254.169.254/computeMetadata/v1/instance/id > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Detected GCP VM${NC}"
    IS_GCP=true
else
    echo -e "${YELLOW}⚠ Not a GCP VM, but continuing anyway...${NC}"
    IS_GCP=false
fi

# Step 1: Install dependencies
echo -e "\n${BLUE}[1/6]${NC} Installing system dependencies..."
sudo apt update -qq
sudo apt install -y python3 python3-pip python3-venv screen curl > /dev/null 2>&1

# Step 2: Setup project
PROJECT_DIR="$HOME/digital_twin"
if [ ! -d "$PROJECT_DIR" ]; then
    echo -e "${RED}❌ Project not found at $PROJECT_DIR${NC}"
    echo "Please upload your project files first!"
    exit 1
fi

cd "$PROJECT_DIR"
echo -e "${GREEN}✓ Project found${NC}"

# Step 3: Setup Python environment
echo -e "\n${BLUE}[2/6]${NC} Setting up Python environment..."
if [ ! -d "venv" ]; then
    python3 -m venv venv
fi
source venv/bin/activate

# Step 4: Install Python packages
echo -e "\n${BLUE}[3/6]${NC} Installing Python packages..."
cd backend
pip install --upgrade pip -q
pip install -r requirements.txt -q
cd ..
echo -e "${GREEN}✓ Dependencies installed${NC}"

# Step 5: Get API key
echo -e "\n${BLUE}[4/6]${NC} Setting up API key..."
if [ -z "$GEMINI_API_KEY" ]; then
    echo -e "${YELLOW}Enter your Gemini API key:${NC}"
    read -s api_key
    export GEMINI_API_KEY="$api_key"
    echo "export GEMINI_API_KEY=\"$api_key\"" >> ~/.bashrc
    echo -e "${GREEN}✓ API key saved${NC}"
else
    echo -e "${GREEN}✓ API key already set${NC}"
fi

# Step 6: Create start scripts
echo -e "\n${BLUE}[5/6]${NC} Creating start scripts..."

# Backend start script
cat > start-backend.sh << 'EOF'
#!/bin/bash
cd ~/digital_twin
source venv/bin/activate
cd backend
export PORT=5000
export GEMINI_API_KEY="${GEMINI_API_KEY}"
python app.py
EOF
chmod +x start-backend.sh

# Frontend start script
cat > start-frontend.sh << 'EOF'
#!/bin/bash
cd ~/digital_twin/frontend
python3 -m http.server 8000
EOF
chmod +x start-frontend.sh

# Combined start script
cat > start-all.sh << 'EOF'
#!/bin/bash
echo "🚀 Starting RAG App..."
screen -S rag-backend -d -m bash -c 'cd ~/digital_twin && ./start-backend.sh'
sleep 2
screen -S rag-frontend -d -m bash -c 'cd ~/digital_twin && ./start-frontend.sh'
sleep 1
echo "✅ App started!"
echo ""
echo "Backend: http://YOUR_IP:5000"
echo "Frontend: http://YOUR_IP:8000"
echo ""
echo "View logs: screen -r rag-backend (or rag-frontend)"
echo "Stop: screen -X -S rag-backend quit && screen -X -S rag-frontend quit"
EOF
chmod +x start-all.sh

echo -e "${GREEN}✓ Scripts created${NC}"

# Step 7: Get IP and show instructions
echo -e "\n${BLUE}[6/6]${NC} Getting network info..."
EXTERNAL_IP=$(curl -s ifconfig.me 2>/dev/null || echo "YOUR_VM_IP")

echo -e "\n${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ DEPLOYMENT READY!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}📋 NEXT STEPS:${NC}"
echo ""
echo "1. Allow firewall access (run from local machine or Cloud Shell):"
echo -e "   ${BLUE}gcloud compute firewall-rules create allow-rag-app --allow tcp:5000,tcp:8000${NC}"
echo ""
echo "2. Start your app:"
echo -e "   ${BLUE}cd ~/digital_twin${NC}"
echo -e "   ${BLUE}./start-all.sh${NC}"
echo ""
echo "3. Access your app:"
echo -e "   ${GREEN}Frontend: http://$EXTERNAL_IP:8000${NC}"
echo -e "   ${GREEN}Backend:  http://$EXTERNAL_IP:5000${NC}"
echo ""
echo -e "${YELLOW}💡 TIPS:${NC}"
echo "  • View logs: screen -r rag-backend"
echo "  • Stop app: screen -X -S rag-backend quit && screen -X -S rag-frontend quit"
echo "  • Check status: screen -ls"
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

