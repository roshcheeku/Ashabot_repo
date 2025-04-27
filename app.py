# ✅ Flask and other imports
from flask import Flask, request, jsonify, render_template
from flask_cors import CORS
import google.generativeai as genai
import spacy
from textblob import TextBlob
import re
import PyPDF2
import docx
from io import BytesIO
import base64
import random

app = Flask(__name__)
CORS(app)  # Enable CORS

# ✅ Configure Gemini API
genai.configure(api_key="Replace with your real Gemini key")  # Replace with your real Gemini key

# ✅ Initialize Gemini Model
model = genai.GenerativeModel("gemini-2.0-flash")
chat = model.start_chat(history=[{
    "role": "user",
    "parts": [
        "You are Ashabot, an ethical AI chatbot. Always respond respectfully and avoid gender-biased, color-biased, or discriminatory content. "
        "If such content is detected, respond with educational, inclusive, and fact-based replies."
    ]
}])

# ✅ Load spaCy model
nlp = spacy.load("en_core_web_sm")

# ✅ Bias detection patterns with educational responses
bias_patterns = {
    # Gender bias
    "suitability for leadership": "Absolutely! Women have led globally—in government, business, and science.",
    "emotional stability": "Emotional intelligence is a leadership asset for everyone.",
    "tech ability": "Women are innovators in tech—from Ada Lovelace to today's pioneers.",
    "logical thinking": "Logic is a human ability, not gender-specific.",
    "career vs family": "Many women successfully balance career and family. Stereotypes don't define reality.",
    "aggressiveness in women": "Assertiveness is a leadership strength for all genders.",
    "women in STEM": "Women have been crucial in STEM fields, past and present.",
    "women in politics": "Women have led nations and made major political impacts globally.",
    "women's emotional nature": "Emotions are part of being human and a leadership strength.",
    "women's competence in business": "Women are highly competent business leaders and entrepreneurs.",
    "women's role in history": "Women have made monumental contributions across history.",
    
    # Color bias - expanded
    "pink is for girls": "Colors have no gender. Pink is for everyone!",
    "blue is for boys": "Colors are universal—blue is loved by all genders.",
    "girls like pink": "Color preference is personal, not based on gender.",
    "boys like blue": "Everyone can enjoy any color they like.",
    "men wearing pink": "Color choices are personal expression, not gender markers.",
    "female colors": "Colors don't have gender. They're wavelengths of light we all perceive!",
    "masculine colors": "Colors are universal expressions, not gendered traits.",
    "girly colors": "All colors are for all people - personal preference matters, not stereotypes.",
    "boyish colors": "Colors are just visual expressions that anyone can enjoy!",
    
    # Additional color-related biases
    "girl toys": "Toys are for everyone to enjoy based on interests, not gender.",
    "boy toys": "All children benefit from diverse play experiences regardless of gender.",
    "dress like a girl": "Clothing is personal expression, not defined by gender.",
    "dress like a boy": "Everyone should wear what makes them comfortable and confident.",
}

# ✅ Empowering messages to display with bias warnings
empowering_messages = [
    "💪 Equality empowers everyone. When we break stereotypes, we all thrive!",
    "🌟 Diversity of thought and experience makes our world richer.",
    "🚀 Breaking barriers creates opportunities for everyone to reach their potential.",
    "🔄 When we challenge biases, we create a more inclusive world.",
    "🌈 Embracing our authentic selves creates a colorful, vibrant society.",
    "🧠 Open minds lead to innovative solutions and stronger communities.",
    "🤝 Together, we can build a world where everyone's contributions are valued.",
    "🔍 Questioning assumptions helps us discover new possibilities.",
    "🌱 Growth happens when we move beyond limiting beliefs.",
    "⚖️ Fairness and equity benefit everyone in society.",
    "🎭 Expression without gender constraints allows authentic creativity to flourish.",
    "🔗 Connection across differences builds stronger communities.",
]

