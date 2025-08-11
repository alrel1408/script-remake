#!/bin/bash

# VPN API Server Startup Script
# AlrelShop VPN Management API

API_DIR="/etc/vpn-api"
API_PORT=5000
API_PID_FILE="/var/run/vpn-api.pid"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}🚀 Starting VPN Management API Server${NC}"

# Create API directory if not exists
if [ ! -d "$API_DIR" ]; then
    mkdir -p $API_DIR
    echo -e "${YELLOW}📁 Created API directory: $API_DIR${NC}"
fi

# Check if config exists
if [ ! -f "$API_DIR/config.json" ]; then
    echo -e "${YELLOW}⚙️  Creating default configuration...${NC}"
    
    # Generate random API key
    API_KEY=$(openssl rand -hex 32)
    
    cat > $API_DIR/config.json << EOF
{
    "api_key": "$API_KEY",
    "port": $API_PORT,
    "host": "0.0.0.0",
    "debug": false
}
EOF
    
    echo -e "${GREEN}✅ Configuration created with API Key: $API_KEY${NC}"
    echo -e "${YELLOW}💡 Simpan API Key ini untuk mengakses API!${NC}"
fi

# Check if Python and pip are installed
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}❌ Python3 tidak ditemukan. Installing...${NC}"
    apt update && apt install -y python3 python3-pip
fi

# Install Python dependencies
if [ ! -d "venv" ]; then
    echo -e "${YELLOW}📦 Creating virtual environment...${NC}"
    python3 -m venv venv
fi

source venv/bin/activate
pip install -r requirements.txt

# Start API server
echo -e "${GREEN}🌐 Starting API server on port $API_PORT...${NC}"

# Kill existing process if running
if [ -f "$API_PID_FILE" ]; then
    OLD_PID=$(cat $API_PID_FILE)
    if ps -p $OLD_PID > /dev/null; then
        kill $OLD_PID
        echo -e "${YELLOW}🔄 Stopped existing API server${NC}"
    fi
fi

# Start with gunicorn
nohup gunicorn --bind 0.0.0.0:$API_PORT --workers 4 --timeout 60 app:app > /var/log/vpn-api.log 2>&1 &
echo $! > $API_PID_FILE

sleep 2

# Check if server started successfully
if ps -p $(cat $API_PID_FILE) > /dev/null; then
    echo -e "${GREEN}✅ VPN API Server started successfully!${NC}"
    echo -e "${GREEN}📍 Server running on: http://0.0.0.0:$API_PORT${NC}"
    echo -e "${GREEN}📋 Log file: /var/log/vpn-api.log${NC}"
    
    # Show API key
    API_KEY=$(grep -o '"api_key": "[^"]*"' $API_DIR/config.json | cut -d'"' -f4)
    echo -e "${YELLOW}🔑 API Key: $API_KEY${NC}"
else
    echo -e "${RED}❌ Failed to start API server. Check logs: /var/log/vpn-api.log${NC}"
    exit 1
fi

