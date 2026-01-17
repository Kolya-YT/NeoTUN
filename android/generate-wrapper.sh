#!/bin/bash
# Generate Gradle Wrapper
cd "$(dirname "$0")"

# Download gradle wrapper jar if it doesn't exist
if [ ! -f "gradle/wrapper/gradle-wrapper.jar" ]; then
    echo "Downloading Gradle Wrapper..."
    mkdir -p gradle/wrapper
    
    # Download gradle wrapper jar from official source
    curl -L -o gradle/wrapper/gradle-wrapper.jar \
        "https://github.com/gradle/gradle/raw/v8.4.0/gradle/wrapper/gradle-wrapper.jar"
    
    echo "Gradle Wrapper downloaded successfully"
fi

# Make gradlew executable
chmod +x gradlew

echo "Gradle Wrapper setup complete"