# ✅ Suggestion for reframing
def suggest_reframing(pattern):
    reframes = {
        # Gender bias
        "suitability for leadership": "Ask about leadership qualities in people of all genders.",
        "emotional stability": "Discuss emotional intelligence across all individuals.",
        "tech ability": "Ask about tech innovations by different people.",
        "logical thinking": "Discuss logic skills across everyone.",
        "career vs family": "Talk about work-life balance for all people.",
        "aggressiveness in women": "Celebrate assertiveness in leadership for all genders.",
        "women in STEM": "Ask about contributions to STEM across all people.",
        "women in politics": "Discuss political leadership examples broadly.",
        "women's emotional nature": "Focus on emotional strength across all individuals.",
        "women's competence in business": "Talk about success stories in business from all backgrounds.",
        "women's role in history": "Explore key historical figures regardless of gender.",
        
        # Color bias - expanded
        "pink is for girls": "Ask about how colors can inspire creativity for everyone.",
        "blue is for boys": "Ask about favorite colors and what they mean to people.",
        "girls like pink": "Explore why people like different colors regardless of gender.",
        "boys like blue": "Discuss how color preferences are personal choices.",
        "men wearing pink": "Consider how color choices can express individuality for everyone.",
        "female colors": "Explore the cultural history of color associations instead.",
        "masculine colors": "Ask about how colors evoke different emotions for different people.",
        "girly colors": "Consider discussing color theory and psychological impacts instead.",
        "boyish colors": "Focus on how colors enhance spaces and experiences for everyone.",
        
        # Additional color-related biases
        "girl toys": "Ask about toys that develop different skills for all children.",
        "boy toys": "Discuss how play experiences benefit child development universally.",
        "dress like a girl": "Explore how clothing reflects personal style across all people.",
        "dress like a boy": "Consider how comfort and function guide clothing choices for everyone.",
    }
    return reframes.get(pattern, "Consider rephrasing your question to be more inclusive.")

# ✅ Color codes for bias warnings
bias_warning_colors = {
    "gender": "#FF69B4",  # Hot Pink
    "color": "#1E90FF",   # Dodger Blue
    "general": "#9932CC"  # Dark Orchid
}

# ✅ Categorize bias types
bias_categories = {
    # Gender bias
    "suitability for leadership": "gender",
    "emotional stability": "gender",
    "tech ability": "gender",
    "logical thinking": "gender",
    "career vs family": "gender",
    "aggressiveness in women": "gender",
    "women in STEM": "gender",
    "women in politics": "gender",
    "women's emotional nature": "gender",
    "women's competence in business": "gender",
    "women's role in history": "gender",
    
    # Color bias - all categorized as "color"
    "pink is for girls": "color",
    "blue is for boys": "color",
    "girls like pink": "color",
    "boys like blue": "color",
    "men wearing pink": "color",
    "female colors": "color",
    "masculine colors": "color",
    "girly colors": "color",
    "boyish colors": "color",
    
    # Additional color-related biases
    "girl toys": "color",
    "boy toys": "color",
    "dress like a girl": "color",
    "dress like a boy": "color",
}

# ✅ Sentiment Analysis
def analyze_sentiment(text):
    blob = TextBlob(text)
    polarity = blob.sentiment.polarity
    if polarity > 0.1:
        return "positive"
    elif polarity < -0.1:
        return "negative"
    else:
        return "neutral"

