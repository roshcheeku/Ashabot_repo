# Ashabot Flask API

An ethical AI chatbot API built with Flask that handles file uploads and creates respectful, educational, and bias-free responses using Google's Gemini AI.

## Features

- **Ethical AI Responses**: Detects and addresses gender bias with educational content
- **File Processing**: Handles multiple file types (PDF, DOCX, TXT, images)
- **Sentiment Analysis**: Analyzes the sentiment of user messages
- **Suggestion Generation**: Provides relevant follow-up questions
- **Opportunity Recommendations**: Suggests opportunities based on user profile and message content

## API Endpoints

### POST `/api/chat`

Main endpoint for chat functionality.

**Request Format**:
```json
{
  "session_id": "unique-session-id",
  "has_files": true,
  "message": "User's text message",
  "files": [
    {
      "file_name": "document.pdf",
      "file_data": "base64-encoded-file-content",
      "file_type": "pdf",
      "file_size": 1024
    }
  ],
  "opportunities_data": {
    "skills": ["Programming", "Leadership"],
    "interests": ["AI", "Web Development"],
    "experience_level": "Intermediate",
    "preferred_roles": ["Developer", "Manager"]
  }
}
```

**Response Format**:
```json
{
  "response": "Ashabot's generated response text",
  "suggestions": ["Suggested follow-up question 1", "Question 2"],
  "opportunities": [
    {
      "title": "Job Opportunity",
      "description": "Description of opportunity",
      "url": "https://example.com/job"
    }
  ]
}
```

### GET `/api/health`

Health check endpoint.

**Response**:
```json
{
  "status": "ok",
  "service": "Ashabot API"
}
```

## Supported File Types

- **Documents**: PDF, DOC, DOCX, TXT
- **Spreadsheets**: XLS, XLSX (basic support)
- **Images**: JPG, JPEG, PNG (basic support)

## Setup and Installation

1. Clone the repository
2. Install dependencies:
   ```
   pip install -r requirements.txt
   ```
3. Download the spaCy model:
   ```
   python -m spacy download en_core_web_sm
   ```
4. Set your Gemini API key as an environment variable:
   ```
   export GEMINI_API_KEY="your-api-key"
   ```
5. Run the server:
   ```
   python app.py
   ```
   
For production deployment:
```
gunicorn app:app
```

## Environment Variables

- `GEMINI_API_KEY`: Your Google Gemini API key
- `PORT`: Port number (default: 5000)

## File Processing Details

1. Files uploaded to the API are base64-decoded and saved temporarily
2. Text extraction happens based on file type:
   - PDFs: Text extracted using PyPDF2
   - DOCX: Text extracted using python-docx
   - TXT: Read directly
   - Images: Placeholder for OCR (add your OCR solution)
   - Spreadsheets: Placeholder (add pandas integration for full support)
3. Extracted content is provided to the Gemini AI for processing

## Bias Detection System

The API contains a system to detect and address gender bias in incoming messages:

1. Uses spaCy for natural language processing
2. Detects patterns related to gender stereotypes
3. Provides educational responses with suggestions for reframing

## Frontend Integration

This API is designed to work with any frontend. The expected flow is:

1. Frontend starts a session with unique ID
2. User sends messages (with optional files)
3. Frontend encodes files as base64
4. API processes input and returns response
5. Frontend displays response, suggestions, and opportunities

## Docker Support

A Dockerfile is provided for containerization:

```bash
docker build -t ashabot-api .
docker run -p 5000:5000 -e GEMINI_API_KEY="your-api-key" ashabot-api
```

## License

MIT

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
