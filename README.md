# Voice Finance Tracker

An advanced, AI-powered personal finance tracker featuring real-time visual analytics, custom budget limit alerts, an SMS parsing sandbox, voice assistant transaction creation, and a personalized AI Financial Coach. 

The application is built on a modern stack featuring a **FastAPI** backend with **MongoDB** for database persistence, and a premium **Flutter** frontend compiled for the web.

---

## 🌟 Key Features

* **Voice-to-Transaction Engine:** Create transaction items directly by speaking or entering natural language commands (e.g., *"spent 450 rupees on dinner yesterday"*). The backend parses these prompts, identifies the amount, category, type (income vs. expense), and relative date, then displays an interactive confirmation dialog.
* **SMS Sandbox Simulator:** Paste bank SMS alerts (e.g., *"Rs. 15,000 credited to account for Freelance"*) to test and review parsed transaction details (detected merchant, bank, amount, transaction type).
* **Interactive Dashboard:** Beautiful dark-themed analytics console featuring:
  - Custom radial gauge visualizing financial health scores.
  - Interactive income vs. expense progress widgets.
  - Categorized breakdowns and recent transaction feeds.
* **Budget & Limits Management:** Configure monthly category-specific spending caps. The UI highlights limits with color-coded alerts (green for healthy, red for exceeded) and tracks remaining allowance metrics in real-time.
* **AI Financial Coach:** Retrieves customized reports, health scores, risk assessments (Low, Medium, High), action steps, and long-term financial strategies powered by the backend transaction history.
* **Secure JWT Authentication:** Token-based secure user sessions protecting all financial endpoints.

---

## 🛠️ Architecture & Technology Stack

### Backend
* **Runtime:** Python 3.10+
* **Framework:** FastAPI (high-performance web framework)
* **Database:** MongoDB (NoSQL database for flexible transaction schemas)
* **Libraries:** Pydantic (data validation), PyJWT (token verification), Uvicorn (ASGI server)

### Frontend
* **Framework:** Flutter (Web)
* **State Management:** `Provider` (architectural state management pattern)
* **UI Design:** HSL-tailored Premium Dark Theme, Custom Painters (for gauges), Google Fonts integration (`Inter`)
* **Libraries:** `fl_chart` (data visualizations), `intl` (date/currency formatting), `record` (microphone audio recording)

---

## 📁 Directory Structure

```text
Voice_App/
│
├── backend/                         # FastAPI backend service
│   ├── app/
│   │   ├── auth.py                  # JWT Auth logic & hashing utilities
│   │   ├── database.py              # MongoDB client initialization
│   │   ├── logger.py                # Logger configuration
│   │   ├── main.py                  # API server core and CORS configuration
│   │   ├── models.py                # Database schemas & documents
│   │   ├── schemas.py               # Request/Response Pydantic validation
│   │   └── transactions.py          # Transactions CRUD, SMS parsing, & voice simulator routes
│   ├── .env                         # Environment variables config
│   ├── requirements.txt             # Python packages listing
│   └── venv/                        # Python virtual environment
│
├── frontend/                        # Flutter web client
│   ├── lib/
│   │   ├── models/                  # App models (Transaction, Budget, AICoach)
│   │   ├── providers/               # State providers (AuthProvider, FinanceProvider)
│   │   ├── services/                # API Client service wrapper
│   │   ├── views/                   # View components (Auth, Dashboard, Transactions, Voice, Budgets, Coach, SMS Sandbox)
│   │   └── main.dart                # MultiProvider routing & MaterialApp entry
│   ├── pubspec.yaml                 # Flutter project dependency configuration
│   └── web/                         # Flutter web resources & index templates
```

---

## 🚀 Setup & Execution

### 1. Prerequisite Checklist
* **Backend:** Python 3.10+, running MongoDB instance.
* **Frontend:** Flutter SDK (configured for Web).
* **Browsers:** Chrome or Chromium browser.

---

### 2. Backend Setup
1. Navigate to the backend directory:
   ```bash
   cd backend
   ```
2. Create and configure your `.env` file (ensure MongoDB connection URL and OpenAI keys are populated):
   ```ini
   MONGO_URI=mongodb://localhost:27017
   DATABASE_NAME=voice_finance
   JWT_SECRET=your_super_secret_jwt_key
   OPENAI_API_KEY=your_openai_api_key
   ```
3. Initialize the Python virtual environment and install dependencies:
   ```bash
   python3 -m venv venv
   source venv/bin/activate
   pip install -r requirements.txt
   ```
4. Start the FastAPI development server:
   ```bash
   uvicorn app.main:app --host 127.0.0.1 --port 8000 --reload
   ```

---

### 3. Frontend Setup
1. Navigate to the frontend directory:
   ```bash
   cd ../frontend
   ```
2. Install the necessary packages:
   ```bash
   flutter pub get
   ```
3. Compile and launch the app in Chrome:
   ```bash
   flutter run -d chrome --web-port 8080
   ```
4. Open your browser and navigate to `http://localhost:8080`.

---

## 🎨 Theme & Color System

To maintain maximum UI consistency and avoid platform compilation issues, the design avoids default presets and relies on the following custom palette:
- **Backgrounds:** `Color(0xFF090D1A)` (Base Dark), `Color(0xFF131C33)` (Cards/Containers)
- **Primary Color:** `Color(0xFF6366F1)` (Indigo Accent)
- **Success/Income:** `Color(0xFF10B981)` (Emerald/Green indicator)
- **Warning/Expense:** `Colors.redAccent`
- **Text:** `Colors.white` (Primary), `Color(0xFF94A3B8)` (Secondary/Muted)
