#!/usr/bin/env python3
"""
OllamaTrauma Python Cross-Platform Script
Compatible with Linux, macOS, Windows, and Ansible
Version: 2.0
"""

import os
import sys
import json
import subprocess
import platform
import logging
import argparse
import time
import shutil
from pathlib import Path
from typing import Dict, List, Optional, Tuple
from datetime import datetime

# Color codes for cross-platform output
class Colors:
    if os.name == 'nt':  # Windows
        try:
            import colorama
            colorama.init()
            RED = '\033[91m'
            GREEN = '\033[92m'
            YELLOW = '\033[93m'
            BLUE = '\033[94m'
            PURPLE = '\033[95m'
            CYAN = '\033[96m'
            WHITE = '\033[97m'
            BOLD = '\033[1m'
            RESET = '\033[0m'
        except ImportError:
            RED = GREEN = YELLOW = BLUE = PURPLE = CYAN = WHITE = BOLD = RESET = ''
    else:
        RED = '\033[91m'
        GREEN = '\033[92m'
        YELLOW = '\033[93m'
        BLUE = '\033[94m'
        PURPLE = '\033[95m'
        CYAN = '\033[96m'
        WHITE = '\033[97m'
        BOLD = '\033[1m'
        RESET = '\033[0m'

class OllamaTrauma:
    def __init__(self, config_dir: Optional[str] = None):
        self.script_dir = Path(__file__).parent
        self.config_dir = Path(config_dir) if config_dir else self.script_dir
        self.config_file = self.config_dir / "ollama_config.json"
        self.log_file = self.config_dir / "ollama_trauma.log"
        
        # Ensure directories exist
        self.config_dir.mkdir(exist_ok=True)
        
        # Set up logging
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(levelname)s - %(message)s',
            handlers=[
                logging.FileHandler(self.log_file),
                logging.StreamHandler()
            ]
        )
        self.logger = logging.getLogger(__name__)
        
        # Initialize configuration
        self.config = self.load_config()
        self.selected_model = self.config.get('selected_model', 'mistral')
        
        # Detect system information
        self.os_info = self.detect_os()
        self.is_ansible = self.detect_ansible()
        
        self.logger.info(f"OllamaTrauma Python v2.0 initialized on {self.os_info['system']}")

    def detect_os(self) -> Dict[str, str]:
        """Detect operating system and package manager."""
        system = platform.system().lower()
        
        os_info = {
            'system': system,
            'release': platform.release(),
            'architecture': platform.architecture()[0],
            'package_manager': 'unknown'
        }
        
        if system == 'darwin':
            os_info['package_manager'] = 'brew'
        elif system == 'linux':
            if shutil.which('dnf'):
                os_info['package_manager'] = 'dnf'
            elif shutil.which('apt'):
                os_info['package_manager'] = 'apt'
            elif shutil.which('yum'):
                os_info['package_manager'] = 'yum'
            elif shutil.which('pacman'):
                os_info['package_manager'] = 'pacman'
            elif shutil.which('zypper'):
                os_info['package_manager'] = 'zypper'
        elif system == 'windows':
            if shutil.which('winget'):
                os_info['package_manager'] = 'winget'
            elif shutil.which('choco'):
                os_info['package_manager'] = 'choco'
            elif shutil.which('scoop'):
                os_info['package_manager'] = 'scoop'
        
        # Check for WSL
        if 'wsl' in os.environ.get('WSL_DISTRO_NAME', '').lower():
            os_info['system'] = 'wsl'
            os_info['package_manager'] = 'apt'
        
        return os_info

    def detect_ansible(self) -> bool:
        """Check if running under Ansible."""
        ansible_vars = [
            'ANSIBLE_STDOUT_CALLBACK',
            'ANSIBLE_REMOTE_USER',
            'ANSIBLE_PLAYBOOK',
            'ANSIBLE_INVENTORY'
        ]
        return any(var in os.environ for var in ansible_vars)

    def log_message(self, level: str, message: str, color: str = ''):
        """Log message with color support."""
        if color:
            print(f"{color}[{level}]{Colors.RESET} {message}")
        else:
            print(f"[{level}] {message}")
        
        # Also log to file
        getattr(self.logger, level.lower(), self.logger.info)(message)

    def load_config(self) -> Dict:
        """Load configuration from JSON file."""
        if self.config_file.exists():
            try:
                with open(self.config_file, 'r') as f:
                    return json.load(f)
            except (json.JSONDecodeError, IOError) as e:
                self.logger.warning(f"Failed to load config: {e}")
        
        return {
            'selected_model': 'mistral',
            'last_updated': datetime.utcnow().isoformat() + 'Z'
        }

    def save_config(self):
        """Save configuration to JSON file."""
        self.config.update({
            'selected_model': self.selected_model,
            'os_info': self.os_info,
            'last_updated': datetime.utcnow().isoformat() + 'Z'
        })
        
        try:
            with open(self.config_file, 'w') as f:
                json.dump(self.config, f, indent=2)
            self.logger.debug(f"Configuration saved to {self.config_file}")
        except IOError as e:
            self.logger.error(f"Failed to save config: {e}")

    def run_command(self, cmd: List[str], capture_output: bool = True, 
                   timeout: Optional[int] = None) -> Tuple[bool, str, str]:
        """Run a system command with cross-platform support."""
        try:
            if capture_output:
                result = subprocess.run(
                    cmd, 
                    capture_output=True, 
                    text=True, 
                    timeout=timeout,
                    shell=(self.os_info['system'] == 'windows')
                )
                return result.returncode == 0, result.stdout, result.stderr
            else:
                result = subprocess.run(
                    cmd, 
                    timeout=timeout,
                    shell=(self.os_info['system'] == 'windows')
                )
                return result.returncode == 0, '', ''
        except subprocess.TimeoutExpired:
            self.logger.error(f"Command timed out: {' '.join(cmd)}")
            return False, '', 'Command timed out'
        except Exception as e:
            self.logger.error(f"Command failed: {e}")
            return False, '', str(e)

    def install_package(self, package: str, package_map: Optional[Dict[str, str]] = None) -> bool:
        """Install a package using the appropriate package manager."""
        if package_map is None:
            package_map = {}
        
        system = self.os_info['system']
        pkg_mgr = self.os_info['package_manager']
        
        # Get package name for this system
        pkg_name = package_map.get(system, package_map.get(pkg_mgr, package))
        
        self.log_message('INFO', f"Installing package: {pkg_name}", Colors.YELLOW)
        
        install_commands = {
            'apt': ['sudo', 'apt', 'update', '&&', 'sudo', 'apt', 'install', '-y', pkg_name],
            'dnf': ['sudo', 'dnf', 'install', '-y', pkg_name],
            'yum': ['sudo', 'yum', 'install', '-y', pkg_name],
            'pacman': ['sudo', 'pacman', '-S', '--noconfirm', pkg_name],
            'zypper': ['sudo', 'zypper', 'install', '-y', pkg_name],
            'brew': ['brew', 'install', pkg_name],
            'winget': ['winget', 'install', pkg_name],
            'choco': ['choco', 'install', '-y', pkg_name],
            'scoop': ['scoop', 'install', pkg_name]
        }
        
        if pkg_mgr in install_commands:
            cmd = install_commands[pkg_mgr]
            success, stdout, stderr = self.run_command(cmd, timeout=300)
            
            if success:
                self.log_message('INFO', f"Successfully installed {pkg_name}", Colors.GREEN)
                return True
            else:
                self.log_message('ERROR', f"Failed to install {pkg_name}: {stderr}", Colors.RED)
                return False
        else:
            self.log_message('ERROR', f"Unknown package manager: {pkg_mgr}", Colors.RED)
            return False

    def check_dependencies(self) -> bool:
        """Check and install required dependencies."""
        self.log_message('INFO', "Checking dependencies...", Colors.CYAN)
        
        dependencies = {
            'curl': {
                'windows': 'curl',
                'winget': 'curl',
                'choco': 'curl'
            },
            'jq': {
                'windows': 'jqlang.jq',
                'winget': 'jqlang.jq',
                'choco': 'jq'
            },
            'git': {
                'windows': 'Git.Git',
                'winget': 'Git.Git',
                'choco': 'git'
            }
        }
        
        all_installed = True
        
        for dep, package_map in dependencies.items():
            if not shutil.which(dep):
                self.log_message('WARN', f"{dep} not found. Installing...", Colors.YELLOW)
                if not self.install_package(dep, package_map):
                    all_installed = False
            else:
                self.log_message('INFO', f"{dep} is already installed", Colors.GREEN)
        
        # Check Python packages
        python_packages = ['requests', 'beautifulsoup4', 'colorama']
        for pkg in python_packages:
            try:
                __import__(pkg)
                self.log_message('INFO', f"Python package {pkg} is available", Colors.GREEN)
            except ImportError:
                self.log_message('WARN', f"Installing Python package: {pkg}", Colors.YELLOW)
                success, _, _ = self.run_command([
                    sys.executable, '-m', 'pip', 'install', '--user', pkg
                ])
                if not success:
                    self.log_message('WARN', f"Failed to install {pkg}", Colors.YELLOW)
        
        return all_installed

    def is_ollama_running(self) -> bool:
        """Check if Ollama service is running."""
        success, _, _ = self.run_command(['curl', '-s', 'http://localhost:11434/api/tags'])
        return success

    def start_ollama_service(self) -> bool:
        """Start Ollama service."""
        if self.is_ollama_running():
            self.log_message('INFO', "Ollama service is already running", Colors.GREEN)
            return True
        
        self.log_message('INFO', "Starting Ollama service...", Colors.YELLOW)
        
        # Try different methods based on OS
        if self.os_info['system'] == 'darwin' and shutil.which('brew'):
            success, _, _ = self.run_command(['brew', 'services', 'start', 'ollama'])
        elif self.os_info['system'] in ['linux', 'wsl'] and shutil.which('systemctl'):
            success, _, _ = self.run_command(['sudo', 'systemctl', 'start', 'ollama'])
        else:
            # Fallback: start as background process
            success, _, _ = self.run_command(['ollama', 'serve'], capture_output=False)
        
        # Wait for service to be ready
        for _ in range(30):
            if self.is_ollama_running():
                self.log_message('INFO', "Ollama service started successfully", Colors.GREEN)
                return True
            time.sleep(1)
        
        self.log_message('ERROR', "Failed to start Ollama service", Colors.RED)
        return False

    def install_ollama(self) -> bool:
        """Install Ollama."""
        if shutil.which('ollama'):
            self.log_message('INFO', "Ollama is already installed", Colors.GREEN)
            return True
        
        self.log_message('INFO', "Installing Ollama...", Colors.YELLOW)
        
        if self.os_info['system'] == 'darwin':
            if shutil.which('brew'):
                success, _, _ = self.run_command(['brew', 'install', 'ollama'])
            else:
                success, _, _ = self.run_command([
                    'curl', '-fsSL', 'https://ollama.ai/install.sh'
                ])
                if success:
                    success, _, _ = self.run_command(['sh'], capture_output=False)
        
        elif self.os_info['system'] in ['linux', 'wsl']:
            success, _, _ = self.run_command([
                'bash', '-c', 'curl -fsSL https://ollama.ai/install.sh | sh'
            ])
        
        elif self.os_info['system'] == 'windows':
            self.log_message('ERROR', 
                "Please install Ollama manually from https://ollama.ai/download", 
                Colors.RED)
            return False
        
        else:
            self.log_message('ERROR', f"Unsupported OS: {self.os_info['system']}", Colors.RED)
            return False
        
        return success

    def list_models(self) -> List[str]:
        """List available Ollama models."""
        if not shutil.which('ollama'):
            return []
        
        success, stdout, _ = self.run_command(['ollama', 'list'])
        if not success:
            return []
        
        models = []
        for line in stdout.strip().split('\n')[1:]:  # Skip header
            if line.strip():
                model_name = line.split()[0]
                models.append(model_name)
        
        return models

    def pull_model(self, model_name: str) -> bool:
        """Pull a model from Ollama."""
        self.log_message('INFO', f"Pulling model: {model_name}", Colors.YELLOW)
        
        success, stdout, stderr = self.run_command(['ollama', 'pull', model_name], timeout=1800)
        
        if success:
            self.log_message('INFO', f"Successfully pulled {model_name}", Colors.GREEN)
            return True
        else:
            self.log_message('ERROR', f"Failed to pull {model_name}: {stderr}", Colors.RED)
            return False

    def remove_model(self, model_name: str) -> bool:
        """Remove a model from Ollama."""
        self.log_message('INFO', f"Removing model: {model_name}", Colors.YELLOW)
        
        success, stdout, stderr = self.run_command(['ollama', 'rm', model_name])
        
        if success:
            self.log_message('INFO', f"Successfully removed {model_name}", Colors.GREEN)
            return True
        else:
            self.log_message('ERROR', f"Failed to remove {model_name}: {stderr}", Colors.RED)
            return False

    def run_model_interactive(self, model_name: str):
        """Run model in interactive mode."""
        if self.is_ansible:
            self.log_message('INFO', f"Ansible mode: Model {model_name} is ready", Colors.GREEN)
            return
        
        self.log_message('INFO', f"Starting interactive session with {model_name}", Colors.GREEN)
        print(f"{Colors.GREEN}Starting {model_name}... (Ctrl+C to exit){Colors.RESET}")
        
        try:
            subprocess.run(['ollama', 'run', model_name], check=True)
        except KeyboardInterrupt:
            print(f"\n{Colors.YELLOW}Session ended.{Colors.RESET}")
        except subprocess.CalledProcessError as e:
            self.log_message('ERROR', f"Failed to run {model_name}: {e}", Colors.RED)

    def clear_screen(self):
        """Clear terminal screen."""
        if not self.is_ansible:
            os.system('cls' if os.name == 'nt' else 'clear')

    def pause(self, message: str = "Press Enter to continue..."):
        """Pause execution for user input."""
        if not self.is_ansible:
            input(f"{Colors.CYAN}{message}{Colors.RESET}")

    def select_model_interactive(self):
        """Interactive model selection."""
        while True:
            self.clear_screen()
            print(f"{Colors.BOLD}{Colors.BLUE}=== Model Selection ==={Colors.RESET}")
            print(f"Current model: {Colors.GREEN}{self.selected_model}{Colors.RESET}")
            print()
            print("Popular models:")
            print("1) mistral (7B) - Fast and efficient")
            print("2) llama2 (7B) - Meta's base model")
            print("3) llama2:13b (13B) - Larger variant")
            print("4) codellama (7B) - Code-focused model")
            print("5) phi (2.7B) - Microsoft's small model")
            print("6) Custom model name")
            print("7) Return to main menu")
            print()
            
            try:
                choice = input("Enter your choice (1-7): ").strip()
                
                if choice == '1':
                    self.selected_model = 'mistral'
                elif choice == '2':
                    self.selected_model = 'llama2'
                elif choice == '3':
                    self.selected_model = 'llama2:13b'
                elif choice == '4':
                    self.selected_model = 'codellama'
                elif choice == '5':
                    self.selected_model = 'phi'
                elif choice == '6':
                    custom_model = input("Enter custom model name: ").strip()
                    if custom_model:
                        self.selected_model = custom_model
                elif choice == '7':
                    break
                else:
                    self.log_message('WARN', "Invalid choice", Colors.YELLOW)
                    time.sleep(1)
                    continue
                
                self.log_message('INFO', f"Selected model: {self.selected_model}", Colors.GREEN)
                self.save_config()
                break
                
            except KeyboardInterrupt:
                break

    def install_and_run_model(self):
        """Install Ollama and run the selected model."""
        self.clear_screen()
        
        # Install Ollama if needed
        if not self.install_ollama():
            return
        
        # Start Ollama service
        if not self.start_ollama_service():
            return
        
        # Check if model exists
        available_models = self.list_models()
        if self.selected_model not in [m.split(':')[0] for m in available_models]:
            if not self.pull_model(self.selected_model):
                return
        
        # Run model
        self.run_model_interactive(self.selected_model)

    def advanced_operations(self):
        """Advanced operations menu."""
        while True:
            self.clear_screen()
            print(f"{Colors.BOLD}{Colors.PURPLE}=== Advanced Operations ==={Colors.RESET}")
            print("1) List all models")
            print("2) Remove models")
            print("3) Model information")
            print("4) System information")
            print("5) Return to main menu")
            print()
            
            if self.is_ansible:
                choice = os.environ.get('ANSIBLE_ADVANCED_CHOICE', '5')
                self.log_message('INFO', f"Ansible mode: Using advanced choice {choice}", Colors.CYAN)
            else:
                choice = input("Enter your choice (1-5): ").strip()
            
            if choice == '1':
                models = self.list_models()
                if models:
                    print(f"{Colors.GREEN}Available models:{Colors.RESET}")
                    for model in models:
                        print(f"  - {model}")
                else:
                    print(f"{Colors.YELLOW}No models installed.{Colors.RESET}")
                self.pause()
                
            elif choice == '2':
                models = self.list_models()
                if not models:
                    print(f"{Colors.YELLOW}No models to remove.{Colors.RESET}")
                    self.pause()
                    continue
                
                print(f"{Colors.GREEN}Available models:{Colors.RESET}")
                for i, model in enumerate(models, 1):
                    print(f"{i}) {model}")
                
                if not self.is_ansible:
                    try:
                        idx = int(input("Select model to remove (number): ")) - 1
                        if 0 <= idx < len(models):
                            model_to_remove = models[idx]
                            confirm = input(f"Remove {model_to_remove}? (y/N): ").lower()
                            if confirm == 'y':
                                self.remove_model(model_to_remove)
                                if model_to_remove == self.selected_model:
                                    self.selected_model = 'mistral'
                                    self.save_config()
                        else:
                            print("Invalid selection.")
                    except (ValueError, KeyboardInterrupt):
                        pass
                self.pause()
                
            elif choice == '3':
                if shutil.which('ollama'):
                    success, stdout, _ = self.run_command(['ollama', '--version'])
                    if success:
                        print(f"{Colors.GREEN}Ollama version:{Colors.RESET}")
                        print(stdout)
                    
                    success, stdout, _ = self.run_command(['ollama', 'show', self.selected_model])
                    if success:
                        print(f"{Colors.GREEN}Current model info:{Colors.RESET}")
                        print(stdout)
                    else:
                        print(f"{Colors.YELLOW}Model {self.selected_model} not found.{Colors.RESET}")
                else:
                    print(f"{Colors.RED}Ollama not installed.{Colors.RESET}")
                self.pause()
                
            elif choice == '4':
                print(f"{Colors.GREEN}System Information:{Colors.RESET}")
                print(f"OS: {self.os_info['system']} {self.os_info['release']}")
                print(f"Architecture: {self.os_info['architecture']}")
                print(f"Package Manager: {self.os_info['package_manager']}")
                print(f"Python Version: {sys.version}")
                print(f"Script Directory: {self.script_dir}")
                print(f"Config Directory: {self.config_dir}")
                print(f"Current Model: {self.selected_model}")
                print(f"Ansible Mode: {'Yes' if self.is_ansible else 'No'}")
                self.pause()
                
            elif choice == '5':
                break
            else:
                self.log_message('WARN', "Invalid option", Colors.YELLOW)
                if not self.is_ansible:
                    time.sleep(1)

    def main_menu(self):
        """Main application menu."""
        while True:
            self.clear_screen()
            print(f"{Colors.BOLD}{Colors.CYAN}===================================={Colors.RESET}")
            print(f"{Colors.BOLD}{Colors.CYAN}    OllamaTrauma Python v2.0       {Colors.RESET}")
            print(f"{Colors.BOLD}{Colors.CYAN}===================================={Colors.RESET}")
            print()
            print(f"Current OS: {Colors.GREEN}{self.os_info['system']}{Colors.RESET}")
            print(f"Current Model: {Colors.GREEN}{self.selected_model}{Colors.RESET}")
            if self.is_ansible:
                print(f"Mode: {Colors.YELLOW}Ansible Automation{Colors.RESET}")
            else:
                print(f"Mode: {Colors.BLUE}Interactive{Colors.RESET}")
            print()
            print("1) Install/Run Ollama Model")
            print("2) Select Different Model")
            print("3) Advanced Operations")
            print("4) View Logs")
            print("5) Exit")
            print("====================================")
            
            if self.is_ansible:
                choice = os.environ.get('ANSIBLE_MAIN_CHOICE', '1')
                self.log_message('INFO', f"Ansible mode: Using main choice {choice}", Colors.CYAN)
            else:
                choice = input("Enter your choice (1-5): ").strip()
            
            try:
                if choice == '1':
                    self.install_and_run_model()
                elif choice == '2':
                    self.select_model_interactive()
                elif choice == '3':
                    self.advanced_operations()
                elif choice == '4':
                    if self.log_file.exists():
                        print(f"{Colors.GREEN}Recent log entries:{Colors.RESET}")
                        with open(self.log_file, 'r') as f:
                            lines = f.readlines()
                            for line in lines[-20:]:
                                print(line.rstrip())
                    else:
                        print(f"{Colors.YELLOW}No log file found.{Colors.RESET}")
                    self.pause()
                elif choice == '5':
                    self.log_message('INFO', "Exiting OllamaTrauma", Colors.GREEN)
                    print(f"{Colors.GREEN}Thank you for using OllamaTrauma!{Colors.RESET}")
                    break
                else:
                    self.log_message('WARN', f"Invalid option: {choice}", Colors.YELLOW)
                    if not self.is_ansible:
                        time.sleep(1)
                
                # In Ansible mode, exit after one operation
                if self.is_ansible:
                    self.log_message('INFO', "Ansible operation completed", Colors.CYAN)
                    break
                    
            except KeyboardInterrupt:
                print(f"\n{Colors.YELLOW}Operation cancelled by user.{Colors.RESET}")
                if not self.is_ansible:
                    time.sleep(1)
                else:
                    break

    def run(self):
        """Main entry point."""
        try:
            # Check dependencies unless skipped in Ansible
            if not self.is_ansible or not os.environ.get('ANSIBLE_SKIP_DEPS'):
                self.check_dependencies()
            
            # Start main menu
            self.main_menu()
            
        except KeyboardInterrupt:
            print(f"\n{Colors.YELLOW}Application terminated by user.{Colors.RESET}")
        except Exception as e:
            self.log_message('ERROR', f"Unexpected error: {e}", Colors.RED)
            raise
        finally:
            self.save_config()

def main():
    """Command line entry point."""
    parser = argparse.ArgumentParser(
        description='OllamaTrauma - Cross-Platform Ollama Management Tool'
    )
    parser.add_argument(
        '--config-dir', 
        help='Configuration directory path',
        type=str
    )
    parser.add_argument(
        '--model',
        help='Set selected model',
        type=str
    )
    parser.add_argument(
        '--install-only',
        help='Install Ollama and dependencies only',
        action='store_true'
    )
    parser.add_argument(
        '--version',
        help='Show version information',
        action='version',
        version='OllamaTrauma Python v2.0'
    )
    
    args = parser.parse_args()
    
    # Create application instance
    app = OllamaTrauma(config_dir=args.config_dir)
    
    # Set model if specified
    if args.model:
        app.selected_model = args.model
        app.save_config()
    
    # Handle install-only mode
    if args.install_only:
        app.check_dependencies()
        app.install_ollama()
        return
    
    # Run main application
    app.run()

if __name__ == '__main__':
    main()
