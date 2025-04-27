import google.generativeai as genai
import spacy
from textblob import TextBlob
import re

# ✅ Configure Gemini API key
genai.configure(api_key="Replace with your real Gemini key")  # Replace with your actual key

# ✅ Initialize Gemini Model
model = genai.GenerativeModel("gemini-2.0-flash")
chat = model.start_chat(history=[{
    "role": "user",
    "parts": [
        "You are Ashabot, an ethical AI chatbot. Always respond respectfully and avoid engaging in gender-biased or discriminatory content. "
        "If such content is detected, respond with educational, inclusive, and fact-based replies."
    ]
}])

# ✅ Load spaCy model
nlp = spacy.load("en_core_web_sm")

# Bias detection patterns and empowering messages
bias_patterns = {
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
    "women’s role in history": "Women have made monumental contributions across history."
}

# Suggestion for reframing biased questions
def suggest_reframing(pattern):
    reframes = {
        "suitability for leadership": "Ask about leadership qualities in all individuals.",
        "emotional stability": "Focus on emotional intelligence across all leaders.",
        "tech ability": "Highlight tech expertise without linking to gender.",
        "logical thinking": "Emphasize logical thinking as a universal human trait.",
        "career vs family": "Discuss career and family balance inclusively.",
        "aggressiveness in women": "Celebrate assertiveness for all genders.",
        "women in STEM": "Celebrate contributions of everyone in STEM.",
        "women in politics": "Recognize political leadership without assumptions.",
        "women's emotional nature": "Focus on emotional intelligence as a human strength.",
        "women's competence in business": "Highlight business leadership across all people.",
        "women’s role in history": "Explore contributions from all genders."
    }
    return reframes.get(pattern, "Consider rephrasing to be more inclusive.")

# ✅ Sentiment analysis
def analyze_sentiment(text):
    blob = TextBlob(text)
    polarity = blob.sentiment.polarity
    if polarity > 0.1:
        return "positive"
    elif polarity < -0.1:
        return "negative"
    else:
        return "neutral"

# ✅ Bias detection with suggestion
def detect_gender_bias(text):
    doc = nlp(text.lower())
    for chunk in doc.noun_chunks:
        if "women" in chunk.text:
            for pattern in bias_patterns:
                if re.search(r'\b' + r'\b|\b'.join(pattern.split()) + r'\b', text.lower()):
                    suggestion = suggest_reframing(pattern)
                    return (
                        f"{bias_patterns[pattern]}\n\n"
                        "🛠️ Suggestion: " + suggestion
                    )
    return None

# ✅ Colors for terminal output
class Colors:
    RED = '\033[91m'
    GREEN = '\033[92m'
    WHITE = '\033[97m'
    RESET = '\033[0m'

# ✅ Start Chatbot
print(f"{Colors.WHITE}🤖 Ashabot: Hello! I'm Ashabot, your ethical and inclusive chatbot 🌟 (type 'exit' to quit){Colors.RESET}")

while True:
    try:
        user_input = input("You: ")

        if user_input.lower() in ["exit", "quit"]:
            print(f"{Colors.WHITE}🤖 Ashabot: Goodbye! Stay kind and curious! 🌟{Colors.RESET}")
            break

        # Sentiment detection
        sentiment = analyze_sentiment(user_input)
        print(f"{Colors.WHITE}🤖 Ashabot (Sentiment Detected): {sentiment.capitalize()}{Colors.RESET}")

        # Bias detection
        bias_warning = detect_gender_bias(user_input)
        if bias_warning:
            print(f"{Colors.RED}⚠️ Ethical Warning: Gender-biased statement detected!{Colors.RESET}")
            print(f"{Colors.GREEN}🤖 Ashabot (Empowering Message): {bias_warning}{Colors.RESET}")
            print(f"{Colors.WHITE}🤖 Ashabot: Let's continue the conversation inclusively! 🌟{Colors.RESET}")
            continue  # Do not send biased input to Gemini

        # Normal flow
        try:
            response = chat.send_message(user_input)
            print(f"{Colors.WHITE}🤖 Ashabot: {response.text}{Colors.RESET}")
        except Exception as e:
            print(f"{Colors.RED}❌ Error communicating with Gemini API: {str(e)}{Colors.RESET}")

    except KeyboardInterrupt:
        print(f"\n{Colors.WHITE}🤖 Ashabot: Interrupted. Goodbye! 🌟{Colors.RESET}")
        break
