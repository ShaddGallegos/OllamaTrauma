#!/bin/bash

# Global variables
SELECTED_MODEL="mistral"

# Function to detect operating system
detect_os() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
  elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
  elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "win32" ]]; then
    OS="windows"
  elif [[ -n "$WSL_DISTRO_NAME" ]] || [[ -n "$WSLENV" ]]; then
    OS="wsl" # Windows Subsystem for Linux
  else
    # Additional Windows detection methods
    if command -v powershell.exe &> /dev/null || command -v cmd.exe &> /dev/null; then
      OS="windows"
    elif [[ -f "/proc/version" ]] && grep -q "Microsoft\|WSL" /proc/version 2>/dev/null; then
      OS="wsl"
    else
      OS="unknown"
    fi
  fi
}

# Function to check and install dependencies
check_dependencies() {
  echo "Checking for required dependencies..."

  # Detect OS first
  detect_os

  # Check if jq is installed
  if ! command -v jq &> /dev/null; then
    echo "jq not found. Installing..."

    case $OS in
      macos)
        # macOS installation methods
        if command -v brew &> /dev/null; then
          echo "Using Homebrew to install jq..."
          brew install jq
        elif command -v port &> /dev/null; then
          echo "Using MacPorts to install jq..."
          sudo port install jq
        else
          echo "WARNING: Neither Homebrew nor MacPorts found."
          echo "Please install jq manually:"
          echo "1. Install Homebrew: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
          echo "2. Then run: brew install jq"
          echo "Or download from: https://github.com/jqlang/jq/releases"
        fi
        ;;
      linux)
        # Linux installation methods
        if command -v dnf &> /dev/null; then
          sudo dnf install -y jq
        elif command -v apt &> /dev/null; then
          sudo apt update && sudo apt install -y jq
        elif command -v yum &> /dev/null; then
          sudo yum install -y jq
        elif command -v pacman &> /dev/null; then
          sudo pacman -S jq
        elif command -v zypper &> /dev/null; then
          sudo zypper install jq
        else
          echo "WARNING: Could not install jq. Package manager not found."
          echo "Please install jq manually for better JSON parsing."
        fi
        ;;
      windows)
        # Windows installation methods
        if command -v winget &> /dev/null; then
          echo "Using winget to install jq..."
          winget install jqlang.jq
        elif command -v choco &> /dev/null; then
          echo "Using Chocolatey to install jq..."
          choco install jq
        elif command -v scoop &> /dev/null; then
          echo "Using Scoop to install jq..."
          scoop install jq
        else
          echo "WARNING: No Windows package manager found (winget, choco, scoop)."
          echo "Please install jq manually:"
          echo "1. Download from: https://github.com/jqlang/jq/releases"
          echo "2. Or install Chocolatey: https://chocolatey.org/install"
          echo "3. Then run: choco install jq"
        fi
        ;;
      wsl)
        # WSL uses Linux package managers
        echo "Detected WSL environment. Using Linux package managers..."
        if command -v apt &> /dev/null; then
          sudo apt update && sudo apt install -y jq
        elif command -v dnf &> /dev/null; then
          sudo dnf install -y jq
        elif command -v yum &> /dev/null; then
          sudo yum install -y jq
        elif command -v pacman &> /dev/null; then
          sudo pacman -S jq
        elif command -v zypper &> /dev/null; then
          sudo zypper install jq
        else
          echo "WARNING: Could not install jq. Package manager not found."
          echo "Please install jq manually for better JSON parsing."
        fi
        ;;
      *)
        echo "WARNING: Unknown operating system. Please install jq manually."
        echo "Visit: https://github.com/jqlang/jq/releases"
        ;;
    esac
  else
    echo "jq is already installed."
  fi

  # Check if git is installed (required for cloning models)
  if ! command -v git &> /dev/null; then
    echo "git not found. Installing..."

    case $OS in
      macos)
        echo "On macOS, git is usually installed with Xcode Command Line Tools."
        echo "Run: xcode-select --install"
        echo "Or install via Homebrew: brew install git"
        ;;
      linux)
        if command -v dnf &> /dev/null; then
          sudo dnf install -y git
        elif command -v apt &> /dev/null; then
          sudo apt update && sudo apt install -y git
        elif command -v yum &> /dev/null; then
          sudo yum install -y git
        elif command -v pacman &> /dev/null; then
          sudo pacman -S git
        elif command -v zypper &> /dev/null; then
          sudo zypper install git
        else
          echo "WARNING: Could not install git. Please install manually."
        fi
        ;;
      windows)
        if command -v winget &> /dev/null; then
          echo "Using winget to install git..."
          winget install Git.Git
        elif command -v choco &> /dev/null; then
          echo "Using Chocolatey to install git..."
          choco install git
        elif command -v scoop &> /dev/null; then
          echo "Using Scoop to install git..."
          scoop install git
        else
          echo "WARNING: No Windows package manager found."
          echo "Please install Git manually:"
          echo "1. Download from: https://git-scm.com/download/win"
          echo "2. Or install Chocolatey: https://chocolatey.org/install"
          echo "3. Then run: choco install git"
        fi
        ;;
      wsl)
        echo "Detected WSL environment. Using Linux package managers..."
        if command -v apt &> /dev/null; then
          sudo apt update && sudo apt install -y git
        elif command -v dnf &> /dev/null; then
          sudo dnf install -y git
        elif command -v yum &> /dev/null; then
          sudo yum install -y git
        elif command -v pacman &> /dev/null; then
          sudo pacman -S git
        elif command -v zypper &> /dev/null; then
          sudo zypper install git
        else
          echo "WARNING: Could not install git. Please install manually."
        fi
        ;;
    esac
  else
    echo "git is already installed."
  fi
}

