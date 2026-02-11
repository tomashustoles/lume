#!/bin/bash

# Setup script for xcconfig API key configuration
# This script helps configure the Xcode project to use Config.xcconfig

set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_FILE="$PROJECT_DIR/Lume.xcodeproj/project.pbxproj"
CONFIG_FILE="$PROJECT_DIR/Config.xcconfig"

echo "🔧 Setting up xcconfig for Lume project..."

# Check if Config.xcconfig exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "❌ Error: Config.xcconfig not found at $CONFIG_FILE"
    echo "   Please ensure Config.xcconfig is in the project root directory"
    exit 1
fi

echo "✅ Found Config.xcconfig"

# Check if project file exists
if [ ! -f "$PROJECT_FILE" ]; then
    echo "❌ Error: Xcode project not found at $PROJECT_FILE"
    exit 1
fi

echo "✅ Found Xcode project"

# Check if Config.xcconfig is already referenced
if grep -q "Config.xcconfig" "$PROJECT_FILE"; then
    echo "⚠️  Config.xcconfig is already referenced in the project"
    echo "   You may need to configure it in Xcode manually"
else
    echo "ℹ️  Config.xcconfig needs to be added to Xcode project"
    echo "   Please add it manually in Xcode (see instructions below)"
fi

echo ""
echo "📋 Next steps (must be done in Xcode):"
echo ""
echo "1. Open Lume.xcodeproj in Xcode"
echo "2. Right-click the project in the navigator → 'Add Files to Lume...'"
echo "3. Select Config.xcconfig (uncheck 'Copy items if needed')"
echo "4. Select the project → Target 'Lume' → Build Settings"
echo "5. Search for 'Configuration File'"
echo "6. For Debug and Release, set to 'Config.xcconfig'"
echo "7. Search for 'INFOPLIST_KEY' and add:"
echo "   INFOPLIST_KEY_GEMINI_API_KEY = \$(GEMINI_API_KEY)"
echo ""
echo "8. Create Config.local.xcconfig:"
echo "   cp Config.local.xcconfig.example Config.local.xcconfig"
echo "9. Edit Config.local.xcconfig and add your API key"
echo ""
echo "✅ Setup instructions complete!"
