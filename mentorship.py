from flask import Flask, request, jsonify
import google.generativeai as genai
import requests

app = Flask(_name_)

# Replace with your actual keys
API_KEY = ''
CSE_ID = ''
GEMINI_API_KEY = ''

genai.configure(api_key=GEMINI_API_KEY)

# Predefined search topics
search_queries = [
    "mentorship programs for women in technology 2025",
    "leadership mentorship programs for women 2025",
    "entrepreneurship mentorship for women",
    "free online sessions for women in STEM",
    "mentorship for women students in engineering"
]

def beautify_results(events):
    prompt = "Please format the following mentorship opportunities nicely with markdown and emojis:\n\n"
    for event in events:
        prompt += f"🎓 {event['title']}\n🔗 {event['link']}\n📝 {event.get('snippet', 'No description.')}\n\n"
    
    try:
        model = genai.GenerativeModel('models/gemini-1.5-pro-latest')
        response = model.generate_content(prompt)
        return response.text
    except Exception as e:
        return f"Error during beautification: {str(e)}"

def google_search(query):
    url = "https://www.googleapis.com/customsearch/v1"
    params = {'q': query, 'key': API_KEY, 'cx': CSE_ID, 'num': 5}
    try:
        res = requests.get(url, params=params)
        res.raise_for_status()
        data = res.json()
        if "items" not in data:
            return []
        return [{'title': i['title'], 'link': i['link'], 'snippet': i.get('snippet', '')} for i in data['items']]
    except Exception as e:
        print(f"Error fetching from Google: {str(e)}")
        return []

@app.route('/mentorship', methods=['GET'])
def get_mentorship():
    all_events = []
    
    for query in search_queries:
        events = google_search(query)
        all_events.extend(events)
    
    if not all_events:
        return jsonify({'mentorship': 'No mentorship opportunities found.'})
    
    beautified = beautify_results(all_events)
    return jsonify({'mentorship': beautified})

if _name_ == '_main_':
    app.run(port=5002)
