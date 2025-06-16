#!/bin/bash

# Global variables
SELECTED_MODEL="mistral"

# Function to check and install dependencies
check_dependencies() {
    echo "Checking for required dependencies..."
    
    # Check if jq is installed
    if ! command -v jq &> /dev/null; then
        echo "jq not found. Installing..."
        
        # Check for different package managers
        if command -v dnf &> /dev/null; then
            sudo dnf install -y jq
        elif command -v apt &> /dev/null; then
            sudo apt update && sudo apt install -y jq
        elif command -v yum &> /dev/null; then
            sudo yum install -y jq
        else
            echo "WARNING: Could not install jq. Package manager not found."
            echo "Please install jq manually for better JSON parsing."
        fi
    else
        echo "jq is already installed."
    fi
}

# Run the dependency check at startup
check_dependencies

# Function to install/update Ollama and run selected model
install_and_run_model() {
    # Check if Ollama is installed
    if ! command -v ollama &> /dev/null; then
        echo "Ollama not found. Installing..."
        curl -fsSL https://ollama.com/install.sh | sh
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
            echo "You can update manually by reinstalling: curl -fsSL https://ollama.com/install.sh | sh"
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

# Function to import model from Hugging Face
import_huggingface_model() {
    reset  # Added reset command to clear screen before showing submenu
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
            reset
            list_popular_gguf_models
            ;;
        2)
            # Search for models
            reset
            search_huggingface_models
            ;;
        3)
            # Manual URL entry
            reset
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
        curl -s "https://huggingface.co/api/models?search=gguf&sort=downloads&direction=-1&limit=20" | \
        jq -r '[.[] | select(
            (.modelId | ascii_downcase | contains("gguf")) or
            (.tags | join(",") | ascii_downcase | contains("gguf"))
        )]' > /tmp/gguf_models.json
        
        # Count results
        COUNT=$(jq 'length' /tmp/gguf_models.json 2>/dev/null || echo "0")
        
        if [ "$COUNT" -gt 0 ]; then
            echo "Found $COUNT popular GGUF models"
            echo "-----------------------------------"
            
            # Display numbered list of models
            jq -r 'to_entries | .[] | "\(.key+1)) \(.value.modelId) - \(.value.downloads) downloads"' /tmp/gguf_models.json
            
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
                SELECTED_MODEL_ID=$(jq -r ".[$((model_choice-1))].modelId" /tmp/gguf_models.json)
                echo "Selected model: $SELECTED_MODEL_ID"
                
                # Import the selected model
                import_from_model_id "$SELECTED_MODEL_ID"
            else
                echo "Invalid choice."
                sleep 1
                list_popular_gguf_models
            fi
            
            # Clean up
            rm -f /tmp/gguf_models.json
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
        git lfs install
        
        # Show warning for large models
        if [[ "$model_url" == *"GGUF"* ]] || [[ "$model_url" == *"gguf"* ]] || \
           [[ "$model_url" == *"Small"* ]] || [[ "$model_url" == *"24B"* ]] || [[ "$model_url" == *"70B"* ]]; then
            echo "⚠️  WARNING: This appears to be a large model (likely several GB)"
            echo "⚠️  Download may take a long time depending on your connection"
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
    file_size=$(du -h "$gguf_file" | cut -f1)
    echo "GGUF file size: $file_size"
    
    if [[ "$file_size" == *"K"* ]] || [[ "$file_size" == "0"* ]]; then
        echo "⚠️ Warning: File size appears very small for a GGUF model."
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
    cat > Modelfile <<EOF
