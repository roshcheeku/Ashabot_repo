from flask import Flask, request, jsonify
import http.client
import json
import google.generativeai as genai
from google.api_core.exceptions import GoogleAPIError

app = Flask(_name_)

# Set your API keys
JOOBLE_API_KEY = ''  # Replace with your actual Jooble API key
GEMINI_API_KEY = ''  # Replace with your actual Gemini API key

# Configure Gemini
genai.configure(api_key=GEMINI_API_KEY)

@app.route('/jobs', methods=['POST'])
def get_jobs():
    data = request.json
    keywords = data.get('keywords', '')
    location = data.get('location', '')

    if not keywords or not location:
        return jsonify({"error": "Please provide both keyword and location."}), 400

    # Jooble API request setup
    host = 'jooble.org'
    connection = http.client.HTTPConnection(host)
    headers = {"Content-type": "application/json"}
    body = json.dumps({"keywords": keywords, "location": location})

    connection.request('POST', f'/api/{JOOBLE_API_KEY}', body, headers)
    response = connection.getresponse()
    data = json.loads(response.read().decode('utf-8'))

    if data.get('totalCount', 0) == 0:
        return jsonify({"message": f"No jobs found for '{keywords}' in {location}."}), 404

    # Construct raw job data string
    raw_jobs = ""
    for job in data['jobs']:
        raw_jobs += (
            f"Title: {job.get('title', 'No title')}\n"
            f"Company: {job.get('company', 'No company')}\n"
            f"Location: {job.get('location', 'No location')}\n"
            f"Type: {job.get('type', 'No type')}\n"
            f"Salary: {job.get('salary', 'No salary')}\n"
            f"Link: {job.get('link', 'No link')}\n"
            f"Updated: {job.get('updated', 'No date')}\n"
            f"Snippet: {job.get('snippet', 'No snippet')}\n\n"
        )

    # Add the prompt back for Gemini
    prompt = f"""
Please format the following job listings for women in tech using markdown style with emojis.

Use this structure for every job:

🔹 *Title*  
🏢 Company  
📍 Location  
🕐 Type  
💰 Salary  
🔗 Link  
🆙 Last Updated  
📝 Description

Only return the listings. Do not include any messages like "continues in same format" or similar.

Here is the data:

{raw_jobs}
"""

    try:
        model = genai.GenerativeModel(model_name='models/gemini-1.5-pro-latest')
        result = model.generate_content(prompt)
        return jsonify({"formattedJobs": result.text})
    except GoogleAPIError as e:
        return jsonify({
            "error": "Error generating content using Gemini API.",
            "fallback": raw_jobs
        }), 500

if _name_ == '_main_':
    app.run(debug=True)
 jobs.py
