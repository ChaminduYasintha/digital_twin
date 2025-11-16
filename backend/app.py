import os
import io
import google.generativeai as genai
from flask import Flask, request, jsonify
from flask_cors import CORS
import faiss
import numpy as np
import PyPDF2

app = Flask(__name__)
CORS(app)

# --- CONFIG ---
api_key = os.environ.get("GEMINI_API_KEY")
if not api_key:
    print("ERROR: Set GEMINI_API_KEY environment variable.")
    print("You can set it with: export GEMINI_API_KEY='your-key-here'")
    exit(1)

try:
    genai.configure(api_key=api_key)
    print("✓ API key configured")
except Exception as e:
    print(f"ERROR: Failed to configure API: {str(e)}")
    print("Please check your GEMINI_API_KEY and try again.")
    exit(1)

# Models
generation_model = genai.GenerativeModel('gemini-2.5-flash-preview-09-2025')
embedding_model = 'models/text-embedding-004'

# State
vector_store = None
document_chunks = [] # List of dicts: {'text': "...", 'source': "Page 1"}

# --- RAG HELPERS ---

def get_text_chunks(text):
    """Split text and track page numbers roughly (simplified)"""
    raw_chunks = [c for c in text.split('\n\n') if len(c) > 50]
    # In a real app, we'd track exact pages. Here we simulate metadata.
    structured_chunks = []
    for i, chunk in enumerate(raw_chunks):
        structured_chunks.append({
            'text': chunk,
            'source': f"Section {i+1}" # Metadata
        })
    return structured_chunks

def retrieve_context(query, k=3):
    """Search Vector Store and return text + metadata"""
    global vector_store, document_chunks
    if vector_store is None:
        return [], []
    
    try:
        # Embed Query
        q_embed = genai.embed_content(model=embedding_model, content=query, task_type="RETRIEVAL_QUERY")["embedding"]
        q_np = np.array([q_embed], dtype=np.float32)
        
        # Search
        D, I = vector_store.search(q_np, k)
        
        found_texts = []
        found_sources = []
        
        for idx in I[0]:
            if idx < len(document_chunks):
                found_texts.append(document_chunks[idx]['text'])
                found_sources.append(document_chunks[idx]['source'])
                
        return found_texts, list(set(found_sources)) # Unique sources
    except Exception as e:
        print(f"Error in retrieve_context: {str(e)}")
        return [], []

# --- AGENTIC LOGIC ---

@app.route('/upload', methods=['POST'])
def upload_file():
    global document_chunks, vector_store
    file = request.files['file']
    
    # Process PDF
    pdf_reader = PyPDF2.PdfReader(io.BytesIO(file.read()))
    full_text = ""
    for page in pdf_reader.pages:
        full_text += page.extract_text() + "\n\n"

    # Chunk & Embed
    try:
        document_chunks = get_text_chunks(full_text)
        texts_only = [c['text'] for c in document_chunks]
        
        embeddings = genai.embed_content(model=embedding_model, content=texts_only, task_type="RETRIEVAL_DOCUMENT")["embedding"]
        
        # Build Index
        vector_store = faiss.IndexFlatL2(768)
        vector_store.add(np.array(embeddings, dtype=np.float32))
        
        return jsonify({"message": f"🎉 Awesome! I've successfully learned from *{file.filename}*. I indexed {len(document_chunks)} sections and I'm ready to answer your questions! Feel free to ask me anything about it. 😊"})
    except Exception as e:
        print(f"Error processing file: {str(e)}")
        return jsonify({"error": f"Error processing file: {str(e)}. Please check your API key."}), 500

@app.route('/chat', methods=['POST'])
def chat():
    data = request.json
    user_msg = data['message']
    history = data['history']
    
    thoughts = [] # Log the agent's thinking
    sources = []
    
    # --- STEP 1: ROUTER (Agent Brain) ---
    # The agent decides: Do I need the uploaded document?
    thoughts.append("🤔 Understanding what you're asking: " + user_msg[:20] + "...")
    
    requires_rag = False
    if vector_store is not None:
        # Simple keyword heuristic for routing (Can be replaced with LLM router)
        thoughts.append("✅ Great! I have documents loaded and ready to search.")
        requires_rag = True 
    else:
        thoughts.append("💭 No documents uploaded yet, but I'll do my best with general knowledge!")

    # --- STEP 2: TOOL USE (Retrieval) ---
    context_text = ""
    if requires_rag:
        thoughts.append("🔍 Searching through my knowledge base...")
        retrieved_texts, retrieved_sources = retrieve_context(user_msg)
        
        if retrieved_texts:
            thoughts.append(f"✨ Perfect! Found {len(retrieved_texts)} relevant sections that might help.")
            context_text = "\n".join(retrieved_texts)
            sources = retrieved_sources
        else:
            thoughts.append("😕 Hmm, I couldn't find specific information about that in the documents.")
    
    # --- STEP 3: SYNTHESIS (Generation) ---
    thoughts.append("💬 Crafting a helpful and friendly response for you...")
    
    system_instruction = """You are a friendly and helpful AI assistant. 
    1. Answer based on the CONTEXT provided below, but be warm and conversational.
    2. If the context is empty or doesn't contain the answer, politely and kindly let the user know that you don't have that information in the document, but offer to help with what you do know.
    3. Be concise but friendly - use a warm, approachable tone.
    4. Feel free to use emojis occasionally to make the conversation more engaging.
    5. Show enthusiasm when you can help, and be empathetic when you cannot."""
    
    prompt = f"""
    {system_instruction}
    
    CONTEXT FROM DOCUMENT:
    {context_text}
    
    USER QUESTION: 
    {user_msg}
    """
    
    # Simple stateless call for demo (uses history in real app)
    try:
        response = generation_model.generate_content(prompt)
        reply_text = response.text if response.text else "I'm sorry, I couldn't generate a response. Please try again."
    except Exception as e:
        print(f"Error generating response: {str(e)}")
        reply_text = f"I encountered an error: {str(e)}. Please check your API key and try again."
    
    return jsonify({
        'reply': reply_text,
        'thoughts': thoughts,  # Send thoughts to frontend
        'sources': sources     # Send sources to frontend
    })

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port, debug=False)