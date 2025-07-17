#!/usr/bin/env python3
"""
OllamaTrauma - Cross-Platform Ollama Management Tool (Python Version)

A comprehensive Python script for managing Ollama models across Linux, macOS, and Windows platforms.
Provides the same functionality as the shell script but with Python's cross-platform capabilities.

Author: ShaddGallegos
Repository: https://github.com/ShaddGallegos/OllamaTrauma
"""

import os
import sys
import subprocess
import platform
import shutil
import json
import tempfile
import urllib.request
import urllib.error
from pathlib import Path
from typing import Optional, Dict, List, Tuple


class OllamaTrauma:
    """Main class for OllamaTrauma functionality"""
    
    def __init__(self):
        self.os_type = platform.system().lower()
        self.temp_dir = tempfile.gettempdir()
        self.ollama_models_dir = self._get_ollama_models_dir()
        
    def _get_ollama_models_dir(self) -> str:
        """Get the Ollama models directory based on OS"""
        if self.os_type == "windows":
            return os.path.join(os.environ.get("USERPROFILE", ""), ".ollama", "models")
        else:
            return os.path.join(os.path.expanduser("~"), ".ollama", "models")
    
    def clear_screen(self):
        """Clear the terminal screen"""
        if self.os_type == "windows":
            os.system("cls")
        else:
            os.system("clear")
    
    def print_header(self):
        """Print the application header"""
        print("=" * 50)
        print("🚀 OllamaTrauma - Cross-Platform Ollama Management Tool")
        print("=" * 50)
        print(f"Platform: {platform.system()} {platform.release()}")
        print(f"Python: {sys.version.split()[0]}")
        print("=" * 50)
    
    def print_menu(self):
        """Print the main menu"""
        print("\n===== Ollama Management Tool =====")
        print("1) Install/Update and Run Models")
        print("2) Import Model from HuggingFace")
        print("3) Advanced LLM Operations")
        print("4) Delete Models")
        print("5) Exit")
        print("==================================")
    
    def run_command(self, command: str, shell: bool = True, capture_output: bool = False) -> Tuple[int, str, str]:
        """Run a system command and return return code, stdout, stderr"""
        try:
            if capture_output:
                result = subprocess.run(
                    command, 
                    shell=shell, 
                    capture_output=True, 
                    text=True,
                    timeout=300
                )
                return result.returncode, result.stdout, result.stderr
            else:
                result = subprocess.run(command, shell=shell, text=True)
                return result.returncode, "", ""
        except subprocess.TimeoutExpired:
            return -1, "", "Command timed out"
        except Exception as e:
            return -1, "", str(e)
    
    def check_dependency(self, command: str) -> bool:
        """Check if a command/dependency is available"""
        return shutil.which(command) is not None
    
    def install_dependency(self, dependency: str) -> bool:
        """Install a dependency based on the operating system"""
        print(f"Installing {dependency}...")
        
        if self.os_type == "linux":
            return self._install_linux_dependency(dependency)
        elif self.os_type == "darwin":  # macOS
            return self._install_macos_dependency(dependency)
        elif self.os_type == "windows":
            return self._install_windows_dependency(dependency)
        else:
            print(f"Unsupported operating system: {self.os_type}")
            return False
    
    def _install_linux_dependency(self, dependency: str) -> bool:
        """Install dependency on Linux"""
        # Try different package managers
        package_managers = [
            ("apt", f"sudo apt update && sudo apt install -y {dependency}"),
            ("dnf", f"sudo dnf install -y {dependency}"),
            ("yum", f"sudo yum install -y {dependency}"),
            ("pacman", f"sudo pacman -S --noconfirm {dependency}"),
            ("zypper", f"sudo zypper install -y {dependency}")
        ]
        
        for pm, command in package_managers:
            if self.check_dependency(pm):
                print(f"Using {pm} to install {dependency}...")
                returncode, _, _ = self.run_command(command)
                return returncode == 0
        
        print("No supported package manager found for Linux")
        return False
    
    def _install_macos_dependency(self, dependency: str) -> bool:
        """Install dependency on macOS"""
        # Try Homebrew first, then MacPorts
        if self.check_dependency("brew"):
            print(f"Using Homebrew to install {dependency}...")
            returncode, _, _ = self.run_command(f"brew install {dependency}")
            return returncode == 0
        elif self.check_dependency("port"):
            print(f"Using MacPorts to install {dependency}...")
            returncode, _, _ = self.run_command(f"sudo port install {dependency}")
            return returncode == 0
        else:
            print("Neither Homebrew nor MacPorts found. Please install one of them.")
            return False
    
    def _install_windows_dependency(self, dependency: str) -> bool:
        """Install dependency on Windows"""
        # Try winget, chocolatey, or scoop
        package_managers = [
            ("winget", f"winget install {dependency}"),
            ("choco", f"choco install {dependency} -y"),
            ("scoop", f"scoop install {dependency}")
        ]
        
        for pm, command in package_managers:
            if self.check_dependency(pm):
                print(f"Using {pm} to install {dependency}...")
                returncode, _, _ = self.run_command(command)
                return returncode == 0
        
        print("No supported package manager found for Windows")
        print("Please install winget, chocolatey, or scoop")
        return False
    
    def install_ollama(self) -> bool:
        """Install or update Ollama"""
        print("Checking Ollama installation...")
        
        if self.check_dependency("ollama"):
            print("Ollama is already installed. Checking for updates...")
            # Try to update Ollama
            returncode, stdout, stderr = self.run_command("ollama --help", capture_output=True)
            if "update" in stdout.lower():
                print("Updating Ollama...")
                returncode, _, _ = self.run_command("ollama update")
                if returncode == 0:
                    print("✅ Ollama updated successfully!")
                else:
                    print("⚠️  Update command failed, but Ollama is still available")
            else:
                print("Update command not available in this version of Ollama")
            return True
        
        print("Installing Ollama...")
        if self.os_type in ["linux", "darwin"]:
            # Use the official install script
            install_command = "curl -fsSL https://ollama.com/install.sh | sh"
            returncode, _, _ = self.run_command(install_command)
            if returncode == 0:
                print("✅ Ollama installed successfully!")
                return True
            else:
                print("❌ Failed to install Ollama")
                return False
        else:
            print("For Windows, please download and install Ollama from https://ollama.com")
            return False
    
    def list_models(self) -> List[str]:
        """List installed Ollama models"""
        if not self.check_dependency("ollama"):
            print("Ollama is not installed!")
            return []
        
        returncode, stdout, stderr = self.run_command("ollama list", capture_output=True)
        if returncode == 0:
            models = []
            lines = stdout.strip().split('\n')
            for line in lines[1:]:  # Skip header
                if line.strip():
                    model_name = line.split()[0]
                    models.append(model_name)
            return models
        else:
            print(f"Failed to list models: {stderr}")
            return []
    
    def pull_model(self, model_name: str) -> bool:
        """Pull a model from Ollama registry"""
        if not self.check_dependency("ollama"):
            print("Ollama is not installed!")
            return False
        
        print(f"Pulling model: {model_name}")
        returncode, _, stderr = self.run_command(f"ollama pull {model_name}")
        if returncode == 0:
            print(f"✅ Model {model_name} pulled successfully!")
            return True
        else:
            print(f"❌ Failed to pull model {model_name}: {stderr}")
            return False
    
    def run_model(self, model_name: str):
        """Run a model interactively"""
        if not self.check_dependency("ollama"):
            print("Ollama is not installed!")
            return
        
        print(f"Starting {model_name}...")
        print("=" * 50)
        print(f"✅ {model_name.upper()} IS NOW RUNNING!")
        print("=" * 50)
        print("\nCONNECT TO:")
        print(f"   ollama run {model_name}")
        print("\nDISCONNECT FROM:")
        print("   /bye or /exit")
        print("\nTO SHUT IT DOWN:")
        print(f"   ollama stop {model_name}")
        print("=" * 50)
        
        # Run the model
        self.run_command(f"ollama run {model_name}")
    
    def delete_model(self, model_name: str) -> bool:
        """Delete a model"""
        if not self.check_dependency("ollama"):
            print("Ollama is not installed!")
            return False
        
        print(f"Deleting model: {model_name}")
        returncode, _, stderr = self.run_command(f"ollama rm {model_name}")
        if returncode == 0:
            print(f"✅ Model {model_name} deleted successfully!")
            return True
        else:
            print(f"❌ Failed to delete model {model_name}: {stderr}")
            return False
    
    def import_huggingface_model(self):
        """Import a model from HuggingFace"""
        print("\n=== Import Model from HuggingFace ===")
        print("Examples:")
        print("- TheBloke/Mistral-7B-Instruct-v0.1-GGUF")
        print("- NousResearch/Nous-Hermes-2-Yi-34B-GGUF")
        print("- microsoft/DialoGPT-medium-GGUF")
        print()
        
        model_url = input("Enter HuggingFace model URL: ").strip()
        if not model_url:
            print("No URL provided!")
            return
        
        # Extract model name from URL
        if model_url.startswith("hf.co/"):
            model_url = model_url[6:]  # Remove "hf.co/" prefix
        elif model_url.startswith("https://huggingface.co/"):
            model_url = model_url[23:]  # Remove "https://huggingface.co/" prefix
        
        model_name = model_url.split('/')[-1]
        print(f"Model name: {model_name}")
        
        # Check and install dependencies
        if not self.check_dependency("git"):
            print("Git is required for cloning repositories")
            if not self.install_dependency("git"):
                print("❌ Failed to install Git")
                return
        
        if not self.check_dependency("git-lfs"):
            print("Git LFS is required for large file support")
            if not self.install_dependency("git-lfs"):
                print("❌ Failed to install Git LFS")
                return
        
        # Initialize Git LFS
        self.run_command("git lfs install")
        
        # Clone the repository
        repo_url = f"https://huggingface.co/{model_url}"
        clone_dir = os.path.join(self.temp_dir, model_name)
        
        # Remove existing directory if it exists
        if os.path.exists(clone_dir):
            shutil.rmtree(clone_dir)
        
        print(f"Cloning repository from {repo_url}...")
        returncode, _, stderr = self.run_command(f"git clone {repo_url} {clone_dir}")
        if returncode != 0:
            print(f"❌ Failed to clone repository: {stderr}")
            return
        
        # Find GGUF files
        gguf_files = []
        for root, dirs, files in os.walk(clone_dir):
            for file in files:
                if file.endswith('.gguf'):
                    gguf_files.append(os.path.join(root, file))
        
        if not gguf_files:
            print("❌ No GGUF files found in the repository!")
            print("Make sure the model supports GGUF format.")
            return
        
        gguf_file = gguf_files[0]
        gguf_filename = os.path.basename(gguf_file)
        print(f"Found GGUF file: {gguf_filename}")
        
        # Create Modelfile
        modelfile_content = f'''FROM "./{gguf_filename}"
TEMPLATE """
<|system|> {{{{ .System }}}} <|end|>
<|user|> {{{{ .Prompt }}}} <|end|>
<|assistant|> {{{{ .Response }}}} <|end|>
"""
'''
        
        modelfile_path = os.path.join(clone_dir, "Modelfile")
        with open(modelfile_path, 'w') as f:
            f.write(modelfile_content)
        
        print("Created Modelfile")
        
        # Create model in Ollama
        print(f"Creating model {model_name} in Ollama...")
        original_dir = os.getcwd()
        os.chdir(clone_dir)
        
        try:
            returncode, _, stderr = self.run_command(f"ollama create {model_name} -f Modelfile")
            if returncode == 0:
                print(f"✅ Model {model_name} created successfully!")
                
                # Ask if user wants to run the model
                choice = input(f"Do you want to run {model_name} now? (y/n): ").lower()
                if choice in ['y', 'yes']:
                    self.run_model(model_name)
            else:
                print(f"❌ Failed to create model: {stderr}")
        finally:
            os.chdir(original_dir)
    
    def advanced_operations(self):
        """Advanced LLM operations menu"""
        print("\n=== Advanced LLM Operations ===")
        print("1) Fine-tune an LLM with a dataset")
        print("2) Use embeddings for retrieval (RAG)")
        print("3) Fine-tune an LLM in Ollama")
        print("4) Back to main menu")
        
        choice = input("Enter your choice (1-4): ").strip()
        
        if choice == "1":
            self.finetune_with_dataset()
        elif choice == "2":
            self.create_embeddings()
        elif choice == "3":
            self.finetune_in_ollama()
        elif choice == "4":
            return
        else:
            print("Invalid choice!")
    
    def finetune_with_dataset(self):
        """Fine-tune an LLM with a custom dataset"""
        print("\n=== Fine-tune LLM with Dataset ===")
        model_name = input("Enter model name (e.g., mistral): ").strip()
        dataset_file = input("Enter dataset file path: ").strip()
        
        if not model_name or not dataset_file:
            print("Model name and dataset file are required!")
            return
        
        if not os.path.exists(dataset_file):
            print(f"Dataset file not found: {dataset_file}")
            return
        
        print("This feature requires a custom training script (train.py)")
        print("Creating a basic training script template...")
        
        # Create a basic training script template
        train_script = '''#!/usr/bin/env python3
"""
Basic training script template for fine-tuning LLMs
This is a placeholder - implement your specific training logic here
"""

import argparse
import json

def main():
    parser = argparse.ArgumentParser(description='Fine-tune LLM')
    parser.add_argument('--model', required=True, help='Model name')
    parser.add_argument('--data', required=True, help='Dataset file')
    parser.add_argument('--epochs', type=int, default=3, help='Number of epochs')
    
    args = parser.parse_args()
    
    print(f"Fine-tuning model: {args.model}")
    print(f"Dataset: {args.data}")
    print(f"Epochs: {args.epochs}")
    
    # TODO: Implement your fine-tuning logic here
    print("This is a placeholder for fine-tuning implementation")
    print("Please implement your specific training logic")

if __name__ == "__main__":
    main()
'''
        
        with open("train.py", "w") as f:
            f.write(train_script)
        
        print("Created train.py template")
        print("Please implement your specific training logic in train.py")
    
    def create_embeddings(self):
        """Create embeddings for RAG"""
        print("\n=== Create Embeddings for RAG ===")
        text_data = input("Enter text data for embedding: ").strip()
        
        if not text_data:
            print("No text data provided!")
            return
        
        try:
            # Try to import sentence-transformers
            import sentence_transformers
            from sentence_transformers import SentenceTransformer
            
            print("Loading SentenceTransformer model...")
            model = SentenceTransformer('all-MiniLM-L6-v2')
            
            print("Creating embedding...")
            embedding = model.encode(text_data)
            
            print("Embedding created successfully!")
            print(f"Embedding shape: {embedding.shape}")
            print(f"Embedding (first 10 values): {embedding[:10]}")
            
        except ImportError:
            print("sentence-transformers not installed. Installing...")
            returncode, _, _ = self.run_command("pip install sentence-transformers")
            if returncode == 0:
                print("Please run this option again to create embeddings")
            else:
                print("Failed to install sentence-transformers")
    
    def finetune_in_ollama(self):
        """Fine-tune model directly in Ollama"""
        print("\n=== Fine-tune LLM in Ollama ===")
        dataset_file = input("Enter dataset file path: ").strip()
        
        if not dataset_file:
            print("Dataset file is required!")
            return
        
        if not os.path.exists(dataset_file):
            print(f"Dataset file not found: {dataset_file}")
            return
        
        print("Note: Direct fine-tuning in Ollama may not be available in all versions")
        print("This feature depends on Ollama's fine-tuning capabilities")
        
        # Try to fine-tune (this might not work in all Ollama versions)
        returncode, stdout, stderr = self.run_command(
            f"ollama finetune mistral --data {dataset_file} --output fine_tuned_model.gguf",
            capture_output=True
        )
        
        if returncode == 0:
            print("✅ Fine-tuning completed successfully!")
            print(stdout)
        else:
            print("❌ Fine-tuning failed or not supported in this Ollama version")
            print(stderr)
    
    def delete_models_menu(self):
        """Display models and allow deletion"""
        print("\n=== Delete Models ===")
        models = self.list_models()
        
        if not models:
            print("No models found!")
            return
        
        print("Installed models:")
        for i, model in enumerate(models, 1):
            print(f"{i}) {model}")
        
        print(f"{len(models) + 1}) Back to main menu")
        
        try:
            choice = int(input("Enter model number to delete: "))
            if 1 <= choice <= len(models):
                model_name = models[choice - 1]
                confirm = input(f"Are you sure you want to delete {model_name}? (y/n): ")
                if confirm.lower() in ['y', 'yes']:
                    self.delete_model(model_name)
            elif choice == len(models) + 1:
                return
            else:
                print("Invalid choice!")
        except ValueError:
            print("Please enter a valid number!")
    
    def install_update_run_models(self):
        """Install/Update Ollama and run models"""
        print("\n=== Install/Update and Run Models ===")
        
        # Install or update Ollama
        if not self.install_ollama():
            return
        
        # List available models
        models = self.list_models()
        print(f"Currently installed models: {len(models)}")
        
        # Check if Mistral is installed
        if "mistral" not in [model.split(':')[0] for model in models]:
            print("Mistral model not found. Pulling...")
            if not self.pull_model("mistral"):
                return
        
        # Run Mistral
        self.run_model("mistral")
    
    def main_menu(self):
        """Main application loop"""
        while True:
            self.clear_screen()
            self.print_header()
            self.print_menu()
            
            choice = input("Enter your choice (1-5): ").strip()
            
            if choice == "1":
                self.install_update_run_models()
            elif choice == "2":
                self.import_huggingface_model()
            elif choice == "3":
                self.advanced_operations()
            elif choice == "4":
                self.delete_models_menu()
            elif choice == "5":
                print("Goodbye!")
                sys.exit(0)
            else:
                print("Invalid choice! Please try again.")
            
            input("\nPress Enter to continue...")


def main():
    """Main entry point"""
    # Check Python version
    if sys.version_info < (3, 6):
        print("Python 3.6 or higher is required!")
        sys.exit(1)
    
    # Create and run the application
    app = OllamaTrauma()
    try:
        app.main_menu()
    except KeyboardInterrupt:
        print("\n\nExiting...")
        sys.exit(0)
    except Exception as e:
        print(f"An error occurred: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