# ✅ Bias Detection (Gender + Color)
def detect_bias(text):
    text_lower = text.lower()
    doc = nlp(text_lower)
    
    # Check for all bias patterns
    for pattern in bias_patterns:
        if re.search(r'\b' + r'\b|\b'.join(pattern.split()) + r'\b', text_lower):
            category = bias_categories.get(pattern, "general")
            color_code = bias_warning_colors.get(category, "#9932CC")  # Default to purple if category not found
            suggestion = suggest_reframing(pattern)
            empowering_message = random.choice(empowering_messages)
            
            return {
                "detected": True,
                "pattern": pattern,
                "response": bias_patterns[pattern],
                "category": category,
                "color": color_code,
                "suggestion": suggestion,
                "empowering_message": empowering_message
            }
    
    # Additional check for gender bias with noun chunks
    for chunk in doc.noun_chunks:
        if "women" in chunk.text or "girl" in chunk.text or "female" in chunk.text:
            for pattern in bias_patterns:
                if pattern in bias_categories and bias_categories[pattern] == "gender":
                    if any(word in text_lower for word in pattern.split()):
                        suggestion = suggest_reframing(pattern)
                        empowering_message = random.choice(empowering_messages)
                        
                        return {
                            "detected": True,
                            "pattern": pattern,
                            "response": bias_patterns[pattern],
                            "category": "gender",
                            "color": bias_warning_colors["gender"],
                            "suggestion": suggestion,
                            "empowering_message": empowering_message
                        }
    
    return {"detected": False}

# ✅ File Parsing - PDF and DOCX
def extract_pdf_text(file):
    pdf_reader = PyPDF2.PdfReader(file)
    text = ""
    for page in pdf_reader.pages:
        text += page.extract_text()
    return text

def extract_docx_text(file):
    doc = docx.Document(file)
    text = ""
    for para in doc.paragraphs:
        text += para.text + "\n"
    return text

# ✅ Routes

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/api/chat', methods=['POST'])
def chat_with_ashabot():
    data = request.get_json()

    user_message = data.get('message', '')
    session_id = data.get('session_id')
    has_files = data.get('has_files', False)
    files = data.get('files', [])

    # Handle case where both message and files are empty
    if not user_message and not has_files:
        return jsonify({'error': 'No message or files provided.'}), 400

    # Analyze sentiment if there's text
    sentiment = "neutral"
    if user_message:
        sentiment = analyze_sentiment(user_message)

    # Detect bias if there's text
    if user_message:
        bias_result = detect_bias(user_message)
        if bias_result["detected"]:
            return jsonify({
                'type': 'bias',
                'response': "⚠ Ethical Warning: Biased content detected!",
                'message': bias_result["response"],
                'suggestion': bias_result["suggestion"],
                'empowering_message': bias_result["empowering_message"],
                'category': bias_result["category"],
                'color': bias_result["color"],
                'note': "Let's keep it positive and inclusive! 🌈",
                'session_id': session_id
            })

    # Handle file uploads
    file_text = ""
    if has_files and files:
        for file_info in files:
            file_name = file_info.get('file_name', '')
            file_content = file_info.get('file_data')  # Base64 content

            if not file_content:
                file_text += f"\n[File: {file_name} - content not processed]\n"
                continue

            try:
                file_data = BytesIO(base64.b64decode(file_content))

                if file_name.lower().endswith('.pdf'):
                    file_text += extract_pdf_text(file_data)
                elif file_name.lower().endswith(('.docx', '.doc')):
                    file_text += extract_docx_text(file_data)
                else:
                    file_text += f"\n[File: {file_name} - type not processed]\n"

            except Exception as e:
                file_text += f"\n[Error processing {file_name}: {str(e)}]\n"

    # Prepare prompt
    if user_message and file_text:
        prompt = (
            f"User uploaded file(s):\n{file_text}\n\n"
            f"User query: {user_message}\n\n"
            f"Please use the uploaded file(s) to better answer."
        )
    elif file_text:
        prompt = (
            f"User uploaded file(s):\n{file_text}\n\n"
            f"Please analyze and respond to the content of these files."
        )
    else:
        prompt = user_message

    # Normal chat response
    try:
        response = chat.send_message(prompt)
        return jsonify({
            'type': 'normal',
            'sentiment': sentiment,
            'response': response.text,
            'session_id': session_id
        })
    except Exception as e:
        return jsonify({'error': f'Error communicating with Gemini API: {str(e)}'}), 500

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)
