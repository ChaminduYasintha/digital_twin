# 🚀 Quick Start Guide - GCP Deployment (Super Simple!)

This is the **easiest way** to deploy your RAG app to GCP. No Nginx, no systemd - just get it running!

## Prerequisites

1. ✅ GCP VM instance with Ubuntu (f1-micro works fine for free tier)
2. ✅ Your Gemini API key from [Google AI Studio](https://makersuite.google.com/app/apikey)
3. ✅ SSH access to your VM

---

## Step 1: Connect to Your VM

```bash
gcloud compute ssh YOUR_INSTANCE_NAME --zone=YOUR_ZONE
```

Or use the SSH button in GCP Console.

---

## Step 2: Upload Your Project

**Option A: Using SCP** (from your Windows machine):
```powershell
cd C:\Users\Chamindu\Desktop\RAG_LEARN\digital_twin
scp -r . USERNAME@EXTERNAL_IP:~/digital_twin
```

**Option B: Using Git**:
```bash
cd ~
git clone YOUR_REPO_URL digital_twin
```

---

## Step 3: Run Deployment Script

```bash
cd ~/digital_twin
chmod +x deploy.sh
./deploy.sh
```

The script will:
- ✅ Install Python and dependencies
- ✅ Set up virtual environment
- ✅ Install all packages
- ✅ Ask for your API key if needed
- ✅ Create start scripts

---

## Step 4: Allow Firewall Access

**From your local machine or GCP Cloud Shell:**
```bash
# Allow backend (port 5000)
gcloud compute firewall-rules create allow-rag-backend \
    --allow tcp:5000 \
    --source-ranges 0.0.0.0/0 \
    --description "Allow RAG backend on port 5000"

# Allow frontend (port 8000)
gcloud compute firewall-rules create allow-rag-frontend \
    --allow tcp:8000 \
    --source-ranges 0.0.0.0/0 \
    --description "Allow RAG frontend on port 8000"
```

**Or via GCP Console:**
1. Go to **VPC Network → Firewall**
2. Click **"Create Firewall Rule"**
3. Allow **TCP ports 5000 and 8000**
4. Source: **0.0.0.0/0**

---

## Step 5: Start Your App

```bash
cd ~/digital_twin
./start-all.sh
```

This will start both backend and frontend automatically in the background.

**Alternative - Manual start:**
```bash
# Install screen (if not already installed)
sudo apt install screen

# Start backend in background
screen -S rag-backend -d -m bash -c 'cd ~/digital_twin && ./start-backend.sh'

# Start frontend in background  
screen -S rag-frontend -d -m bash -c 'cd ~/digital_twin && ./start-frontend.sh'

# Check they're running
screen -ls
```

---

## Step 6: Access Your App

1. Get your VM's external IP:
   ```bash
   curl ifconfig.me
   ```

2. Open in browser:
   ```
   http://YOUR_EXTERNAL_IP:8000
   ```
   
   This will show the frontend, which automatically connects to the backend on port 5000.

**Note:** The simple setup serves frontend and backend separately:
- Frontend runs on port 8000 (serves the HTML)
- Backend runs on port 5000 (Flask API)
- The frontend automatically connects to the backend on the same hostname

---

## Keep It Running (After Closing SSH)

The setup script already shows you how to use `screen` to run both services in the background. They'll keep running even after you close SSH.

**To check if they're running:**
```bash
screen -ls
```

**To view logs:**
```bash
# View backend logs
screen -r backend

# View frontend logs  
screen -r frontend

# Detach: Press Ctrl+A, then D
```

**To stop services:**
```bash
# Stop backend
screen -X -S backend quit

# Stop frontend
screen -X -S frontend quit
```

---

## That's It! 🎉

Your app is now running! 

### Quick Commands:

```bash
# Start app
cd ~/digital_twin && ./start.sh

# Stop app
# Press Ctrl+C in the terminal where it's running

# View logs
# They appear in the terminal where you started it
```

---


## Troubleshooting

**Can't access from browser?**
- Check firewall rule is created
- Make sure app is running: `curl http://localhost:5000`
- Verify external IP: `curl ifconfig.me`

**App stops when I close SSH?**
- Use `screen` or `tmux` (see above)
- Or use the full setup with systemd

**Port already in use?**
- Change port: `export PORT=8080` before starting
- Or kill existing process: `sudo lsof -ti:5000 | xargs kill`

---

## Next Steps

1. ✅ Test your app works
2. ✅ Set up screen/tmux for persistence
3. ✅ Your app is ready to use!

**Questions?** Check the main [README.md](README.md) for more details.

