#!/bin/bash

# OllamaTrauma Java Unix/Linux/macOS Wrapper
# Automatically detects Java and runs the application

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
JAR_FILE="$SCRIPT_DIR/ollama-trauma.jar"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RESET='\033[0m'

# Function to print colored messages
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${RESET}"
}

# Check if we're running from the build directory
if [ ! -f "$JAR_FILE" ]; then
    JAR_FILE="$SCRIPT_DIR/target/ollama-trauma.jar"
fi

# Still not found? Try the Gradle build directory
if [ ! -f "$JAR_FILE" ]; then
    JAR_FILE="$SCRIPT_DIR/build/libs/ollama-trauma.jar"
fi

# Function to find Java
find_java() {
    if [ -n "$JAVA_HOME" ]; then
        JAVA_EXE="$JAVA_HOME/bin/java"
        if [ -x "$JAVA_EXE" ]; then
            print_message "$GREEN" "Using Java from JAVA_HOME: $JAVA_EXE"
            return 0
        else
            print_message "$YELLOW" "JAVA_HOME is set but java executable not found: $JAVA_EXE"
        fi
    fi
    
    if command -v java &> /dev/null; then
        JAVA_EXE="java"
        print_message "$GREEN" "Using Java from PATH: $(which java)"
        return 0
    fi
    
    # Try common Java installation locations
    local java_locations=(
        "/usr/bin/java"
        "/usr/local/bin/java"
        "/opt/java/bin/java"
        "/Library/Java/JavaVirtualMachines/*/Contents/Home/bin/java"
        "/usr/lib/jvm/*/bin/java"
    )
    
    for location in "${java_locations[@]}"; do
        if [ -x "$location" ]; then
            JAVA_EXE="$location"
            print_message "$GREEN" "Found Java at: $JAVA_EXE"
            return 0
        fi
    done
    
    return 1
}

# Check Java version
check_java_version() {
    local java_version_output
    java_version_output=$("$JAVA_EXE" -version 2>&1)
    
    if [ $? -ne 0 ]; then
        print_message "$RED" "Error: Unable to determine Java version"
        return 1
    fi
    
    print_message "$CYAN" "Java version check:"
    echo "$java_version_output" | head -3
    
    # Extract major version number
    local version_line=$(echo "$java_version_output" | head -1)
    local version_number
    
    if [[ $version_line =~ \"1\.([0-9]+)\. ]]; then
        version_number=${BASH_REMATCH[1]}
    elif [[ $version_line =~ \"([0-9]+)\. ]]; then
        version_number=${BASH_REMATCH[1]}
    else
        print_message "$YELLOW" "Warning: Could not parse Java version"
        return 0
    fi
    
    if [ "$version_number" -lt 11 ]; then
        print_message "$RED" "Error: Java 11 or later is required (found Java $version_number)"
        print_message "$CYAN" "Please install a newer version of Java:"
        echo "  - Oracle JDK: https://www.oracle.com/java/technologies/downloads/"
        echo "  - OpenJDK: https://openjdk.org/"
        echo "  - Adoptium: https://adoptium.net/"
        return 1
    fi
    
    return 0
}

# Main script execution
main() {
    print_message "$BLUE" "OllamaTrauma Java Cross-Platform Launcher"
    print_message "$BLUE" "=========================================="
    
    # Find Java
    if ! find_java; then
        print_message "$RED" "Error: Java not found"
        print_message "$CYAN" "Please install Java 11 or later and ensure it's in your PATH or set JAVA_HOME"
        print_message "$CYAN" "Installation options:"
        echo "  - Ubuntu/Debian: sudo apt install openjdk-11-jdk"
        echo "  - CentOS/RHEL: sudo dnf install java-11-openjdk-devel"
        echo "  - macOS: brew install openjdk@11"
        echo "  - Or download from: https://adoptium.net/"
        exit 1
    fi
    
    # Check Java version
    if ! check_java_version; then
        exit 1
    fi
    
    # Check if JAR file exists
    if [ ! -f "$JAR_FILE" ]; then
        print_message "$RED" "Error: JAR file not found: $JAR_FILE"
        echo
        print_message "$CYAN" "Please build the project first:"
        echo "  mvn clean package    (for Maven)"
        echo "  gradle shadowJar     (for Gradle)"
        echo
        exit 1
    fi
    
    # Set JVM arguments for better performance and cross-platform compatibility
    JVM_ARGS="-XX:+UseG1GC -Xms256m -Xmx1g -Dfile.encoding=UTF-8"
    
    # Enable colored output
    JVM_ARGS="$JVM_ARGS -Dforce.color=true"
    
    # Add JVM arguments for better native integration
    case "$(uname -s)" in
        Darwin*)
            JVM_ARGS="$JVM_ARGS -Djava.awt.headless=true -Dapple.awt.UIElement=true"
            ;;
        Linux*)
            JVM_ARGS="$JVM_ARGS -Djava.awt.headless=true"
            ;;
    esac
    
    # Handle Ansible mode
    if [ "$1" = "--ansible" ]; then
        export ANSIBLE_STDOUT_CALLBACK=json
        export ANSIBLE_MAIN_CHOICE=1
        export ANSIBLE_SKIP_DEPS=true
        shift
    fi
    
    # Set environment variables for cross-platform behavior
    if [ -z "$ANSIBLE_STDOUT_CALLBACK" ] && [ -t 1 ]; then
        # Interactive mode - enable colors
        export FORCE_COLOR=1
    fi
    
    print_message "$GREEN" "Starting OllamaTrauma Java..."
    echo "JAR: $JAR_FILE"
    echo "Java: $JAVA_EXE"
    echo "Args: $*"
    echo
    
    # Run the application
    "$JAVA_EXE" $JVM_ARGS -jar "$JAR_FILE" "$@"
    
    # Capture exit code
    local exit_code=$?
    
    if [ $exit_code -ne 0 ]; then
        echo
        print_message "$RED" "Application exited with code: $exit_code"
    else
        print_message "$GREEN" "Application completed successfully"
    fi
    
    exit $exit_code
}

# Handle command line help
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "OllamaTrauma Java Cross-Platform Launcher"
    echo "Usage: $0 [OPTIONS] [JAVA_APP_ARGS...]"
    echo
    echo "Options:"
    echo "  --help, -h     Show this help message"
    echo "  --ansible      Enable Ansible integration mode"
    echo
    echo "Java Application Arguments:"
    echo "  --config-dir DIR    Configuration directory path"
    echo "  --model MODEL       Set selected model"
    echo "  --install-only      Install dependencies and Ollama only"
    echo "  --quiet            Suppress non-critical output"
    echo "  --version          Show version information"
    echo
    echo "Environment Variables:"
    echo "  JAVA_HOME          Java installation directory"
    echo "  FORCE_COLOR        Enable colored output (1 to enable)"
    echo
    echo "Examples:"
    echo "  $0                              # Run interactively"
    echo "  $0 --model llama2               # Run with specific model"
    echo "  $0 --ansible --install-only     # Ansible mode, install only"
    echo
    exit 0
fi

# Check if we're being sourced or executed
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