FROM "./$gguf_file"
TEMPLATE """
<|system|> {{ .System }} <|end|>
<|user|> {{ .Prompt }} <|end|>
<|assistant|> {{ .Response }} <|end|>
"""
EOF

    # Build the model in Ollama
    echo "Building the model in Ollama..."
    ollama create "$model_name" -f Modelfile

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
        SEARCH_QUERY="$search_terms+gguf"  # Combined search
        SEARCH_TYPE="models with BOTH terms"
    fi
    
    echo "---------------------------------------"
    
    # Search for models with GGUF format
    if command -v jq &> /dev/null; then
        echo "Fetching and filtering models..."
        
        # We'll get more results and filter more strictly
        curl -s "https://huggingface.co/api/models?search=$SEARCH_QUERY&limit=50" | \
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
        ' > /tmp/gguf_results.json
        
        # Count results
        COUNT=$(jq 'length' /tmp/gguf_results.json 2>/dev/null || echo "0")
        
        if [ "$COUNT" -gt 0 ]; then
            echo "✅ Found $COUNT $SEARCH_TYPE"
            echo "---------------------------------------"
            
            # Display numbered list of models
            jq -r 'to_entries | .[] | "\(.key+1)) \(.value.modelId) (\(.value.downloads) downloads)"' /tmp/gguf_results.json
            
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
                    MODEL_ID=$(jq -r ".[$((detail_choice-1))].modelId" /tmp/gguf_results.json)
                    echo "=============== MODEL DETAILS ==============="
                    jq -r ".[$((detail_choice-1))]" /tmp/gguf_results.json | jq '.'
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
                SELECTED_MODEL_ID=$(jq -r ".[$((model_choice-1))].modelId" /tmp/gguf_results.json)
                echo "Selected model: $SELECTED_MODEL_ID"
                
                # Import the selected model
                import_from_model_id "$SELECTED_MODEL_ID"
            else
                echo "Invalid choice."
                sleep 1
                search_huggingface_models
            fi
            
            # Clean up
            rm -f /tmp/gguf_results.json
        else
            echo "No models found containing BOTH 'gguf' AND '$search_terms'."
            echo "Showing top GGUF models instead:"
            echo "---------------------------------------"
            
            curl -s "https://huggingface.co/api/models?search=gguf&sort=downloads&direction=-1&limit=10" | \
            jq -r '[.[] | select(
                (.modelId | ascii_downcase | contains("gguf")) or
                (.tags | join(",") | ascii_downcase | contains("gguf"))
            )] | .[0:10]' > /tmp/fallback_models.json
            
            COUNT_FB=$(jq 'length' /tmp/fallback_models.json 2>/dev/null || echo "0")
            
            if [ "$COUNT_FB" -gt 0 ]; then
                # Display numbered list of models
                jq -r 'to_entries | .[] | "\(.key+1)) \(.value.modelId) (\(.value.downloads) downloads)"' /tmp/fallback_models.json
                
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
                    FB_MODEL_ID=$(jq -r ".[$((fb_choice-1))].modelId" /tmp/fallback_models.json)
                    echo "Selected model: $FB_MODEL_ID"
                    
                    # Import the selected model
                    import_from_model_id "$FB_MODEL_ID"
                else
                    echo "Invalid choice."
                    sleep 1
                    search_huggingface_models
                fi
                
                # Clean up
                rm -f /tmp/fallback_models.json
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

# Function for advanced LLM operations
advanced_llm_operations() {
    reset  # Added reset command to clear screen before showing submenu
    echo "Select an option:"
    echo "1) Fine-tune an LLM with a dataset"
    echo "2) Use embeddings for retrieval (RAG)"
    echo "3) Fine-tune the currently selected model"
    echo "4) Select a different model"
    read -p "Enter choice (1/2/3/4): " choice

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
    else
        echo "Invalid choice."
    fi
}

# New function to delete selected models
delete_models() {
    reset
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
                delete_models  # Recursive call to delete another model
            fi
        else
            echo "Deletion cancelled."
            sleep 1
            delete_models  # Return to the delete menu
        fi
    else
        echo "Invalid choice."
        sleep 1
        delete_models  # Return to the delete menu on invalid input
    fi
}

# Main function with menu - updated with delete option
main() {
    reset
    echo "===== Ollama Management Tool ====="
    echo "1) Install/Update and Run Model (Current: $SELECTED_MODEL)"
    echo "2) Import/Search for a Model from Huggingace.co"
    echo "3) Advanced LLM Operations (Train The Model, Fine-tune)"
    echo "4) Delete Models"
    echo "5) Exit"
    echo "=================================="
    read -p "Enter your choice (1-5): " main_choice

    case $main_choice in
        1) reset; install_and_run_model ;;
        2) import_huggingface_model ;;
        3) advanced_llm_operations ;;
        4) delete_models ;;
        5) echo "Exiting..."; exit 0 ;;
        *) echo "Invalid option. Please try again."; sleep 1; main ;;
    esac
    
    # Return to main menu after function completes
    read -p "Press Enter to return to main menu..."
    reset
    main
}

# Start the script
main