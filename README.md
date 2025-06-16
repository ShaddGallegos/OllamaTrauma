# OllamaTrauma.sh
# Ollama Management Tool

A comprehensive bash script for managing Ollama LLM deployments, including installation, model management, and fine-tuning capabilities.

I made this as an ansible demo the bash script has more menu features the tml file needs a little mod depending which model you want to install and isnt menu driven, but still cool! 

## Features

- **Menu**
```
===== Ollama Management Tool =====
1) Install/Update and Run Mistral
2) Import Model from Huggingface.co
3) Advanced LLM Operations (Train The Model, Fine-tune)
4) Exit
==================================
Enter your choice (1-4):
```
- **Installation & Updates**: Easily install or update Ollama and run the Mistral model

- **Hugging Face Integration**: Import models directly from Hugging Face repositories

- **Advanced LLM Operations**:
  - Fine-tune models with custom datasets
  - Implement Retrieval Augmented Generation (RAG)
  - Fine-tune Mistral models directly in Ollama

## Requirements

- Linux/macOS system
- Internet connection
- Python (for fine-tuning and embedding operations)
- Git and Git LFS (for Hugging Face model imports)
- Sufficient disk space for LLM models

## Installation

1. Download the script:
   ```bash
   git clone https://github.com/yourusername/ollama-management-tool.git
   cd ollama-management-tool
   ```

2. Make the script executable:
   ```bash
   chmod +x OllamaTrauma.sh
   ```

## Usage

Run the script:
```bash
./OllamaTrauma.sh
```

### Main Menu Options

1. **Install/Update and Run Mistral**
   - Checks if Ollama is installed, installs it if needed
   - Downloads the Mistral model if not available local already
   - Runs the Mistral LLM

2. **Import Model from Hugging Face**
   - Imports GGUF models from Hugging Face repositories
   - Configures model templates
   - Creates an Ollama model from the imported weights

3. **Advanced LLM Operations**
   - Fine-tune models with custom datasets
   - Generate embeddings for RAG applications
   - Fine-tune Mistral models directly within Ollama

4. **Exit**
   - Exit the application

## Additional Information

- The script automatically returns to the main menu after each operation
- For fine-tuning, prepare your dataset in the appropriate format
- For Hugging Face imports, ensure your model has GGUF format files

## Troubleshooting

- If you encounter permission issues, make sure the script is executable
- Ensure you have an active internet connection
- For Python-related operations, ensure you have the required libraries installed

## License

This script is provided as-is under the MIT License.