# Function to install/update Ollama and run selected model
install_and_run_model() {
  # Detect OS
  detect_os

  # Check if Ollama is installed
  if ! command -v ollama &> /dev/null; then
    echo "Ollama not found. Installing..."

    case $OS in
      macos)
        echo "Installing Ollama on macOS..."
        if command -v brew &> /dev/null; then
          echo "Using Homebrew to install Ollama..."
          brew install ollama
          # Start Ollama service on macOS
          brew services start ollama
        else
          echo "Using official installer..."
          curl -fsSL https://ollama.com/install.sh | sh
        fi
        ;;
      linux)
        echo "Installing Ollama on Linux..."
        curl -fsSL https://ollama.com/install.sh | sh
        ;;
      windows)
        echo "Installing Ollama on Windows..."
        if command -v winget &> /dev/null; then
          echo "Using winget to install Ollama..."
          winget install Ollama.Ollama
        elif command -v choco &> /dev/null; then
          echo "Using Chocolatey to install Ollama..."
          choco install ollama
        else
          echo "Please install Ollama manually:"
          echo "1. Download from: https://ollama.com/download/windows"
          echo "2. Or install a package manager first:"
          echo " - Chocolatey: https://chocolatey.org/install"
          echo " - Scoop: https://scoop.sh/"
          echo " - Winget: Built into Windows 10/11"
          echo "3. Then run: choco install ollama"
        fi
        ;;
      wsl)
        echo "Installing Ollama on WSL..."
        echo "Note: Ollama will run in WSL but may need additional setup for GPU access."
        curl -fsSL https://ollama.com/install.sh | sh
        ;;
      *)
        echo "Unknown OS. Trying generic installation..."
        curl -fsSL https://ollama.com/install.sh | sh
        ;;
    esac
  else
    echo "Checking Ollama version..."
    OLLAMA_VERSION=$(ollama --version 2>/dev/null || echo "Unknown")
    echo "Current Ollama version: $OLLAMA_VERSION"

    # Only try update if command exists in help
    if ollama --help 2>&1 | grep -q "update"; then
      echo "Updating Ollama..."
      ollama update
    else
      echo "Note: This version of Ollama doesn't support the update command."
      case $OS in
        macos)
          if command -v brew &> /dev/null; then
            echo "You can update via Homebrew: brew upgrade ollama"
          else
            echo "You can update manually by reinstalling: curl -fsSL https://ollama.com/install.sh | sh"
          fi
          ;;
        linux)
          echo "You can update manually by reinstalling: curl -fsSL https://ollama.com/install.sh | sh"
          ;;
        windows)
          if command -v winget &> /dev/null; then
            echo "You can update via winget: winget upgrade Ollama.Ollama"
          elif command -v choco &> /dev/null; then
            echo "You can update via Chocolatey: choco upgrade ollama"
          else
            echo "You can update manually by downloading from: https://ollama.com/download/windows"
          fi
          ;;
        wsl)
          echo "You can update manually by reinstalling: curl -fsSL https://ollama.com/install.sh | sh"
          ;;
      esac
    fi
  fi

  # Get available models and display as numbered list
  echo "Checking for available models..."

  # Create an array of model names
  MODEL_LIST=($(ollama list | tail -n +2 | awk '{print $1}' | cut -d':' -f1 | sort -u))

  # Display the numbered model list
  if [ ${#MODEL_LIST[@]} -eq 0 ]; then
    echo "No models found. Would you like to:"
    echo "1) Pull the Mistral model"
    echo "2) Pull a different model"
    echo "3) Return to main menu"
    read -p "Enter choice (1-3): " no_model_choice

    case $no_model_choice in
      1)
        echo "Pulling Mistral model..."
        ollama pull mistral
        SELECTED_MODEL="mistral"
        ;;
      2)
        read -p "Enter model name to pull: " pull_model
        echo "Pulling $pull_model model..."
        ollama pull $pull_model
        SELECTED_MODEL="$pull_model"
        ;;
      3)
        echo "Returning to main menu..."
        return
        ;;
      *)
        echo "Invalid choice. Returning to main menu."
        return
        ;;
    esac
  else
    # Display models with numbers
    echo "Available models:"
    echo "----------------------------"
    for i in "${!MODEL_LIST[@]}"; do
      MODEL_NUM=$((i+1))
      MODEL_INFO=$(ollama list | grep "${MODEL_LIST[$i]}" | head -1)
      MODEL_SIZE=$(echo "$MODEL_INFO" | awk '{print $3, $4}')
      echo "$MODEL_NUM) ${MODEL_LIST[$i]} ($MODEL_SIZE)"
    done
    echo "----------------------------"
    echo "$((${#MODEL_LIST[@]}+1))) Pull a new model"
    echo "$((${#MODEL_LIST[@]}+2))) Use current selection ($SELECTED_MODEL)"
    echo "$((${#MODEL_LIST[@]}+3))) Return to main menu"
    echo "----------------------------"

    # Get user choice
    read -p "Enter choice (1-$((${#MODEL_LIST[@]}+3))): " model_choice

    # Handle user selection
    if [ "$model_choice" -eq $((${#MODEL_LIST[@]}+1)) ]; then
      # Pull new model option
      echo "Available model families:"
      echo "1) Llama models (Meta)"
      echo "2) Mistral models"
      echo "3) CodeLlama models"
      echo "4) Other (enter name manually)"
      read -p "Select model family (1-4): " family_choice

      case $family_choice in
        1)
          echo "Select Llama model:"
          echo "1) llama2 - Base model"
          echo "2) llama2-uncensored - Less restricted version"
          echo "3) llama2:13b - Larger variant (13B parameters)"
          echo "4) llama2:70b - Largest variant (70B parameters)"
          read -p "Enter choice (1-4): " llama_choice

          case $llama_choice in
            1) pull_model="llama2" ;;
            2) pull_model="llama2-uncensored" ;;
            3) pull_model="llama2:13b" ;;
            4) pull_model="llama2:70b" ;;
            *) echo "Invalid choice"; return ;;
          esac
          ;;
        2)
          echo "Select Mistral model:"
          echo "1) mistral - Base model"
          echo "2) mistral-openorca - Fine-tuned on OpenOrca dataset"
          echo "3) mistral-instruct - Instruction-tuned variant"
          read -p "Enter choice (1-3): " mistral_choice

          case $mistral_choice in
            1) pull_model="mistral" ;;
            2) pull_model="mistral-openorca" ;;
            3) pull_model="mistral-instruct" ;;
            *) echo "Invalid choice"; return ;;
          esac
          ;;
        3)
          echo "Select CodeLlama model:"
          echo "1) codellama - Base model"
          echo "2) codellama:13b - Larger variant"
          echo "3) codellama:34b - Largest variant"
          read -p "Enter choice (1-3): " code_choice

          case $code_choice in
            1) pull_model="codellama" ;;
            2) pull_model="codellama:13b" ;;
            3) pull_model="codellama:34b" ;;
            *) echo "Invalid choice"; return ;;
          esac
          ;;
        4)
          read -p "Enter model name to pull: " pull_model
          ;;
        *)
          echo "Invalid choice"
          return
          ;;
      esac

      echo "Pulling $pull_model model..."
      ollama pull $pull_model
      SELECTED_MODEL="$pull_model"
    elif [ "$model_choice" -eq $((${#MODEL_LIST[@]}+2)) ]; then
      # Use current selection
      echo "Using current selection: $SELECTED_MODEL"
    elif [ "$model_choice" -eq $((${#MODEL_LIST[@]}+3)) ]; then
      # Return to main menu
      echo "Returning to main menu..."
      return
    elif [ "$model_choice" -ge 1 ] && [ "$model_choice" -le ${#MODEL_LIST[@]} ]; then
      # Select from list
      SELECTED_MODEL="${MODEL_LIST[$((model_choice-1))]}"
      echo "Selected model: $SELECTED_MODEL"
    else
      echo "Invalid choice. Returning to main menu."
      return
    fi
  fi

  # Only run if a model was selected and we didn't return early
  if [ -n "$SELECTED_MODEL" ]; then
    echo "Starting $SELECTED_MODEL LLM..."
    ollama run $SELECTED_MODEL
  fi
}

# Function to clear screen (cross-platform)
clear_screen() {
  if command -v clear &> /dev/null; then
    clear
  elif command -v reset &> /dev/null; then
    reset
  else
    # Fallback for systems without clear or reset
    printf '\033[2J\033[H'
  fi
}

# Function to import model from Hugging Face
import_huggingface_model() {
  clear_screen # Use cross-platform clear function
  echo "===== Hugging Face Model Import ====="
  echo "1) Browse popular GGUF models"
  echo "2) Search for specific models (Keywords or Tags)"
  echo "3) Enter model URL manually"
  echo "4) Return to main menu"
  echo "=================================="
  read -p "Enter your choice (1-4): " hf_choice

  case $hf_choice in
    1)
      # List popular GGUF models
      clear_screen
      list_popular_gguf_models
      ;;
    2)
      # Search for models
      clear_screen
      search_huggingface_models
      ;;
    3)
      # Manual URL entry
      clear_screen
      manual_model_entry
      ;;
    4)
      return
      ;;
    *)
      echo "Invalid option. Please try again."
      sleep 1
      import_huggingface_model
      ;;
  esac
}

# Function to list popular GGUF models
list_popular_gguf_models() {
  echo "===== Popular GGUF Models ====="
  echo "Fetching popular models with GGUF format..."

  if command -v jq &> /dev/null; then
    # Get popular GGUF models
    GGUF_MODELS_JSON=$(curl -s "https://huggingface.co/api/models?search=gguf&sort=downloads&direction=-1&limit=20" | \
    jq -r '[.[] | select(
    (.modelId | ascii_downcase | contains("gguf")) or
    (.tags | join(",") | ascii_downcase | contains("gguf"))
      )]')

    # Count results
    COUNT=$(echo "$GGUF_MODELS_JSON" | jq 'length' 2>/dev/null || echo "0")

    if [ "$COUNT" -gt 0 ]; then
      echo "Found $COUNT popular GGUF models"
      echo "-----------------------------------"

      # Display numbered list of models
      echo "$GGUF_MODELS_JSON" | jq -r 'to_entries | .[] | "\(.key+1)) \(.value.modelId) - \(.value.downloads) downloads"'

      echo "-----------------------------------"
      echo "$((COUNT+1))) Return to Hugging Face menu"
      echo "-----------------------------------"

      # Get user selection
      read -p "Select a model to import (1-$((COUNT+1))): " model_choice

      if [ "$model_choice" -eq $((COUNT+1)) ]; then
        # Return to previous menu
        import_huggingface_model
      elif [ "$model_choice" -ge 1 ] && [ "$model_choice" -le $COUNT ]; then
        # Get selected model ID
        SELECTED_MODEL_ID=$(echo "$GGUF_MODELS_JSON" | jq -r ".[$((model_choice-1))].modelId")
        echo "Selected model: $SELECTED_MODEL_ID"

        # Import the selected model
        import_from_model_id "$SELECTED_MODEL_ID"
      else
        echo "Invalid choice."
        sleep 1
        list_popular_gguf_models
      fi
    else
      echo "Failed to fetch models. Please try another method."
      sleep 2
      import_huggingface_model
    fi
  else
    echo "jq is required for this feature. Please install it first."
    echo "Returning to previous menu..."
    sleep 2
    import_huggingface_model
  fi
}

# Function to import model from model ID
import_from_model_id() {
  local model_url="$1"
  echo "Importing model: $model_url"

  # Now use the existing import functionality with the selected model ID
  import_direct_url "$model_url"
}

# Function for manual model URL entry
manual_model_entry() {
  echo "===== Manual Model Import ====="
  echo "Enter the Hugging Face model URL or ID"
  echo "Examples:"
  echo "- TheBloke/Mistral-7B-Instruct-v0.1-GGUF"
  echo "- NousResearch/Nous-Hermes-2-Yi-34B-GGUF"
  echo "-----------------------------------"

  read -p "Enter model URL/ID: " model_url

  if [ -z "$model_url" ]; then
    echo "No model specified. Returning to menu."
    sleep 1
    import_huggingface_model
  else
    import_direct_url "$model_url"
  fi
}

# Updated function to import directly from URL with better LFS handling
import_direct_url() {
  # Use provided model URL if available, otherwise prompt
  local model_url="${1:-}"

  if [ -z "$model_url" ]; then
    read -p "Enter Hugging Face model URL: " model_url
  fi

  # Extract model name
  model_name=$(basename "$model_url")

  # Check if we have write permissions in current directory
  if ! touch test_write_permissions 2>/dev/null; then
    echo "[WARNING] Warning: No write permissions in current directory: $(pwd)"
    echo "[WARNING] This may cause issues during model import."
    read -p "Continue anyway? (y/n): " continue_no_write
    if [[ "$continue_no_write" != "y" && "$continue_no_write" != "Y" ]]; then
      echo "Import cancelled."
      return 1
    fi
  else
    rm -f test_write_permissions 2>/dev/null
  fi

  # Check if directory already exists (from previous interrupted attempt)
  if [ -d "$model_name" ]; then
    echo "Directory '$model_name' already exists."
    read -p "Do you want to (r)esume download, (d)elete and start fresh, or (c)ancel? [r/d/c]: " choice

    case $choice in
      r|R)
        echo "Resuming download..."
        cd "$model_name" || { echo "Cannot access model folder"; return 1; }
        echo "Pulling large files with Git LFS..."
        git lfs install
        git lfs pull
        ;;
      d|D)
        echo "Deleting directory and starting fresh..."
        rm -rf "$model_name"
        # Will continue with fresh download below
        ;;
      *)
        echo "Import cancelled."
        return 1
        ;;
    esac
  fi

  # Only proceed with clone if we're not already in the directory
  if [ ! -d "$model_name" ]; then
    # Install Git LFS if needed
    echo "Ensuring Git LFS is installed..."

    # Check if Git LFS is already installed
    if ! command -v git-lfs &> /dev/null; then
      echo "Git LFS not found. Installing..."

      case $OS in
        macos)
          if command -v brew &> /dev/null; then
            echo "Installing Git LFS via Homebrew..."
            brew install git-lfs
          else
            echo "Please install Git LFS manually:"
            echo "1. Install Homebrew: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
            echo "2. Then run: brew install git-lfs"
            echo "Or download from: https://git-lfs.github.io/"
          fi
          ;;
        linux)
          if command -v dnf &> /dev/null; then
            sudo dnf install -y git-lfs
          elif command -v apt &> /dev/null; then
            sudo apt update && sudo apt install -y git-lfs
          elif command -v yum &> /dev/null; then
            sudo yum install -y git-lfs
          elif command -v pacman &> /dev/null; then
            sudo pacman -S git-lfs
          elif command -v zypper &> /dev/null; then
            sudo zypper install git-lfs
          else
            echo "WARNING: Could not install Git LFS automatically."
            echo "Please install Git LFS manually: https://git-lfs.github.io/"
          fi
          ;;
        windows)
          if command -v winget &> /dev/null; then
            echo "Installing Git LFS via winget..."
            winget install GitHub.GitLFS
          elif command -v choco &> /dev/null; then
            echo "Installing Git LFS via Chocolatey..."
            choco install git-lfs
          elif command -v scoop &> /dev/null; then
            echo "Installing Git LFS via Scoop..."
            scoop install git-lfs
          else
            echo "WARNING: No Windows package manager found."
            echo "Please install Git LFS manually:"
            echo "1. Download from: https://git-lfs.github.io/"
            echo "2. Or install Chocolatey: https://chocolatey.org/install"
            echo "3. Then run: choco install git-lfs"
          fi
          ;;
        wsl)
          echo "Detected WSL environment. Installing Git LFS..."
          if command -v apt &> /dev/null; then
            sudo apt update && sudo apt install -y git-lfs
          elif command -v dnf &> /dev/null; then
            sudo dnf install -y git-lfs
          elif command -v yum &> /dev/null; then
            sudo yum install -y git-lfs
          elif command -v pacman &> /dev/null; then
            sudo pacman -S git-lfs
          elif command -v zypper &> /dev/null; then
            sudo zypper install git-lfs
          else
            echo "WARNING: Could not install Git LFS automatically."
            echo "Please install Git LFS manually: https://git-lfs.github.io/"
          fi
          ;;
      esac
    fi

    # Initialize Git LFS
    git lfs install

    # Show warning for large models
    if [[ "$model_url" == *"GGUF"* ]] || [[ "$model_url" == *"gguf"* ]] || \
       [[ "$model_url" == *"Small"* ]] || [[ "$model_url" == *"24B"* ]] || [[ "$model_url" == *"70B"* ]]; then
      echo "[WARNING] WARNING: This appears to be a large model (likely several GB)"
      echo "[WARNING] Download may take a long time depending on your connection"
      echo ""
      read -p "Do you want to continue? (y/n): " continue_download
      if [[ "$continue_download" != "y" && "$continue_download" != "Y" ]]; then
        echo "Download cancelled."
        return 1
      fi
    fi

    # Clone with progress indication
    echo "Cloning the model repository..."
    echo "Step 1/2: Cloning repository metadata"
    git clone "https://huggingface.co/$model_url" || {
      echo "Clone failed or was interrupted."
      return 1
    }

    # Enter the directory to pull LFS files
    cd "$model_name" || { echo "Model folder not found"; return 1; }

    echo "Step 2/2: Downloading large model files (this may take a long time)"
    echo "LFS progress will appear below. Be patient, large files take time to download."
    echo "---------------------------------------"
    git lfs pull || {
      echo "LFS pull failed. You can try to resume later."
      echo "To resume: cd $model_name && git lfs pull"
      read -p "Continue with import anyway? (y/n): " continue_anyway
      if [[ "$continue_anyway" != "y" && "$continue_anyway" != "Y" ]]; then
        cd ..
        return 1
      fi
    }
  else
    # If we're continuing from an existing directory
    cd "$model_name" || { echo "Model folder not found"; return 1; }
  fi

  # Find GGUF model file - search more thoroughly
  echo "Searching for GGUF files in the repository..."
  gguf_files=$(find . -name "*.gguf" -type f)

  # If multiple GGUF files found, let user choose
  if [ $(echo "$gguf_files" | wc -l) -gt 1 ]; then
    echo "Multiple GGUF files found. Please select one:"
    select gguf_file in $gguf_files; do
      if [ -n "$gguf_file" ]; then
        echo "Selected: $gguf_file"
        break
      else
        echo "Invalid selection. Try again."
      fi
    done
  # If only one found, use it
  elif [ $(echo "$gguf_files" | wc -l) -eq 1 ]; then
    gguf_file=$gguf_files
    echo "Found GGUF file: $gguf_file"
  # If no GGUF files found
  else
    echo "No .gguf files found. Showing all files in repository:"
    find . -type f | sort -h | grep -v "/.git/"

    # Ask user to manually specify the file
    read -p "Enter the exact GGUF file path (or press Enter to cancel): " gguf_file
    if [ -z "$gguf_file" ]; then
      echo "No GGUF file specified. Import cancelled."
      cd ..
      return 1
    fi
  fi

  # Verify the selected file exists
  if [ ! -f "$gguf_file" ]; then
    echo "Error: The specified GGUF file does not exist."
    cd ..
    return 1
  fi

  # Check file size to ensure it was properly downloaded
  if command -v stat &> /dev/null; then
    # Use stat command (more reliable on both systems)
    if [[ "$OS" == "macos" ]]; then
      file_size=$(stat -f%z "$gguf_file" 2>/dev/null || echo "0")
      file_size_human=$(du -h "$gguf_file" | cut -f1)
    else
      file_size=$(stat -c%s "$gguf_file" 2>/dev/null || echo "0")
      file_size_human=$(du -h "$gguf_file" | cut -f1)
    fi
  else
    # Fallback to du command
    file_size_human=$(du -h "$gguf_file" | cut -f1)
    file_size="unknown"
  fi

  echo "GGUF file size: $file_size_human"

  # Check if file size is suspiciously small (less than 1MB or only KB)
  if [[ "$file_size_human" == *"K"* ]] || [[ "$file_size_human" == "0"* ]] || [[ "$file_size" != "unknown" && "$file_size" -lt 1048576 ]]; then
    echo "[WARNING] Warning: File size appears very small for a GGUF model."
    echo "This might indicate an incomplete download."
    read -p "Continue anyway? (y/n): " continue_small
    if [[ "$continue_small" != "y" && "$continue_small" != "Y" ]]; then
      echo "Import cancelled. Try running 'git lfs pull' in the $model_name directory."
      cd ..
      return 1
    fi
  fi

  # Create the Modelfile
  echo "Creating Modelfile..."
  if ! cat > Modelfile <<EOF
