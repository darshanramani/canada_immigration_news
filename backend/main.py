import os
import json
from fastapi import FastAPI
from pydantic import BaseModel
from dotenv import load_dotenv
import feedparser
import google.generativeai as genai
import firebase_admin
from firebase_admin import credentials, firestore

load_dotenv()

# ---------------- GEMINI ----------------

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")

if GEMINI_API_KEY:
    genai.configure(api_key=GEMINI_API_KEY)

model = genai.GenerativeModel("gemini-2.5-flash")

# ---------------- FIREBASE ----------------



firebase_key_json = os.getenv("FIREBASE_KEY_JSON")

if firebase_key_json:
    firebase_key_dict = json.loads(firebase_key_json)
    cred = credentials.Certificate(firebase_key_dict)
else:
    cred = credentials.Certificate("firebase_key.json")

firebase_admin.initialize_app(cred)

db = firestore.client()

# ---------------- FASTAPI ----------------

app = FastAPI(
    title="Canada Immigration Daily API",
    version="1.0.0",
)

# ---------------- RSS FEEDS ----------------

RSS_FEEDS = [
    "https://www.canadavisa.com/news/rss.html",
    # "https://www.cicnews.com/feed",
]

# ---------------- REQUEST MODEL ----------------

class SummaryRequest(BaseModel):
    title: str
    content: str

# ---------------- HOME ----------------

@app.get("/")
def home():
    return {
        "message": "Canada Immigration Daily API running."
    }

# ---------------- HEALTH ----------------

@app.get("/health")
def health_check():
    return {
        "status": "ok"
    }

# ---------------- AI SUMMARY ----------------

@app.post("/generate-summary")
def generate_summary(request: SummaryRequest):

    prompt = f"""
    Summarize this Canada immigration update in simple English.

    Rules:
    - Use 3 short bullet points
    - Beginner friendly
    - No legal advice
    - Do not add extra facts

    Title:
    {request.title}

    Content:
    {request.content}
    """

    response = model.generate_content(prompt)

    return {
        "title": request.title,
        "summary": response.text
    }

def detect_category(title: str, summary: str = "") -> str:
    text = f"{title} {summary}".lower()

    if "express entry" in text or "crs" in text or "invitation to apply" in text:
        return "Express Entry"

    if "study permit" in text or "international student" in text or "student" in text:
        return "Study Permit"

    if "work permit" in text or "foreign worker" in text or "lmia" in text:
        return "Work Permit"

    if "pnp" in text or "provincial nominee" in text or "nominee program" in text:
        return "PNP"

    if "visitor visa" in text or "temporary resident visa" in text:
        return "Visitor Visa"

    if "permanent residence" in text or "permanent resident" in text or "pr" in text:
        return "Permanent Residence"

    return "General"

# ---------------- FETCH + AI + FIRESTORE ----------------

@app.get("/sync-news")
def sync_news():

    uploaded_articles = []
    skipped_articles = []

    for feed_url in RSS_FEEDS:

        feed = feedparser.parse(feed_url)

        for entry in feed.entries[:1]:

            title = entry.get("title", "")
            link = entry.get("link", "")
            summary = entry.get("summary", "")

            existing_docs = (
                db.collection("news")
                .where("sourceUrl", "==", link)
                .limit(1)
                .get()
            )

            if len(existing_docs) > 0:
                skipped_articles.append({
                    "title": title,
                    "reason": "Already exists"
                })
                continue

            prompt = f"""
            Summarize this Canada immigration news in simple English.

            Rules:
            - Use 3 short bullet points
            - Beginner friendly
            - No legal advice
            - Do not add extra facts

            Title:
            {title}

            Content:
            {summary}
            """

            try:
                ai_summary = summary[:500]
                # response = model.generate_content(prompt)
                # ai_summary = response.text


            except Exception as e:
                ai_summary = f"AI generation failed: {str(e)}"

            news_data = {
                "title": title,
                "category": detect_category(title, summary),
                "date": firestore.SERVER_TIMESTAMP,
                "summary": ai_summary,
                "sourceUrl": link,
                "isImportant": False,
            }

            db.collection("news").add(news_data)

            uploaded_articles.append({
                "title": title,
                "uploaded": True
            })

    return {
        "success": True,
        "message": "News sync completed successfully.",
        "uploaded_count": len(uploaded_articles),
        "skipped_count": len(skipped_articles),
        "uploaded_articles": uploaded_articles,
        "skipped_articles": skipped_articles,
    }