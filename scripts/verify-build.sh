#!/bin/bash

# NeoTUN Build Verification Script
# This script verifies that the project structure and dependencies are correct for CI/CD

set -e

echo "🔍 NeoTUN Build Verification"
echo "=========================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print status
print_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓${NC} $2"
    else
        echo -e "${RED}✗${NC} $2"
        exit 1
    fi
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Check project structure
echo "📁 Checking project structure..."

# Check for required directories
[ -d ".github/workflows" ] && print_status 0 "GitHub Actions workflows directory exists" || print_status 1 "Missing .github/workflows directory"
[ -d "android" ] && print_status 0 "Android project directory exists" || print_status 1 "Missing android directory"
[ -d "windows" ] && print_status 0 "Windows project directory exists" || print_status 1 "Missing windows directory"
[ -d "shared" ] && print_status 0 "Shared code directory exists" || print_status 1 "Missing shared directory"

# Check for required files
[ -f ".gitmodules" ] && print_status 0 "Git submodules configuration exists" || print_status 1 "Missing .gitmodules file"
[ -f "android/build.gradle.kts" ] && print_status 0 "Android build configuration exists" || print_status 1 "Missing android/build.gradle.kts"
[ -f "windows/NeoTUN.sln" ] && print_status 0 "Windows solution file exists" || print_status 1 "Missing windows/NeoTUN.sln"

# Check GitHub Actions workflows
echo ""
echo "🔧 Checking GitHub Actions workflows..."

[ -f ".github/workflows/android.yml" ] && print_status 0 "Android CI workflow exists" || print_status 1 "Missing Android CI workflow"
[ -f ".github/workflows/windows.yml" ] && print_status 0 "Windows CI workflow exists" || print_status 1 "Missing Windows CI workflow"
[ -f ".github/workflows/release.yml" ] && print_status 0 "Release workflow exists" || print_status 1 "Missing Release workflow"

# Check Android project structure
echo ""
echo "📱 Checking Android project..."

[ -f "android/gradlew" ] && print_status 0 "Gradle wrapper exists" || print_status 1 "Missing Gradle wrapper"
[ -f "android/app/build.gradle.kts" ] && print_status 0 "Android app build file exists" || print_status 1 "Missing Android app build file"
[ -f "android/app/src/main/AndroidManifest.xml" ] && print_status 0 "Android manifest exists" || print_status 1 "Missing Android manifest"

# Check if gradlew is executable
if [ -f "android/gradlew" ]; then
    if [ -x "android/gradlew" ]; then
        print_status 0 "Gradle wrapper is executable"
    else
        print_warning "Gradle wrapper is not executable (will be fixed in CI)"
    fi
fi

# Check Windows project structure
echo ""
echo "🪟 Checking Windows project..."

[ -f "windows/NeoTUN.Windows/NeoTUN.Windows.csproj" ] && print_status 0 "Windows project file exists" || print_status 1 "Missing Windows project file"
[ -f "windows/NeoTUN.Core/NeoTUN.Core.csproj" ] && print_status 0 "Core project file exists" || print_status 1 "Missing Core project file"

# Check for .NET version
if command -v dotnet &> /dev/null; then
    DOTNET_VERSION=$(dotnet --version)
    if [[ $DOTNET_VERSION == 8.* ]]; then
        print_status 0 ".NET 8 is installed ($DOTNET_VERSION)"
    else
        print_warning ".NET 8 not found, found version: $DOTNET_VERSION"
    fi
else
    print_warning ".NET SDK not found (required for local Windows builds)"
fi

# Check for Go
echo ""
echo "🐹 Checking Go installation..."

if command -v go &> /dev/null; then
    GO_VERSION=$(go version | awk '{print $3}')
    if [[ $GO_VERSION == go1.21* ]]; then
        print_status 0 "Go 1.21 is installed ($GO_VERSION)"
    else
        print_warning "Go 1.21 not found, found version: $GO_VERSION"
    fi
else
    print_warning "Go not found (required for Xray builds)"
fi

# Check submodule status
echo ""
echo "📦 Checking Git submodules..."

if [ -d "xray-core" ]; then
    if [ -f "xray-core/main/main.go" ]; then
        print_status 0 "Xray-core submodule is properly initialized"
    else
        print_warning "Xray-core submodule exists but appears incomplete"
        echo "   Run: git submodule update --init --recursive"
    fi
else
    print_warning "Xray-core submodule not found"
    echo "   Run: git submodule update --init --recursive"
fi

# Check for required secrets documentation
echo ""
echo "🔐 Checking secrets documentation..."

if grep -q "ANDROID_KEYSTORE_BASE64" README.md; then
    print_status 0 "Android signing secrets documented"
else
    print_warning "Android signing secrets not documented in README"
fi

if grep -q "WINDOWS_CERTIFICATE_BASE64" README.md; then
    print_status 0 "Windows signing secrets documented"
else
    print_warning "Windows signing secrets not documented in README"
fi

# Validate workflow syntax (basic check)
echo ""
echo "✅ Checking workflow syntax..."

for workflow in .github/workflows/*.yml; do
    if [ -f "$workflow" ]; then
        # Basic YAML syntax check
        if command -v python3 &> /dev/null; then
            python3 -c "import yaml; yaml.safe_load(open('$workflow'))" 2>/dev/null
            if [ $? -eq 0 ]; then
                print_status 0 "$(basename $workflow) has valid YAML syntax"
            else
                print_status 1 "$(basename $workflow) has invalid YAML syntax"
            fi
        else
            print_warning "Python3 not available for YAML validation"
        fi
    fi
done

# Summary
echo ""
echo "📋 Build Verification Summary"
echo "============================"
echo ""
echo "✅ Project structure is ready for CI/CD"
echo "🚀 GitHub Actions workflows are configured"
echo "📱 Android build configuration is complete"
echo "🪟 Windows build configuration is complete"
echo ""
echo "Next steps:"
echo "1. Configure GitHub Secrets for code signing"
echo "2. Initialize Xray-core submodule: git submodule update --init --recursive"
echo "3. Test local builds before pushing to main branch"
echo "4. Create a release tag (v1.0.0) to trigger release pipeline"
echo ""
echo "For detailed instructions, see docs/CI_CD_GUIDE.md"