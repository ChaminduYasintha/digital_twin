<!-- @format -->

# Digital Twin - Agentic RAG Application

A Retrieval Augmented Generation (RAG) application with an agentic architecture that allows you to upload PDF documents and ask questions about them using Google's Gemini AI.

## Project Structure

```
digital_twin/
├── backend/
│   ├── app.py          # Flask backend server
│   └── requirements.txt # Python dependencies
├── frontend/
│   └── index.html      # Frontend UI
├── deploy.sh           # One-command deployment script
├── QUICK_START.md      # Quick deployment guide
└── README.md           # This file
```

## Prerequisites

1. **Python 3.11+** installed on your system
2. **Google Gemini API Key** - Get one from [Google AI Studio](https://makersuite.google.com/app/apikey)
3. **GCP VM Instance** - A Compute Engine VM instance running Ubuntu/Debian

## Local Development

### 1. Install Python Dependencies

```bash
cd backend
pip install -r requirements.txt
```

### 2. Set Up Environment Variable

**On Windows (PowerShell):**

```powershell
$env:GEMINI_API_KEY="your-api-key-here"
```

**On Windows (Command Prompt):**

```cmd
set GEMINI_API_KEY=your-api-key-here
```

**On Linux/Mac:**

```bash
export GEMINI_API_KEY="your-api-key-here"
```

### 3. Run the Backend Server

```bash
cd backend
python app.py
```

The server will start on `http://127.0.0.1:5000`.

### 4. Open the Frontend

Open the `frontend/index.html` file in your web browser.

## Usage

1. **Upload a Document**: Click the "Load Knowledge" button and select a PDF file
2. **Ask Questions**: Type your question in the input field and press Enter or click the send button
3. **View Agent Thoughts**: Click on "Agent Thought Process" to see how the agent processes your query
4. **Check Sources**: View citation badges showing which sections of the document were referenced

## Features

- **PDF Document Processing**: Upload and process PDF documents
- **Vector Search**: Uses FAISS for efficient similarity search
- **Agentic Architecture**: Shows the agent's thinking process (routing, retrieval, synthesis)
- **Source Citations**: Displays which sections of the document were referenced
- **Modern UI**: Clean, dark-themed interface with Tailwind CSS
- **Animated Bot**: Live typing effects and status indicators

## Deployment to GCP VM

### 🚀 Super Simple Setup (Recommended for Beginners)

**Easiest way - just 2 steps!**

1. **SSH into your VM, upload project, and run deploy script**

   ```bash
   gcloud compute ssh INSTANCE_NAME --zone=ZONE_NAME
   # Upload files or: git clone YOUR_REPO ~/digital_twin
   cd ~/digital_twin
   chmod +x deploy.sh
   ./deploy.sh
   ```

2. **Allow firewall and start**

   ```bash
   # Allow ports (from local machine or Cloud Shell)
   gcloud compute firewall-rules create allow-rag-app --allow tcp:5000,tcp:8000

   # Start your app
   cd ~/digital_twin
   ./start-all.sh
   ```

**Access at:** `http://YOUR_EXTERNAL_IP:8000`

📖 **Full guide:** See [QUICK_START.md](QUICK_START.md) for detailed steps.

## Service Management

Once deployed, manage your app with:

```bash
# View backend logs
screen -r rag-backend

# View frontend logs
screen -r rag-frontend

# Check if services are running
screen -ls

# Stop services
screen -X -S rag-backend quit
screen -X -S rag-frontend quit

# Restart services
cd ~/digital_twin
./start-all.sh
```

## API Endpoints

- `POST /upload` - Upload a PDF file for processing
- `POST /chat` - Send a chat message and get a response

## Troubleshooting

### Local Development

- **"ERROR: Set GEMINI_API_KEY environment variable"**: Make sure you've set the environment variable correctly
- **Connection errors**: Ensure the backend server is running on port 5000
- **Import errors**: Make sure all dependencies are installed: `pip install -r backend/requirements.txt`

### Live Demo url
http://136.117.28.118:8000/

## License

This project is open source and available for personal and commercial use.
