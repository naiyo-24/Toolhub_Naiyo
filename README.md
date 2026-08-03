# Toolhub Naiyo

Toolhub Naiyo is a comprehensive all-in-one utility application designed to streamline daily tasks, business operations, and student utilities. Built with a robust modern technology stack, it provides seamless cross-platform functionality via a Flutter mobile application, a React/Vite web interface, and a powerful FastAPI Python backend.

## 🌟 Key Features

### 💼 Business Toolkit
A powerful suite of tools designed for small businesses and freelancers.
- **Invoice Generator**: Create professional A4 invoices with dynamic tax (GST) and discount calculations. Includes support for automated "amount in words" generation.
- **POS Billing**: Rapid thermal receipt generation for retail checkouts with barcode scanning support.
- **Quotation Generator**: Quickly draft and share customized quotes and estimates with clients, fully synced with your inventory.
- **Inventory Management**: Track stock levels, set MRP/selling prices, and organize raw materials vs. finished goods.
- **Business Card Generator**: Design and export professional business cards instantly.

### 🎓 Student Toolkit
Tools to simplify academic life.
- **CGPA Calculator**: Support for up to 8 semesters with dynamic add/remove functionality. Includes real-time percentage conversions based on MAKAUT university guidelines.

### 📝 Form Builder
- Create custom forms dynamically.
- Collect and manage responses directly within the app.

### 🛠 Internet & Utility Tools
- **URL Shortener**: Quickly condense long URLs for easy sharing.
- **File Sharing & Management**: Easily rename files, extract ZIP archives, and share documents securely.
- **Currency & Finance Calculators**: Convert travel currencies and calculate GST/Tax brackets.

## 🏗 Technology Stack

- **Mobile App**: Flutter (Dart)
  - *State Management*: Riverpod
  - *Routing*: GoRouter
  - *Networking*: Dio
  - *Styling*: Google Fonts (SpaceGrotesk, ArchivoBlack, GeneralSans)
  - *Native Integrations*: Mobile Scanner (Barcode/QR), PDF/Printing, Image Cropper/Picker.
- **Backend API**: FastAPI (Python)
  - *Database*: SQLAlchemy
  - *PDF Generation*: ReportLab
- **Web Frontend**: React (TypeScript / TSX)
  - *Build Tool*: Vite

## 🚀 Getting Started

### Prerequisites
Make sure you have the following installed:
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (>=3.0.0)
- [Python 3.9+](https://www.python.org/downloads/) (for the backend)
- [Node.js](https://nodejs.org/) (for the web frontend)

### Running the Flutter App

1. Navigate to the app directory:
   ```bash
   cd Toolhub_Naiyo
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run the application:
   ```bash
   flutter run
   ```

### Running the Backend

1. Navigate to the backend directory:
   ```bash
   cd Toolhub_Naiyo_Backend
   ```
2. Install Python dependencies:
   ```bash
   pip install -r requirements.txt
   ```
3. Start the FastAPI server:
   ```bash
   uvicorn main:app --reload --host 0.0.0.0 --port 8000
   ```

### Running the Web Application

1. Navigate to the web directory:
   ```bash
   cd Toolhub_Naiyo_Website
   ```
2. Install NPM dependencies:
   ```bash
   npm install
   ```
3. Start the development server:
   ```bash
   npm run dev
   ```

## 📱 App Architecture Highlights
- **Modular Design**: Features are encapsulated within a `features/` directory (e.g., `business_toolkit`, `student_toolkit`, `internet_tools`).
- **Real-time Sync**: Barcode scanning seamlessly integrates with the inventory backend to instantly pull product pricing, HSN codes, and GST brackets.
- **Offline Capabilities**: Uses `shared_preferences` for localized app state and user profile caching.

## 📄 License
This project is proprietary and confidential.
