import requests
import base64

# Path to your PDF file
file_path = r"C:\Users\drros\OneDrive\Desktop\final ml resume _250110_1243124.pdf"

# Read the file and encode it in base64
with open(file_path, "rb") as file:
    file_data = file.read()
    file_base64 = base64.b64encode(file_data).decode('utf-8')

# API URL of your Flask server
url = 'http://127.0.0.1:5000/api/chat'

# Prepare the data to send
data = {
    "message": "Please analyze the content of my resume.",
    "session_id": "12345",  # Unique session ID
    "has_files": True,
    "files": [
        {
            "file_name": "final ml resume _250110_1243124.pdf",
            "file_data": file_base64
        }
    ]
}

# Send the POST request
response = requests.post(url, json=data)

# Print the response from the server
print(response.json())
