from flask import Flask, request, jsonify
from flask_cors import CORS
import requests
import re
from datetime import datetime
from bs4 import BeautifulSoup
import google.generativeai as genai

# Replace with your actual API Keys
GOOGLE_API_KEY = 'AIzaSyDrlfaeNvHQiO6IAkb5-DGa2CSrkxCTq4E'  # Google API Key for Custom Search
CSE_ID = 'd168988076f8b4dbd'          # Custom Search Engine ID
GEMINI_API_KEY = 'AIzaSyDrlfaeNvHQiO6IAkb5-DGa2CSrkxCTq4E'  # Gemini API Key (different from Google API Key)

# Configure Gemini
genai.configure(api_key=GEMINI_API_KEY)

app = Flask(__name__)
CORS(app)  # Enable CORS so Flutter can connect

def parse_date_from_string(date_string):
    """Try to extract date from a string, returns None if no date found"""
    for fmt in ("%B %d, %Y", "%Y-%m-%d", "%b %d, %Y", "%d%B%Y", "%B %d %Y", "%d %B %Y"):
        try:
            return datetime.strptime(date_string, fmt)
        except ValueError:
            continue
    return None

def extract_event_date_from_link(event_url):
    """Try to scrape the event date from the event page"""
    try:
        page = requests.get(event_url, timeout=10)
        soup = BeautifulSoup(page.content, 'html.parser')
        date_texts = soup.find_all(string=re.compile(r'(\w+\s\d{1,2}(?:[-–]\d{1,2})?,?\s\d{4})'))
        for text in date_texts:
            date_match = re.search(r'(\w+\s\d{1,2}),?\s(\d{4})', text)
            if date_match:
                date_string = f"{date_match.group(1)}, {date_match.group(2)}"
                parsed_date = parse_date_from_string(date_string)
                if parsed_date:
                    return parsed_date
    except Exception:
        pass
    return None

def beautify_event_list(events):
    """Beautify the event details using Gemini API"""
    prompt = "Please beautify the following event details with clear sections, markdown style, and emojis:\n\n"
    for event in events:
        prompt += f"Title: {event['title']}\nLink: {event['link']}\nSnippet: {event['snippet']}\nEvent Date: {event['date']}\n\n"
    
    try:
        model = genai.GenerativeModel('models/gemini-1.5-pro-latest')
        response = model.generate_content(prompt)
        return response.text
    except Exception as e:
        return f"Error during beautification: {str(e)}"

def search_events(query):
    """Search for public events related to the query"""
    url = f'https://www.googleapis.com/customsearch/v1?q={query}&key={GOOGLE_API_KEY}&cx={CSE_ID}'
    response = requests.get(url)

    events = []

    if response.status_code == 200:
        search_results = response.json()

        if 'items' in search_results:
            for result in search_results['items']:
                title = result['title']
                link = result['link']
                snippet = result.get('snippet', '')

                # Try regex to find date
                date_match = re.search(r'(\d{4}-\d{2}-\d{2}|[A-Za-z]+\s\d{1,2},?\s\d{4})', title + " " + snippet)
                if date_match:
                    event_date = parse_date_from_string(date_match.group(0))
                else:
                    event_date = extract_event_date_from_link(link)

                if event_date and event_date >= datetime.now():
                    events.append({
                        'title': title,
                        'link': link,
                        'snippet': snippet,
                        'date': event_date.strftime('%B %d, %Y')
                    })
    return events

@app.route('/events', methods=['POST'])
def get_events():
    try:
        data = request.get_json()
        query = data.get('query', '')

        if not query:
            return jsonify({'error': 'No query provided'}), 400

        events = search_events(query)

        if events:
            beautified = beautify_event_list(events)
            return jsonify({'events': beautified})
        else:
            return jsonify({'events': 'No upcoming events found.'})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(debug=True, port=5001)