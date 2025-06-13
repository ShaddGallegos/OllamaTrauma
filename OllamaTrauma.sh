#!/bin/bash

# Function to install/update Ollama and run Mistral
install_and_run_mistral() {
    # Check if Ollama is installed
    if ! command -v ollama &> /dev/null; then
        echo "Ollama not found. Installing..."
        curl -fsSL https://ollama.com/install.sh | sh
    else
        echo "Updating Ollama..."
        ollama update
    fi

    # Pull the latest Mistral model if not already available
    if ! ollama list | grep -q "mistral"; then
        echo "Downloading Mistral model..."
        ollama pull mistral
    fi

    # Run the model
    echo "Starting the Mistral LLM..."
    ollama run mistral
}

# Function to import model from Hugging Face
import_huggingface_model() {
    # Prompt user for the Hugging Face model URL
    read -p "Enter Hugging Face model URL (e.g., hf.co/Ansible-Model/santacoder-finetuned-alanstack-ec2): " model_url

    # Extract model name
    model_name=$(basename "$model_url")

    # Install Git LFS if needed
    echo "Ensuring Git LFS is installed..."
    git lfs install

    # Clone the model repository
    echo "Cloning the model repository..."
    git clone "https://huggingface.co/$model_url"

    # Navigate into model directory
    cd "$model_name" || { echo "Model folder not found"; exit 1; }

    # Find GGUF model file
    gguf_file=$(ls | grep ".gguf" | head -n 1)

    # Check if a GGUF file exists
    if [ -z "$gguf_file" ]; then
        echo "No GGUF file found in the repository. Make sure the model supports GGUF format."
        return 1
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

    # Run the model
    echo "Starting the model..."
    ollama run "$model_name"
}

# Function for advanced LLM operations
advanced_llm_operations() {
    echo "Select an option:"
    echo "1) Fine-tune an LLM with a dataset"
    echo "2) Use embeddings for retrieval (RAG)"
    echo "3) Fine-tune an LLM in Ollama"
    read -p "Enter choice (1/2/3): " choice

    if [ "$choice" -eq 1 ]; then
        # Fine-tuning the LLM
        read -p "Enter model name (e.g., mistral): " model_name
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
        # Fine-tuning an LLM with Ollama
        read -p "Enter dataset file (e.g., my_dataset.json): " dataset

        echo "Fine-tuning model in Ollama..."
        ollama finetune mistral --data "$dataset" --output fine_tuned_model.gguf

    else
        echo "Invalid choice."
    fi
}

# Main function with menu
main() {
    clear
    echo "===== Ollama Management Tool ====="
    echo "1) Install/Update and Run Mistral"
    echo "2) Import Model from Hugging Face"
    echo "3) Advanced LLM Operations (Train The Model, Fine-tune)"
    echo "4) Exit"
    echo "=================================="
    read -p "Enter your choice (1-4): " main_choice

    case $main_choice in
        1) install_and_run_mistral ;;
        2) import_huggingface_model ;;
        3) advanced_llm_operations ;;
        4) echo "Exiting..."; exit 0 ;;
        *) echo "Invalid option. Please try again."; main ;;
    esac
    
    # Return to main menu after function completes
    read -p "Press Enter to return to main menu..."
    main
}

# Start the script
main