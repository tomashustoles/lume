# Lume - Art Recognition App

A beautiful app that uses AI to recognize and learn about artwork.

## 🔐 Setting Up API Keys

This app requires a Google Gemini API key to function. **Never commit your API key to version control!**

### Quick Setup

1. **Copy the template file:**
   ```bash
   cp Secrets.xcconfig.template Secrets.xcconfig
   ```

2. **Get your Gemini API key:**
   - Go to [Google AI Studio](https://aistudio.google.com/app/apikey)
   - Create or select a project
   - Click "Create API Key"
   - Copy the generated key

3. **Add your key to Secrets.xcconfig:**
   ```
   GEMINI_API_KEY = your_actual_api_key_here
   ```

4. **Configure Xcode (if needed):**
   - Open your project in Xcode
   - Select the project in the navigator
   - Go to the "Info" tab
   - Under "Configurations", set `Secrets.xcconfig` for both Debug and Release

5. **Build and run!**

### Alternative: Environment Variable

You can also set the API key as an environment variable:

1. In Xcode, go to Product > Scheme > Edit Scheme
2. Select "Run" on the left
3. Go to the "Arguments" tab
4. Under "Environment Variables", add:
   - Name: `GEMINI_API_KEY`
   - Value: `your_actual_api_key_here`

## 🔒 Security Notes

- ✅ `Secrets.xcconfig` is in `.gitignore` and won't be committed
- ✅ API key is loaded at runtime from secure configuration
- ✅ Template file is provided for easy setup
- ⚠️ Never hardcode API keys in source files
- ⚠️ Rotate your API key if it's ever exposed

## 📱 Features

- Real-time camera artwork recognition
- AI-powered artwork analysis
- History of scanned artworks
- Beautiful UI with animations
- Subscription management

## 🛠 Development

- Built with SwiftUI
- Uses Google Gemini 2.5 Flash API
- SwiftData for local storage
- StoreKit for subscriptions

## 📄 License

[Your License Here]