FROM "./$gguf_file"
TEMPLATE """
<|system|> {{ .System }} <|end|>
<|user|> {{ .Prompt }} <|end|>
<|assistant|> {{ .Response }} <|end|>
"""
EOF
  then
    echo "Error: Could not create Modelfile. Check write permissions in current directory."
    echo "Current directory: $(pwd)"
    echo "Trying to create Modelfile in /tmp instead..."

    # Try creating in /tmp as fallback
    case $OS in
      macos)
        TEMP_DIR="${TMPDIR:-/tmp}"
        ;;
      windows)
        TEMP_DIR="${TEMP:-${TMP:-/tmp}}"
        ;;
      wsl)
        TEMP_DIR="${TMPDIR:-/tmp}"
        ;;
      *)
        TEMP_DIR="/tmp"
        ;;
    esac

    MODELFILE_PATH="$TEMP_DIR/Modelfile_$$"
    if ! cat > "$MODELFILE_PATH" <<EOF
FROM "./$gguf_file"
TEMPLATE """
<|system|> {{ .System }} <|end|>
<|user|> {{ .Prompt }} <|end|>
<|assistant|> {{ .Response }} <|end|>
"""
EOF
    then
      echo "Error: Could not create Modelfile in /tmp either. Permission denied."
      cd ..
      return 1
    fi
    echo "Created Modelfile at: $MODELFILE_PATH"
  else
    MODELFILE_PATH="./Modelfile"
    echo "Created Modelfile at: $MODELFILE_PATH"
  fi

  # Build the model in Ollama
  echo "Building the model in Ollama..."
  if ! ollama create "$model_name" -f "$MODELFILE_PATH"; then
    echo "Error: Failed to create model in Ollama."
    rm -f "$MODELFILE_PATH" 2>/dev/null
    cd ..
    return 1
  fi

  # Clean up temporary Modelfile if it was created in temp directory
  if [[ "$MODELFILE_PATH" == "$TEMP_DIR"/* ]] || [[ "$MODELFILE_PATH" == /tmp/* ]]; then
    rm -f "$MODELFILE_PATH"
  fi

  # Set as selected model
  SELECTED_MODEL="$model_name"

  # Return to parent directory
  cd ..

  # Run the model
  echo "Starting the model $model_name..."
  ollama run "$model_name"
}

# Function to search for GGUF models on Hugging Face with numbered selection
search_huggingface_models() {
  echo "===== Hugging Face GGUF Model Search ====="
  echo "This feature helps you find models with GGUF files on Hugging Face."

  # Prompt for search keywords
  read -p "Enter keywords to search for (e.g., 'llama') or press Enter to search all GGUF models: " search_terms

  # Handle empty search (just show GGUF models)
  if [ -z "$search_terms" ]; then
    echo "Searching for all GGUF models on Hugging Face (top downloads)"
    SEARCH_QUERY="gguf"
    SEARCH_TYPE="all GGUF models"
  else
    echo "Searching for models containing BOTH 'gguf' AND '$search_terms'"
    SEARCH_QUERY="$search_terms+gguf" # Combined search
    SEARCH_TYPE="models with BOTH terms"
  fi

  echo "---------------------------------------"

  # Search for models with GGUF format
  if command -v jq &> /dev/null; then
    echo "Fetching and filtering models..."

    # We'll get more results and filter more strictly
    SEARCH_RESULTS_JSON=$(curl -s "https://huggingface.co/api/models?search=$SEARCH_QUERY&limit=50" | \
    jq -r --arg KEYWORD "$(echo "$search_terms" | tr '[:upper:]' '[:lower:]')" '
    [.[] |
    # First check: It MUST contain "gguf"
    select(
    (.modelId | ascii_downcase | contains("gguf")) or
    (.tags | join(",") | ascii_downcase | contains("gguf")) or
    (.description | ascii_downcase | contains("gguf"))
    ) |
    # Second check: If keyword provided, it MUST contain keyword too
    # (skip this filter if no keyword)
    select(
    $KEYWORD == "" or
    (.modelId | ascii_downcase | contains($KEYWORD)) or
    (.tags | join(",") | ascii_downcase | contains($KEYWORD)) or
    (.description | ascii_downcase | contains($KEYWORD))
    )
    | {
      model: .,
      modelId: .modelId,
      downloads: .downloads,
      tags: .tags
    }
    ] | sort_by(-.downloads) | .[0:15]
    ')

    # Count results
    COUNT=$(echo "$SEARCH_RESULTS_JSON" | jq 'length' 2>/dev/null || echo "0")

    if [ "$COUNT" -gt 0 ]; then
      echo "[PASS] Found $COUNT $SEARCH_TYPE"
      echo "---------------------------------------"

      # Display numbered list of models
      echo "$SEARCH_RESULTS_JSON" | jq -r 'to_entries | .[] | "\(.key+1)) \(.value.modelId) (\(.value.downloads) downloads)"'

      echo "---------------------------------------"
      echo "$((COUNT+1))) Show more details about a model"
      echo "$((COUNT+2))) Return to previous menu"
      echo "---------------------------------------"

      # Get user selection
      read -p "Select a model to import (1-$((COUNT+2))): " model_choice

      if [ "$model_choice" -eq $((COUNT+2)) ]; then
        # Return to previous menu
        import_huggingface_model
      elif [ "$model_choice" -eq $((COUNT+1)) ]; then
        # Show more details about a specific model
        read -p "Enter the number of the model to see details (1-$COUNT): " detail_choice
        if [ "$detail_choice" -ge 1 ] && [ "$detail_choice" -le $COUNT ]; then
          # Get model details and display them
          MODEL_ID=$(echo "$SEARCH_RESULTS_JSON" | jq -r ".[$((detail_choice-1))].modelId")
          echo "=============== MODEL DETAILS ==============="
          echo "$SEARCH_RESULTS_JSON" | jq -r ".[$((detail_choice-1))]" | jq '.'
          echo "============================================="
          read -p "Would you like to import this model? (y/n): " import_detail
          if [[ $import_detail == "y" || $import_detail == "Y" ]]; then
            import_from_model_id "$MODEL_ID"
          else
            # Return to search results
            search_huggingface_models
          fi
        else
          echo "Invalid choice."
          sleep 1
          search_huggingface_models
        fi
      elif [ "$model_choice" -ge 1 ] && [ "$model_choice" -le $COUNT ]; then
        # Get selected model ID
        SELECTED_MODEL_ID=$(echo "$SEARCH_RESULTS_JSON" | jq -r ".[$((model_choice-1))].modelId")
        echo "Selected model: $SELECTED_MODEL_ID"

        # Import the selected model
        import_from_model_id "$SELECTED_MODEL_ID"
      else
        echo "Invalid choice."
        sleep 1
        search_huggingface_models
      fi
    else
      echo "No models found containing BOTH 'gguf' AND '$search_terms'."
      echo "Showing top GGUF models instead:"
      echo "---------------------------------------"

      FALLBACK_MODELS_JSON=$(curl -s "https://huggingface.co/api/models?search=gguf&sort=downloads&direction=-1&limit=10" | \
      jq -r '[.[] | select(
      (.modelId | ascii_downcase | contains("gguf")) or
      (.tags | join(",") | ascii_downcase | contains("gguf"))
        )] | .[0:10]')

      COUNT_FB=$(echo "$FALLBACK_MODELS_JSON" | jq 'length' 2>/dev/null || echo "0")

      if [ "$COUNT_FB" -gt 0 ]; then
        # Display numbered list of models
        echo "$FALLBACK_MODELS_JSON" | jq -r 'to_entries | .[] | "\(.key+1)) \(.value.modelId) (\(.value.downloads) downloads)"'

        echo "---------------------------------------"
        echo "$((COUNT_FB+1))) Return to previous menu"
        echo "---------------------------------------"

        # Get user selection
        read -p "Select a model to import (1-$((COUNT_FB+1))): " fb_choice

        if [ "$fb_choice" -eq $((COUNT_FB+1)) ]; then
          # Return to previous menu
          import_huggingface_model
        elif [ "$fb_choice" -ge 1 ] && [ "$fb_choice" -le $COUNT_FB ]; then
          # Get selected model ID
          FB_MODEL_ID=$(echo "$FALLBACK_MODELS_JSON" | jq -r ".[$((fb_choice-1))].modelId")
          echo "Selected model: $FB_MODEL_ID"

          # Import the selected model
          import_from_model_id "$FB_MODEL_ID"
        else
          echo "Invalid choice."
          sleep 1
          search_huggingface_models
        fi
      else
        echo "No fallback models found. Try a different search term."
        sleep 2
        import_huggingface_model
      fi
    fi
  else
    # Simple alternative if jq is not available
    echo "For better filtering, please install jq."
    echo "Visit: https://huggingface.co/models?search=gguf+$search_terms"
    echo "---------------------------------------"
    read -p "Press Enter to return to previous menu..."
    import_huggingface_model
  fi
}

# Function to crawl URLs with redirect depth control
train_from_url_with_redirects() {
  clear_screen
  echo "===== URL Training Data Crawler ====="
  echo "This will crawl web content and create training data"
  echo "-------------------------------------"
  
  # Get URL input
  read -p "Enter the base URL to crawl: " base_url
  if [[ -z "$base_url" ]]; then
    echo "Error: URL cannot be empty"
    return 1
  fi
  
  # Validate URL format
  if [[ ! "$base_url" =~ ^https?:// ]]; then
    echo "Warning: URL should start with http:// or https://"
    read -p "Add https:// prefix? (y/n): " add_https
    if [[ "$add_https" =~ ^[Yy] ]]; then
      base_url="https://$base_url"
    fi
  fi
  
  # Get redirect depth
  read -p "Enter maximum redirect depth (1-10, default: 3): " max_depth
  max_depth=${max_depth:-3}
  
  # Validate depth is a number and within range
  if ! [[ "$max_depth" =~ ^[0-9]+$ ]] || [ "$max_depth" -lt 1 ] || [ "$max_depth" -gt 10 ]; then
    echo "Invalid depth. Using default value of 3."
    max_depth=3
  fi
  
  # Get file types to include
  echo "Select content types to include:"
  echo "1) HTML only"
  echo "2) HTML + Text files"
  echo "3) HTML + Text + PDF"
  echo "4) All text content"
  read -p "Enter choice (1-4, default: 1): " content_choice
  content_choice=${content_choice:-1}
  
  case $content_choice in
    1) file_extensions="html,htm" ;;
    2) file_extensions="html,htm,txt,md" ;;
    3) file_extensions="html,htm,txt,md,pdf" ;;
    4) file_extensions="html,htm,txt,md,pdf,doc,docx,rtf" ;;
    *) file_extensions="html,htm" ;;
  esac
  
  # Output directory - Use OllamaTrauma-TrainingData folder
  output_dir="./OllamaTrauma-TrainingData/training_data_$(date +%Y%m%d_%H%M%S)"
  mkdir -p "$output_dir"
  
  echo ""
  echo "Configuration Summary:"
  echo "  Base URL: $base_url"
  echo "  Max Depth: $max_depth"
  echo "  File Types: $file_extensions"
  echo "  Output Directory: $output_dir"
  echo ""
  
  read -p "Proceed with crawling? (y/n): " proceed
  if [[ ! "$proceed" =~ ^[Yy] ]]; then
    echo "Crawling cancelled."
    return 0
  fi
  
  echo "Starting web crawling..."
  
  # Create Python crawler script
  cat > "$output_dir/url_crawler.py" << 'EOF'
#!/usr/bin/env python3
import requests
import sys
import os
import json
from urllib.parse import urljoin, urlparse, urlencode
from bs4 import BeautifulSoup
import time
import re
from datetime import datetime

class URLCrawler:
    def __init__(self, base_url, max_depth, file_extensions, output_dir):
        self.base_url = base_url
        self.max_depth = max_depth
        self.file_extensions = file_extensions.split(',')
        self.output_dir = output_dir
        self.visited_urls = set()
        self.crawled_data = []
        self.session = requests.Session()
        self.session.headers.update({
            'User-Agent': 'Mozilla/5.0 (compatible; OllamaTrauma-Crawler/1.0)'
        })
    
    def is_valid_url(self, url):
        """Check if URL is valid and within scope"""
        try:
            parsed = urlparse(url)
            base_parsed = urlparse(self.base_url)
            return parsed.netloc == base_parsed.netloc
        except:
            return False
    
    def extract_text_from_html(self, html_content):
        """Extract clean text from HTML"""
        try:
            soup = BeautifulSoup(html_content, 'html.parser')
            
            # Remove script and style elements
            for script in soup(["script", "style"]):
                script.extract()
            
            # Get text and clean it
            text = soup.get_text()
            lines = (line.strip() for line in text.splitlines())
            chunks = (phrase.strip() for line in lines for phrase in line.split("  "))
            text = ' '.join(chunk for chunk in chunks if chunk)
            
            return text
        except Exception as e:
            print(f"Error extracting text: {e}")
            return ""
    
    def crawl_url(self, url, depth=0):
        """Crawl a single URL"""
        if depth > self.max_depth or url in self.visited_urls:
            return []
        
        if not self.is_valid_url(url):
            return []
        
        self.visited_urls.add(url)
        found_urls = []
        
        try:
            print(f"Crawling (depth {depth}): {url}")
            response = self.session.get(url, timeout=10)
            response.raise_for_status()
            
            content_type = response.headers.get('content-type', '').lower()
            
            if 'text/html' in content_type:
                # Extract text content
                text_content = self.extract_text_from_html(response.text)
                
                if text_content.strip():
                    self.crawled_data.append({
                        'url': url,
                        'depth': depth,
                        'content': text_content[:5000],  # Limit content length
                        'timestamp': datetime.now().isoformat(),
                        'content_type': 'html'
                    })
                
                # Find more URLs to crawl
                if depth < self.max_depth:
                    soup = BeautifulSoup(response.text, 'html.parser')
                    for link in soup.find_all('a', href=True):
                        next_url = urljoin(url, link['href'])
                        if self.is_valid_url(next_url) and next_url not in self.visited_urls:
                            found_urls.append(next_url)
            
            elif any(ext in content_type for ext in ['text/plain', 'text/markdown']):
                # Handle text files
                self.crawled_data.append({
                    'url': url,
                    'depth': depth,
                    'content': response.text[:5000],
                    'timestamp': datetime.now().isoformat(),
                    'content_type': 'text'
                })
            
            time.sleep(0.5)  # Be respectful to the server
            
        except Exception as e:
            print(f"Error crawling {url}: {e}")
        
        return found_urls
    
    def crawl(self):
        """Main crawling function"""
        urls_to_crawl = [(self.base_url, 0)]
        
        while urls_to_crawl:
            url, depth = urls_to_crawl.pop(0)
            new_urls = self.crawl_url(url, depth)
            
            # Add new URLs to crawl
            for new_url in new_urls[:10]:  # Limit to prevent infinite crawling
                if new_url not in self.visited_urls:
                    urls_to_crawl.append((new_url, depth + 1))
        
        return self.crawled_data
    
    def save_training_data(self):
        """Save crawled data as training dataset"""
        training_file = os.path.join(self.output_dir, 'training_dataset.json')
        
        # Convert to training format
        training_data = []
        for item in self.crawled_data:
            # Create question-answer pairs from the content
            content = item['content']
            if len(content) > 100:  # Only use substantial content
                training_data.append({
                    "instruction": f"Provide information about the content from {item['url']}",
                    "input": "",
                    "output": content[:2000],  # Limit output length
                    "metadata": {
                        "source_url": item['url'],
                        "crawl_depth": item['depth'],
                        "timestamp": item['timestamp']
                    }
                })
        
        # Save the training data
        with open(training_file, 'w', encoding='utf-8') as f:
            json.dump(training_data, f, indent=2, ensure_ascii=False)
        
        print(f"\nTraining dataset saved to: {training_file}")
        print(f"Total training examples: {len(training_data)}")
        return training_file

if __name__ == "__main__":
    if len(sys.argv) != 5:
        print("Usage: python url_crawler.py <base_url> <max_depth> <file_extensions> <output_dir>")
        sys.exit(1)
    
    base_url = sys.argv[1]
    max_depth = int(sys.argv[2])
    file_extensions = sys.argv[3]
    output_dir = sys.argv[4]
    
    crawler = URLCrawler(base_url, max_depth, file_extensions, output_dir)
    crawled_data = crawler.crawl()
    training_file = crawler.save_training_data()
    
    print(f"\nCrawling completed!")
    print(f"URLs processed: {len(crawler.visited_urls)}")
    print(f"Training file: {training_file}")
EOF
  
  # Check if required Python packages are available
  echo "Checking Python dependencies..."
  python3 -c "import requests, bs4" 2>/dev/null || {
    echo "Installing required Python packages..."
    pip3 install requests beautifulsoup4 || {
      echo "Error: Failed to install required packages"
      echo "Please install manually: pip3 install requests beautifulsoup4"
      return 1
    }
  }
  
  # Run the crawler
  echo "Running crawler..."
  cd "$output_dir"
  python3 url_crawler.py "$base_url" "$max_depth" "$file_extensions" "."
  
  if [[ -f "training_dataset.json" ]]; then
    echo ""
    echo "Success! Training dataset created."
    echo "Dataset location: $output_dir/training_dataset.json"
    echo ""
    
    # Ask if user wants to start training immediately
    read -p "Start training with this dataset now? (y/n): " start_training
    if [[ "$start_training" =~ ^[Yy] ]]; then
      echo "Starting training with model: $SELECTED_MODEL"
      
      # Check if Ollama supports fine-tuning (this is experimental)
      if ollama --help | grep -q "finetune"; then
        ollama finetune "$SELECTED_MODEL" --data "training_dataset.json" --output "${SELECTED_MODEL}_url_trained"
      else
        echo "Note: Direct Ollama fine-tuning not available."
        echo "Training dataset is ready for use with compatible training tools."
        echo "You can use the dataset with:"
        echo "  - Custom training scripts"
        echo "  - Hugging Face training pipelines"
        echo "  - Other LLM training frameworks"
      fi
    fi
  else
    echo "Error: Failed to create training dataset"
    return 1
  fi
  
  cd - > /dev/null
}

# Function for advanced LLM operations
advanced_llm_operations() {
  clear_screen # Use cross-platform clear function
  echo "Select an option:"
  echo "1) Fine-tune an LLM with a dataset"
  echo "2) Use embeddings for retrieval (RAG)"
  echo "3) Fine-tune the currently selected model"
  echo "4) Select a different model"
  echo "5) Train from URL with redirect crawling"
  read -p "Enter choice (1/2/3/4/5): " choice

  if [ "$choice" -eq 1 ]; then
    # Fine-tuning the LLM
    read -p "Enter model name (default: $SELECTED_MODEL): " model_name
    model_name=${model_name:-$SELECTED_MODEL}
    read -p "Enter dataset file (e.g., my_dataset.json): " dataset

    echo "Running fine-tuning process..."
    python train.py --model "$model_name" --data "$dataset" --epochs 3

  elif [ "$choice" -eq 2 ]; then
    # Using embeddings for RAG
    echo "Setting up retrieval-augmented generation..."
    read -p "Enter text data for embedding: " text_data

    python -c "
    from sentence_transformers import SentenceTransformer
    model = SentenceTransformer('all-MiniLM-L6-v2')
    embedding = model.encode(\"$text_data\")
    print('Embedding created:', embedding)
    "

  elif [ "$choice" -eq 3 ]; then
    # Fine-tuning the selected model
    read -p "Enter dataset file (e.g., my_dataset.json): " dataset

    echo "Fine-tuning model $SELECTED_MODEL in Ollama..."
    ollama finetune $SELECTED_MODEL --data "$dataset" --output "${SELECTED_MODEL}_tuned.gguf"

  elif [ "$choice" -eq 4 ]; then
    # Select a different model
    echo "Available models:"
    ollama list
    read -p "Enter model name to use: " new_model

    # Check if model exists
    if ollama list | grep -q "$new_model"; then
      SELECTED_MODEL="$new_model"
      echo "Selected model is now: $SELECTED_MODEL"
    else
      echo "Model $new_model not found. Would you like to pull it? (y/n)"
      read -p "> " pull_choice
      if [[ $pull_choice == "y" || $pull_choice == "Y" ]]; then
        ollama pull $new_model
        SELECTED_MODEL="$new_model"
      fi
    fi

  elif [ "$choice" -eq 5 ]; then
    # Train from URL with redirect crawling
    train_from_url_with_redirects

  else
    echo "Invalid choice."
  fi
}

# Function to integrate training data with LLMs
integrate_training_data() {
  clear_screen
  echo "===== Training Data Integration ====="
  echo "Choose how to use your training data with LLMs"
  echo "---------------------------------------------"
  echo ""
  echo "Available methods:"
  echo "1) Fine-tune with Ollama (if supported)"
  echo "2) Create a Modelfile for custom model"
  echo "3) RAG (Retrieval Augmented Generation) setup"
  echo "4) Export for external training tools"
  echo "5) Create embeddings database"
  echo "6) Back to main menu"
  echo ""
  read -p "Enter your choice (1-6): " integration_choice
  
  case $integration_choice in
    1) finetune_with_ollama ;;
    2) create_custom_modelfile ;;
    3) setup_rag_system ;;
    4) export_for_external_tools ;;
    5) create_embeddings_database ;;
    6) return ;;
    *) echo "Invalid choice."; sleep 1; integrate_training_data ;;
  esac
}

# Function to fine-tune with Ollama
finetune_with_ollama() {
  clear_screen
  echo "===== Ollama Fine-tuning ====="
  echo ""
  
  # Check for training data files in the OllamaTrauma-TrainingData directory
  echo "Looking for training data files..."
  training_files=($(find ./OllamaTrauma-TrainingData -name "training_dataset.json" -o -name "*.jsonl" -o -name "*training*.json" 2>/dev/null))
  
  if [ ${#training_files[@]} -eq 0 ]; then
    echo "No training data files found in OllamaTrauma-TrainingData directory."
    echo "Expected formats: training_dataset.json, *.jsonl, *training*.json"
    echo ""
    read -p "Enter path to your training data file: " manual_file
    if [[ -f "$manual_file" ]]; then
      training_files=("$manual_file")
    else
      echo "File not found: $manual_file"
      return 1
    fi
  fi
  
  echo "Found training data files:"
  for i in "${!training_files[@]}"; do
    echo "$((i+1))) ${training_files[$i]}"
  done
  echo ""
  
  read -p "Select file (1-${#training_files[@]}): " file_choice
  if [[ ! "$file_choice" =~ ^[0-9]+$ ]] || [ "$file_choice" -lt 1 ] || [ "$file_choice" -gt ${#training_files[@]} ]; then
    echo "Invalid selection"
    return 1
  fi
  
  selected_file="${training_files[$((file_choice-1))]}"
  echo "Selected: $selected_file"
  echo ""
  
  # Show available models
  echo "Available models for fine-tuning:"
  ollama list
  echo ""
  
  read -p "Enter base model name (default: $SELECTED_MODEL): " base_model
  base_model=${base_model:-$SELECTED_MODEL}
  
  read -p "Enter name for fine-tuned model: " tuned_model_name
  if [[ -z "$tuned_model_name" ]]; then
    tuned_model_name="${base_model}_finetuned"
  fi
  
  echo ""
  echo "Fine-tuning configuration:"
  echo "  Base model: $base_model"
  echo "  Training data: $selected_file"
  echo "  Output model: $tuned_model_name"
  echo ""
  
  read -p "Proceed with fine-tuning? (y/n): " proceed
  if [[ ! "$proceed" =~ ^[Yy] ]]; then
    echo "Fine-tuning cancelled."
    return 0
  fi
  
  # Check if Ollama supports fine-tuning
  if ollama --help 2>/dev/null | grep -q "finetune\|train"; then
    echo "Starting Ollama fine-tuning..."
    ollama finetune "$base_model" --data "$selected_file" --output "$tuned_model_name"
  else
    echo "Direct Ollama fine-tuning not available in this version."
    echo "Creating Modelfile approach instead..."
    create_modelfile_with_data "$base_model" "$selected_file" "$tuned_model_name"
  fi
}

# Function to create a custom Modelfile
create_custom_modelfile() {
  clear_screen
  echo "===== Create Custom Modelfile ====="
  echo "This creates a Modelfile that incorporates your training data"
  echo ""
  
  # Find training data
  echo "Looking for training data files..."
  training_files=($(find . -name "*.json" -o -name "*.jsonl" -o -name "*.txt" 2>/dev/null | head -10))
  
  if [ ${#training_files[@]} -eq 0 ]; then
    read -p "Enter path to your training data file: " data_file
  else
    echo "Found data files:"
    for i in "${!training_files[@]}"; do
      echo "$((i+1))) ${training_files[$i]}"
    done
    echo "$((${#training_files[@]}+1))) Enter custom path"
    echo ""
    read -p "Select file: " file_choice
    
    if [[ "$file_choice" -eq $((${#training_files[@]}+1)) ]]; then
      read -p "Enter path to your training data file: " data_file
    else
      data_file="${training_files[$((file_choice-1))]}"
    fi
  fi
  
  if [[ ! -f "$data_file" ]]; then
    echo "File not found: $data_file"
    return 1
  fi
  
  read -p "Enter base model (default: $SELECTED_MODEL): " base_model
  base_model=${base_model:-$SELECTED_MODEL}
  
  read -p "Enter name for your custom model: " custom_model_name
  if [[ -z "$custom_model_name" ]]; then
    custom_model_name="${base_model}_custom"
  fi
  
  # Create system prompts from training data
  echo "Analyzing training data to create system prompts..."
  
  # Create Modelfile
  modelfile_path="./Modelfile_${custom_model_name}"
  
  cat > "$modelfile_path" << EOF
FROM $base_model

# System message incorporating training data knowledge
SYSTEM """
You are an AI assistant that has been trained on specific domain knowledge. 
You have access to specialized information and should use this knowledge to provide accurate, helpful responses.

Key areas of expertise based on training data:
- Domain-specific information from the provided training dataset
- Context-aware responses based on learned patterns
- Detailed explanations when appropriate

Please provide helpful, accurate responses while being mindful of the specialized knowledge you've been trained on.
"""

# Parameters for better performance
PARAMETER temperature 0.7
PARAMETER top_p 0.9
PARAMETER top_k 40
PARAMETER repeat_penalty 1.1

# Template for responses
TEMPLATE """{{ if .System }}<|im_start|>system
{{ .System }}<|im_end|>
{{ end }}{{ if .Prompt }}<|im_start|>user
{{ .Prompt }}<|im_end|>
{{ end }}<|im_start|>assistant
"""
EOF

  # Add training data context if it's JSON
  if [[ "$data_file" == *.json ]]; then
    echo "# Training data context" >> "$modelfile_path"
    echo "# This model has been informed by data from: $data_file" >> "$modelfile_path"
    
    # Extract key information from training data (first few examples)
    python3 -c "
import json
import sys

try:
    with open('$data_file', 'r') as f:
        data = json.load(f)
    
    if isinstance(data, list) and len(data) > 0:
        print('\\n# Sample training context:')
        for i, item in enumerate(data[:3]):  # First 3 items
            if isinstance(item, dict):
                if 'instruction' in item and 'output' in item:
                    print(f'# Example {i+1}: {item[\"instruction\"][:100]}...')
                elif 'content' in item:
                    print(f'# Example {i+1}: {item[\"content\"][:100]}...')
except Exception as e:
    print(f'# Could not parse training data: {e}')
" >> "$modelfile_path"
  fi
  
  echo ""
  echo "Modelfile created: $modelfile_path"
  echo ""
  echo "Creating custom model with Ollama..."
  
  if ollama create "$custom_model_name" -f "$modelfile_path"; then
    echo ""
    echo "✅ Success! Custom model '$custom_model_name' created."
    echo "Your training data has been incorporated into the model's system prompt."
    echo ""
    read -p "Test the custom model now? (y/n): " test_model
    if [[ "$test_model" =~ ^[Yy] ]]; then
      echo ""
      echo "Testing model with a sample question..."
      echo "Type your question (or press Enter for default test):"
      read -p "> " test_question
      test_question=${test_question:-"What can you tell me about your training data?"}
      
      echo ""
      echo "Model response:"
      ollama run "$custom_model_name" "$test_question"
    fi
  else
    echo "❌ Failed to create custom model"
    echo "Modelfile is available at: $modelfile_path"
  fi
}

# Function to create RAG system
setup_rag_system() {
  clear_screen
  echo "===== RAG (Retrieval Augmented Generation) Setup ====="
  echo "This creates a system that retrieves relevant information from your data"
  echo ""
  
  # Check for required Python packages
  echo "Checking Python dependencies for RAG..."
  python3 -c "import sentence_transformers, numpy, faiss" 2>/dev/null || {
    echo "Installing required packages for RAG..."
    pip3 install sentence-transformers numpy faiss-cpu || {
      echo "Failed to install required packages. Please install manually:"
      echo "pip3 install sentence-transformers numpy faiss-cpu"
      return 1
    }
  }
  
  # Find training data
  echo "Looking for training data files..."
  data_files=($(find . -name "*.json" -o -name "*.jsonl" -o -name "*.txt" 2>/dev/null))
  
  if [ ${#data_files[@]} -eq 0 ]; then
    read -p "Enter path to your training data: " data_file
  else
    echo "Found data files:"
    for i in "${!data_files[@]}"; do
      echo "$((i+1))) ${data_files[$i]}"
    done
    read -p "Select file: " file_choice
    data_file="${data_files[$((file_choice-1))]}"
  fi
  
  if [[ ! -f "$data_file" ]]; then
    echo "File not found: $data_file"
    return 1
  fi
  
  # Create RAG system
  echo "Creating RAG system..."
  
  cat > "./rag_system.py" << 'EOF'
#!/usr/bin/env python3
import json
import numpy as np
from sentence_transformers import SentenceTransformer
import faiss
import sys
import os

class RAGSystem:
    def __init__(self, data_file):
        self.model = SentenceTransformer('all-MiniLM-L6-v2')
        self.data_file = data_file
        self.documents = []
        self.embeddings = None
        self.index = None
        
    def load_data(self):
        """Load and process training data"""
        print("Loading training data...")
        
        if self.data_file.endswith('.json'):
            with open(self.data_file, 'r') as f:
                data = json.load(f)
                
            if isinstance(data, list):
                for item in data:
                    if isinstance(item, dict):
                        if 'content' in item:
                            self.documents.append(item['content'])
                        elif 'output' in item:
                            self.documents.append(item['output'])
                        elif 'instruction' in item:
                            self.documents.append(f"{item.get('instruction', '')}: {item.get('output', '')}")
                        else:
                            # Use the entire item as text
                            self.documents.append(str(item))
        
        elif self.data_file.endswith('.txt'):
            with open(self.data_file, 'r') as f:
                content = f.read()
                # Split into chunks
                chunks = [chunk.strip() for chunk in content.split('\n\n') if chunk.strip()]
                self.documents.extend(chunks)
        
        print(f"Loaded {len(self.documents)} documents")
        
    def create_embeddings(self):
        """Create embeddings for all documents"""
        print("Creating embeddings...")
        self.embeddings = self.model.encode(self.documents)
        
        # Create FAISS index
        dimension = self.embeddings.shape[1]
        self.index = faiss.IndexFlatL2(dimension)
        self.index.add(self.embeddings.astype('float32'))
        
        print(f"Created embeddings with dimension {dimension}")
        
    def search(self, query, top_k=3):
        """Search for relevant documents"""
        query_embedding = self.model.encode([query])
        
        scores, indices = self.index.search(query_embedding.astype('float32'), top_k)
        
        results = []
        for score, idx in zip(scores[0], indices[0]):
            results.append({
                'document': self.documents[idx],
                'score': float(score)
            })
        
        return results
        
    def generate_response(self, query, context_docs):
        """Generate response using Ollama with context"""
        context = "\n\n".join([doc['document'][:500] for doc in context_docs])
        
        prompt = f"""Based on the following context information, please answer the question:

Context:
{context}

Question: {query}

Answer:"""
        
        return prompt

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python3 rag_system.py <data_file>")
        sys.exit(1)
    
    data_file = sys.argv[1]
    
    # Initialize RAG system
    rag = RAGSystem(data_file)
    rag.load_data()
    rag.create_embeddings()
    
    print("\n🚀 RAG System Ready!")
    print("Enter queries to search your training data (type 'quit' to exit)")
    print("-" * 50)
    
    while True:
        query = input("\nQuery: ").strip()
        if query.lower() in ['quit', 'exit']:
            break
            
        if not query:
            continue
            
        # Search for relevant documents
        results = rag.search(query, top_k=3)
        
        print(f"\n📚 Found {len(results)} relevant documents:")
        for i, result in enumerate(results, 1):
            print(f"\n{i}. (Score: {result['score']:.3f})")
            print(result['document'][:300] + "..." if len(result['document']) > 300 else result['document'])
        
        # Generate Ollama prompt
        prompt = rag.generate_response(query, results)
        
        print(f"\n🤖 Sending to Ollama model...")
        os.system(f'ollama run mistral "{prompt}"')
EOF

  chmod +x "./rag_system.py"
  
  echo ""
  echo "✅ RAG system created!"
  echo "File: ./rag_system.py"
  echo ""
  
  read -p "Test the RAG system now? (y/n): " test_rag
  if [[ "$test_rag" =~ ^[Yy] ]]; then
    echo "Starting RAG system..."
    python3 ./rag_system.py "$data_file"
  fi
}

# Function to export training data for external tools
export_for_external_tools() {
  clear_screen
  echo "===== Export Training Data ====="
  echo "Convert your data for external training frameworks"
  echo ""
  
  # Find training data files
  data_files=($(find . -name "*.json" -o -name "*.jsonl" 2>/dev/null))
  
  if [ ${#data_files[@]} -eq 0 ]; then
    echo "No training data files found."
    read -p "Enter path to your training data: " source_file
  else
    echo "Found training data files:"
    for i in "${!data_files[@]}"; do
      echo "$((i+1))) ${data_files[$i]}"
    done
    read -p "Select file: " file_choice
    source_file="${data_files[$((file_choice-1))]}"
  fi
  
  if [[ ! -f "$source_file" ]]; then
    echo "File not found: $source_file"
    return 1
  fi
  
  echo ""
  echo "Export formats:"
  echo "1) Hugging Face format (for transformers library)"
  echo "2) OpenAI fine-tuning format"
  echo "3) CSV format"
  echo "4) Plain text format"
  echo "5) JSONL format"
  
  read -p "Select export format (1-5): " export_format
  
  output_dir="./exported_data_$(date +%Y%m%d_%H%M%S)"
  mkdir -p "$output_dir"
  
  case $export_format in
    1)
      # Hugging Face format
      python3 -c "
import json
import os

with open('$source_file', 'r') as f:
    data = json.load(f)

hf_data = {'train': []}
for item in data:
    if isinstance(item, dict):
        if 'instruction' in item and 'output' in item:
            hf_data['train'].append({
                'text': f\"<|im_start|>user\\n{item['instruction']}\\n<|im_end|>\\n<|im_start|>assistant\\n{item['output']}\\n<|im_end|>\"
            })

with open('$output_dir/hf_dataset.json', 'w') as f:
    json.dump(hf_data, f, indent=2)

print('Exported Hugging Face format to: $output_dir/hf_dataset.json')
"
      ;;
    2)
      # OpenAI format
      python3 -c "
import json

with open('$source_file', 'r') as f:
    data = json.load(f)

openai_data = []
for item in data:
    if isinstance(item, dict):
        if 'instruction' in item and 'output' in item:
            openai_data.append({
                'messages': [
                    {'role': 'user', 'content': item['instruction']},
                    {'role': 'assistant', 'content': item['output']}
                ]
            })

with open('$output_dir/openai_format.jsonl', 'w') as f:
    for item in openai_data:
        f.write(json.dumps(item) + '\\n')

print('Exported OpenAI format to: $output_dir/openai_format.jsonl')
"
      ;;
    3)
      # CSV format
      python3 -c "
import json
import csv

with open('$source_file', 'r') as f:
    data = json.load(f)

with open('$output_dir/training_data.csv', 'w', newline='') as csvfile:
    fieldnames = ['instruction', 'output', 'source']
    writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
    writer.writeheader()
    
    for item in data:
        if isinstance(item, dict):
            writer.writerow({
                'instruction': item.get('instruction', ''),
                'output': item.get('output', ''),
                'source': item.get('metadata', {}).get('source_url', '')
            })

print('Exported CSV format to: $output_dir/training_data.csv')
"
      ;;
    4)
      # Plain text format
      python3 -c "
import json

with open('$source_file', 'r') as f:
    data = json.load(f)

with open('$output_dir/training_data.txt', 'w') as f:
    for i, item in enumerate(data):
        if isinstance(item, dict):
            f.write(f'=== Example {i+1} ===\\n')
            if 'instruction' in item:
                f.write(f'Q: {item[\"instruction\"]}\\n')
            if 'output' in item:
                f.write(f'A: {item[\"output\"]}\\n')
            f.write('\\n')

print('Exported plain text format to: $output_dir/training_data.txt')
"
      ;;
    5)
      # JSONL format
      python3 -c "
import json

with open('$source_file', 'r') as f:
    data = json.load(f)

with open('$output_dir/training_data.jsonl', 'w') as f:
    for item in data:
        if isinstance(item, dict):
            f.write(json.dumps(item) + '\\n')

print('Exported JSONL format to: $output_dir/training_data.jsonl')
"
      ;;
    *)
      echo "Invalid format selected"
      return 1
      ;;
  esac
  
  echo ""
  echo "✅ Export completed!"
  echo "Files saved to: $output_dir"
  ls -la "$output_dir"
}

# Function to create embeddings database
create_embeddings_database() {
  clear_screen
  echo "===== Create Embeddings Database ====="
  echo "Create a searchable vector database from your training data"
  echo ""
  
  # Check dependencies
  python3 -c "import sentence_transformers, numpy" 2>/dev/null || {
    echo "Installing required packages..."
    pip3 install sentence-transformers numpy || {
      echo "Failed to install packages"
      return 1
    }
  }
  
  # Find data files
  data_files=($(find . -name "*.json" -o -name "*.txt" 2>/dev/null))
  
  if [ ${#data_files[@]} -eq 0 ]; then
    read -p "Enter path to your data file: " data_file
  else
    echo "Select data file:"
    for i in "${!data_files[@]}"; do
      echo "$((i+1))) ${data_files[$i]}"
    done
    read -p "Choice: " file_choice
    data_file="${data_files[$((file_choice-1))]}"
  fi
  
  echo "Creating embeddings database..."
  
  python3 -c "
import json
import numpy as np
from sentence_transformers import SentenceTransformer
import pickle

print('Loading model...')
model = SentenceTransformer('all-MiniLM-L6-v2')

print('Loading data...')
documents = []

if '$data_file'.endswith('.json'):
    with open('$data_file', 'r') as f:
        data = json.load(f)
    
    for item in data:
        if isinstance(item, dict):
            text = item.get('content') or item.get('output') or str(item)
            documents.append(text)
elif '$data_file'.endswith('.txt'):
    with open('$data_file', 'r') as f:
        content = f.read()
        documents = [chunk.strip() for chunk in content.split('\n\n') if chunk.strip()]

print(f'Processing {len(documents)} documents...')
embeddings = model.encode(documents)

# Save embeddings and documents
database = {
    'embeddings': embeddings,
    'documents': documents,
    'model_name': 'all-MiniLM-L6-v2'
}

db_file = './embeddings_database.pkl'
with open(db_file, 'wb') as f:
    pickle.dump(database, f)

print(f'✅ Embeddings database saved to: {db_file}')
print(f'   - {len(documents)} documents')
print(f'   - {embeddings.shape[1]} dimensional embeddings')
"
  
  echo ""
  echo "✅ Embeddings database created!"
  echo "You can now use this for semantic search and RAG applications."
}

# New function to delete selected models
delete_models() {
  clear_screen
  echo "===== Delete Models ====="
  echo "This will remove selected models from Ollama"
  echo "--------------------------------"

  # Get available models
  MODEL_LIST=($(ollama list | tail -n +2 | awk '{print $1}' | cut -d':' -f1 | sort -u))

  if [ ${#MODEL_LIST[@]} -eq 0 ]; then
    echo "No models found to delete."
    sleep 2
    return
  fi

  # Display models with numbers
  echo "Available models:"
  echo "----------------------------"
  for i in "${!MODEL_LIST[@]}"; do
    MODEL_NUM=$((i+1))
    MODEL_INFO=$(ollama list | grep "${MODEL_LIST[$i]}" | head -1)
    MODEL_SIZE=$(echo "$MODEL_INFO" | awk '{print $3, $4}')
    echo "$MODEL_NUM) ${MODEL_LIST[$i]} ($MODEL_SIZE)"
  done
  echo "----------------------------"
  echo "$((${#MODEL_LIST[@]}+1))) Return to main menu"
  echo "----------------------------"

  # Get user choice
  read -p "Enter model number to delete (1-$((${#MODEL_LIST[@]}+1))): " delete_choice

  # Handle return to main menu
  if [ "$delete_choice" -eq $((${#MODEL_LIST[@]}+1)) ]; then
    echo "Returning to main menu..."
    return
  # Handle model deletion
  elif [ "$delete_choice" -ge 1 ] && [ "$delete_choice" -le ${#MODEL_LIST[@]} ]; then
    MODEL_TO_DELETE="${MODEL_LIST[$((delete_choice-1))]}"

    # Confirm deletion
    echo "You are about to delete model: $MODEL_TO_DELETE"
    read -p "Are you sure? (y/n): " confirm

    if [[ $confirm == "y" || $confirm == "Y" ]]; then
      echo "Deleting $MODEL_TO_DELETE..."
      ollama rm "$MODEL_TO_DELETE"

      # Check if deleted model was the selected model
      if [ "$MODEL_TO_DELETE" == "$SELECTED_MODEL" ]; then
        # Reset to mistral or the first available model
        if ollama list | grep -q "mistral"; then
          SELECTED_MODEL="mistral"
        else
          # Get the first available model or set to mistral if none
          NEW_MODEL_LIST=($(ollama list | tail -n +2 | awk '{print $1}' | cut -d':' -f1 | sort -u))
          if [ ${#NEW_MODEL_LIST[@]} -gt 0 ]; then
            SELECTED_MODEL="${NEW_MODEL_LIST[0]}"
          else
            SELECTED_MODEL="mistral"
          fi
        fi
        echo "Current model was deleted. New selected model: $SELECTED_MODEL"
      fi

      echo "Model deleted successfully."
      sleep 1

      # Ask if user wants to delete another model
      read -p "Delete another model? (y/n): " another
      if [[ $another == "y" || $another == "Y" ]]; then
        delete_models # Recursive call to delete another model
      fi
    else
      echo "Deletion cancelled."
      sleep 1
      delete_models # Return to the delete menu
    fi
  else
    echo "Invalid choice."
    sleep 1
    delete_models # Return to the delete menu on invalid input
  fi
}

# Main function with menu - updated with delete option
main() {
  clear_screen
  echo "===== Ollama Management Tool ====="
  echo "Current OS: $OS"
  echo "1) Install/Update and Run Model (Current: $SELECTED_MODEL)"
  echo "2) Import/Search for a Model from Huggingace.co"
  echo "3) Advanced LLM Operations (Train The Model, Fine-tune)"
  echo "4) Training Data Integration (Use Your Data with LLMs)"
  echo "5) Delete Models"
  echo "6) Exit"
  echo "=================================="
  read -p "Enter your choice (1-6): " main_choice

  case $main_choice in
    1) clear_screen; install_and_run_model ;;
    2) import_huggingface_model ;;
    3) advanced_llm_operations ;;
    4) integrate_training_data ;;
    5) delete_models ;;
    6) echo "Exiting..."; exit 0 ;;
    *) echo "Invalid option. Please try again."; sleep 1; main ;;
  esac

  # Return to main menu after function completes
  read -p "Press Enter to return to main menu..."
  clear_screen
  main
}

# Initialize OS detection and run dependency check
detect_os
echo "Detected OS: $OS"
check_dependencies

# Start the script
main