#!/bin/bash

# Quick setup script for Lume API keys
# This helps you quickly configure the API key

echo "🔐 Lume API Key Setup"
echo "===================="
echo ""

# Check if APIKeys.plist already exists
if [ -f "APIKeys.plist" ]; then
    echo "✅ APIKeys.plist already exists"
    echo ""
    read -p "Do you want to recreate it? (y/n): " recreate
    if [ "$recreate" != "y" ]; then
        echo "Keeping existing APIKeys.plist"
        exit 0
    fi
fi

echo "This script will help you create APIKeys.plist"
echo ""
echo "📋 You have two options:"
echo "1. Use environment variable (recommended for development)"
echo "2. Create APIKeys.plist file"
echo ""

read -p "Which method do you prefer? (1/2): " method

if [ "$method" == "1" ]; then
    echo ""
    echo "✨ Environment Variable Method"
    echo "=============================="
    echo ""
    echo "Follow these steps in Xcode:"
    echo "1. Product > Scheme > Edit Scheme..."
    echo "2. Select 'Run' > 'Arguments' tab"
    echo "3. Add Environment Variable:"
    echo "   Name: GEMINI_API_KEY"
    echo "   Value: [Your API Key]"
    echo ""
    echo "Get your API key from: https://aistudio.google.com/app/apikey"
    echo ""
elif [ "$method" == "2" ]; then
    echo ""
    read -p "Enter your Gemini API key: " api_key
    
    if [ -z "$api_key" ]; then
        echo "❌ No API key provided. Exiting."
        exit 1
    fi
    
    # Create APIKeys.plist
    cat > APIKeys.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>GEMINI_API_KEY</key>
	<string>$api_key</string>
</dict>
</plist>
EOF
    
    echo ""
    echo "✅ APIKeys.plist created successfully!"
    echo ""
    echo "Next steps:"
    echo "1. Add APIKeys.plist to your Xcode project"
    echo "2. Make sure it's added to your app target"
    echo "3. Build and run!"
    echo ""
else
    echo "❌ Invalid option. Please run the script again and choose 1 or 2."
    exit 1
fi

echo "🚀 You're all set! Happy coding!"
