package com.ollamatrauma;

import java.io.*;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.file.*;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.concurrent.TimeUnit;
import java.util.regex.Pattern;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;

/**
 * OllamaTrauma Java Cross-Platform Application
 * Compatible with Windows, macOS, Linux, and integrates with existing ecosystem
 * Version: 2.0
 */
public class OllamaTrauma {
    
    // Constants
    private static final String VERSION = "2.0";
    private static final String DEFAULT_MODEL = "mistral";
    private static final int OLLAMA_PORT = 11434;
    private static final String OLLAMA_API_URL = "http://localhost:" + OLLAMA_PORT;
    private static final int SERVICE_START_TIMEOUT = 30;
    private static final int MODEL_PULL_TIMEOUT = 1800; // 30 minutes
    
    // ANSI Color codes
    public static class Colors {
        public static final String RESET = "\033[0m";
        public static final String RED = "\033[31m";
        public static final String GREEN = "\033[32m";
        public static final String YELLOW = "\033[33m";
        public static final String BLUE = "\033[34m";
        public static final String PURPLE = "\033[35m";
        public static final String CYAN = "\033[36m";
        public static final String WHITE = "\033[37m";
        public static final String BOLD = "\033[1m";
        
        // Disable colors on Windows unless explicitly enabled
        static {
            if (System.getProperty("os.name").toLowerCase().contains("windows") 
                && System.getenv("FORCE_COLOR") == null) {
                // Windows typically doesn't support ANSI colors in standard console
                disableColors();
            }
        }
        
        private static void disableColors() {
            try {
                java.lang.reflect.Field[] fields = Colors.class.getFields();
                for (java.lang.reflect.Field field : fields) {
                    if (field.getType() == String.class) {
                        field.set(null, "");
                    }
                }
            } catch (Exception e) {
                // Ignore reflection errors
            }
        }
    }
    
    // System information
    public static class SystemInfo {
        public final String osName;
        public final String osVersion;
        public final String osArch;
        public final String javaVersion;
        public final String packageManager;
        public final boolean isWindows;
        public final boolean isMacOS;
        public final boolean isLinux;
        public final boolean isWSL;
        
        public SystemInfo() {
            this.osName = System.getProperty("os.name").toLowerCase();
            this.osVersion = System.getProperty("os.version");
            this.osArch = System.getProperty("os.arch");
            this.javaVersion = System.getProperty("java.version");
            
            this.isWindows = osName.contains("windows");
            this.isMacOS = osName.contains("mac") || osName.contains("darwin");
            this.isLinux = osName.contains("linux");
            this.isWSL = isLinux && (System.getenv("WSL_DISTRO_NAME") != null || 
                                   System.getenv("WSLENV") != null);
            
            this.packageManager = detectPackageManager();
        }
        
        private String detectPackageManager() {
            if (isWindows) {
                if (commandExists("winget")) return "winget";
                if (commandExists("choco")) return "choco";
                if (commandExists("scoop")) return "scoop";
                return "unknown";
            } else if (isMacOS) {
                if (commandExists("brew")) return "brew";
                if (commandExists("port")) return "port";
                return "unknown";
            } else if (isLinux || isWSL) {
                if (commandExists("dnf")) return "dnf";
                if (commandExists("apt")) return "apt";
                if (commandExists("yum")) return "yum";
                if (commandExists("pacman")) return "pacman";
                if (commandExists("zypper")) return "zypper";
                return "unknown";
            }
            return "unknown";
        }
    }
    
    // Configuration management
    public static class Config {
        private String selectedModel;
        private SystemInfo systemInfo;
        private LocalDateTime lastUpdated;
        private boolean managedByAnsible;
        private Path configFile;
        private ObjectMapper mapper;
        
        public Config(Path configDir) throws IOException {
            this.mapper = new ObjectMapper();
            this.configFile = configDir.resolve("ollama_config.json");
            this.systemInfo = new SystemInfo();
            this.selectedModel = DEFAULT_MODEL;
            this.lastUpdated = LocalDateTime.now();
            this.managedByAnsible = isAnsibleMode();
            
            if (Files.exists(configFile)) {
                loadConfig();
            }
        }
        
        private void loadConfig() {
            try {
                JsonNode config = mapper.readTree(configFile.toFile());
                this.selectedModel = config.path("selected_model").asText(DEFAULT_MODEL);
                this.managedByAnsible = config.path("managed_by_ansible").asBoolean(false);
            } catch (Exception e) {
                System.err.println("Warning: Failed to load config: " + e.getMessage());
            }
        }
        
        public void save() {
            try {
                ObjectNode config = mapper.createObjectNode();
                config.put("selected_model", selectedModel);
                config.put("java_version", systemInfo.javaVersion);
                config.put("os_name", systemInfo.osName);
                config.put("os_version", systemInfo.osVersion);
                config.put("os_arch", systemInfo.osArch);
                config.put("package_manager", systemInfo.packageManager);
                config.put("last_updated", lastUpdated.format(DateTimeFormatter.ISO_LOCAL_DATE_TIME));
                config.put("managed_by_ansible", managedByAnsible);
                
                Files.createDirectories(configFile.getParent());
                mapper.writerWithDefaultPrettyPrinter().writeValue(configFile.toFile(), config);
            } catch (Exception e) {
                System.err.println("Warning: Failed to save config: " + e.getMessage());
            }
        }
        
        // Getters and setters
        public String getSelectedModel() { return selectedModel; }
        public void setSelectedModel(String model) { 
            this.selectedModel = model; 
            this.lastUpdated = LocalDateTime.now();
        }
        public SystemInfo getSystemInfo() { return systemInfo; }
        public boolean isManagedByAnsible() { return managedByAnsible; }
    }
    
    // Main application class
    private final Config config;
    private final Path configDir;
    private final Path logFile;
    private final Scanner scanner;
    private final boolean isAnsible;
    private final boolean quiet;
    
    public OllamaTrauma(String configDirPath, boolean quiet) throws IOException {
        this.quiet = quiet;
        this.scanner = new Scanner(System.in);
        this.isAnsible = isAnsibleMode();
        
        // Setup directories
        if (configDirPath != null) {
            this.configDir = Paths.get(configDirPath);
        } else {
            String userHome = System.getProperty("user.home");
            this.configDir = Paths.get(userHome, ".ollama_trauma");
        }
        
        Files.createDirectories(configDir);
        this.logFile = configDir.resolve("ollama_trauma.log");
        this.config = new Config(configDir);
        
        logMessage("INFO", "OllamaTrauma Java v" + VERSION + " initialized on " + 
                   config.getSystemInfo().osName);
    }
    
    // Utility methods
    private static boolean isAnsibleMode() {
        return System.getenv("ANSIBLE_STDOUT_CALLBACK") != null ||
               System.getenv("ANSIBLE_REMOTE_USER") != null ||
               System.getenv("ANSIBLE_PLAYBOOK") != null;
    }
    
    private static boolean commandExists(String command) {
        try {
            Process process;
            if (System.getProperty("os.name").toLowerCase().contains("windows")) {
                process = new ProcessBuilder("where", command).start();
            } else {
                process = new ProcessBuilder("which", command).start();
            }
            return process.waitFor() == 0;
        } catch (Exception e) {
            return false;
        }
    }
    
    private void logMessage(String level, String message) {
        String timestamp = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"));
        String logEntry = String.format("[%s] [%s] %s", timestamp, level, message);
        
        // Write to log file
        try {
            Files.write(logFile, (logEntry + System.lineSeparator()).getBytes(), 
                       StandardOpenOption.CREATE, StandardOpenOption.APPEND);
        } catch (IOException e) {
            // Ignore log file write errors
        }
        
        // Write to console with colors
        if (!quiet) {
            String coloredMessage = colorizeLogMessage(level, message);
            System.out.println(coloredMessage);
        }
    }
    
    private String colorizeLogMessage(String level, String message) {
        String color = Colors.WHITE;
        switch (level.toUpperCase()) {
            case "ERROR": color = Colors.RED; break;
            case "WARN": color = Colors.YELLOW; break;
            case "INFO": color = Colors.GREEN; break;
            case "DEBUG": color = Colors.CYAN; break;
        }
        return color + "[" + level + "]" + Colors.RESET + " " + message;
    }
    
    private CommandResult runCommand(String... command) throws IOException, InterruptedException {
        return runCommand(Arrays.asList(command), null, 0);
    }
    
    private CommandResult runCommand(List<String> command, Path workingDir, int timeoutSeconds) 
            throws IOException, InterruptedException {
        ProcessBuilder pb = new ProcessBuilder(command);
        if (workingDir != null) {
            pb.directory(workingDir.toFile());
        }
        
        pb.redirectErrorStream(true);
        Process process = pb.start();
        
        boolean finished;
        if (timeoutSeconds > 0) {
            finished = process.waitFor(timeoutSeconds, TimeUnit.SECONDS);
            if (!finished) {
                process.destroyForcibly();
                return new CommandResult(1, "", "Command timed out");
            }
        } else {
            process.waitFor();
        }
        
        String output = readProcessOutput(process);
        return new CommandResult(process.exitValue(), output, "");
    }
    
    private String readProcessOutput(Process process) throws IOException {
        StringBuilder output = new StringBuilder();
        try (BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()))) {
            String line;
            while ((line = reader.readLine()) != null) {
                output.append(line).append(System.lineSeparator());
            }
        }
        return output.toString();
    }
    
    private static class CommandResult {
        public final int exitCode;
        public final String output;
        public final String error;
        
        public CommandResult(int exitCode, String output, String error) {
            this.exitCode = exitCode;
            this.output = output;
            this.error = error;
        }
        
        public boolean isSuccess() {
            return exitCode == 0;
        }
    }
    
    // Package management
    private boolean installPackage(String packageName, Map<String, String> packageMap) {
        SystemInfo sysInfo = config.getSystemInfo();
        String actualPackage = packageMap.getOrDefault(sysInfo.packageManager, packageName);
        
        logMessage("INFO", "Installing package: " + actualPackage);
        
        try {
            List<String> command = new ArrayList<>();
            
            switch (sysInfo.packageManager) {
                case "winget":
                    command.addAll(Arrays.asList("winget", "install", actualPackage));
                    break;
                case "choco":
                    command.addAll(Arrays.asList("choco", "install", "-y", actualPackage));
                    break;
                case "scoop":
                    command.addAll(Arrays.asList("scoop", "install", actualPackage));
                    break;
                case "brew":
                    command.addAll(Arrays.asList("brew", "install", actualPackage));
                    break;
                case "apt":
                    // Update cache first
                    runCommand("sudo", "apt", "update");
                    command.addAll(Arrays.asList("sudo", "apt", "install", "-y", actualPackage));
                    break;
                case "dnf":
                    command.addAll(Arrays.asList("sudo", "dnf", "install", "-y", actualPackage));
                    break;
                case "yum":
                    command.addAll(Arrays.asList("sudo", "yum", "install", "-y", actualPackage));
                    break;
                case "pacman":
                    command.addAll(Arrays.asList("sudo", "pacman", "-S", "--noconfirm", actualPackage));
                    break;
                default:
                    logMessage("ERROR", "Unknown package manager: " + sysInfo.packageManager);
                    return false;
            }
            
            CommandResult result = runCommand(command, null, 300); // 5 minute timeout
            
            if (result.isSuccess()) {
                logMessage("INFO", "Successfully installed " + actualPackage);
                return true;
            } else {
                logMessage("ERROR", "Failed to install " + actualPackage + ": " + result.error);
                return false;
            }
            
        } catch (Exception e) {
            logMessage("ERROR", "Exception installing " + actualPackage + ": " + e.getMessage());
            return false;
        }
    }
    
    private boolean checkDependencies() {
        logMessage("INFO", "Checking dependencies...");
        
        Map<String, Map<String, String>> dependencies = new HashMap<>();
        
        // curl dependency
        Map<String, String> curlMap = new HashMap<>();
        curlMap.put("winget", "curl");
        curlMap.put("choco", "curl");
        dependencies.put("curl", curlMap);
        
        // git dependency
        Map<String, String> gitMap = new HashMap<>();
        gitMap.put("winget", "Git.Git");
        gitMap.put("choco", "git");
        dependencies.put("git", gitMap);
        
        // jq dependency (optional)
        Map<String, String> jqMap = new HashMap<>();
        jqMap.put("winget", "jqlang.jq");
        jqMap.put("choco", "jq");
        dependencies.put("jq", jqMap);
        
        boolean allInstalled = true;
        
        for (Map.Entry<String, Map<String, String>> entry : dependencies.entrySet()) {
            String dep = entry.getKey();
            if (!commandExists(dep)) {
                logMessage("WARN", dep + " not found. Installing...");
                if (!installPackage(dep, entry.getValue())) {
                    if (!dep.equals("jq")) { // jq is optional
                        allInstalled = false;
                    }
                }
            } else {
                logMessage("INFO", dep + " is already installed");
            }
        }
        
        return allInstalled;
    }
    
    // Ollama management
    private boolean isOllamaRunning() {
        try {
            URL url = new URL(OLLAMA_API_URL + "/api/tags");
            HttpURLConnection conn = (HttpURLConnection) url.openConnection();
            conn.setRequestMethod("GET");
            conn.setConnectTimeout(5000);
            conn.setReadTimeout(5000);
            
            int responseCode = conn.getResponseCode();
            conn.disconnect();
            return responseCode == 200;
        } catch (Exception e) {
            return false;
        }
    }
    
    private boolean startOllamaService() {
        if (isOllamaRunning()) {
            logMessage("INFO", "Ollama service is already running");
            return true;
        }
        
        logMessage("INFO", "Starting Ollama service...");
        
        try {
            SystemInfo sysInfo = config.getSystemInfo();
            
            if (sysInfo.isWindows) {
                // Windows: Start as background process
                new ProcessBuilder("ollama", "serve").start();
            } else if (sysInfo.isMacOS && commandExists("brew")) {
                runCommand("brew", "services", "start", "ollama");
            } else {
                // Linux/Unix: Start as background process
                new ProcessBuilder("ollama", "serve").start();
            }
            
            // Wait for service to be ready
            for (int i = 0; i < SERVICE_START_TIMEOUT; i++) {
                if (isOllamaRunning()) {
                    logMessage("INFO", "Ollama service started successfully");
                    return true;
                }
                Thread.sleep(1000);
            }
            
            logMessage("ERROR", "Ollama service failed to start within " + SERVICE_START_TIMEOUT + " seconds");
            return false;
            
        } catch (Exception e) {
            logMessage("ERROR", "Failed to start Ollama service: " + e.getMessage());
            return false;
        }
    }
    
    private boolean installOllama() {
        if (commandExists("ollama")) {
            logMessage("INFO", "Ollama is already installed");
            return true;
        }
        
        logMessage("INFO", "Installing Ollama...");
        
        try {
            SystemInfo sysInfo = config.getSystemInfo();
            
            if (sysInfo.isWindows) {
                logMessage("ERROR", "Please install Ollama manually from https://ollama.ai/download");
                if (!isAnsible) {
                    System.out.print("Press Enter after installation is complete...");
                    scanner.nextLine();
                }
                return commandExists("ollama");
            } else {
                // macOS and Linux: Use install script
                CommandResult result = runCommand("bash", "-c", 
                    "curl -fsSL https://ollama.ai/install.sh | sh");
                return result.isSuccess();
            }
            
        } catch (Exception e) {
            logMessage("ERROR", "Failed to install Ollama: " + e.getMessage());
            return false;
        }
    }
    
    private List<String> listModels() {
        List<String> models = new ArrayList<>();
        
        if (!commandExists("ollama")) {
            return models;
        }
        
        try {
            CommandResult result = runCommand("ollama", "list");
            if (result.isSuccess()) {
                String[] lines = result.output.split("\\r?\\n");
                for (int i = 1; i < lines.length; i++) { // Skip header
                    String line = lines[i].trim();
                    if (!line.isEmpty()) {
                        String modelName = line.split("\\s+")[0];
                        models.add(modelName);
                    }
                }
            }
        } catch (Exception e) {
            logMessage("ERROR", "Failed to list models: " + e.getMessage());
        }
        
        return models;
    }
    
    private boolean pullModel(String modelName) {
        logMessage("INFO", "Pulling model: " + modelName);
        
        try {
            CommandResult result = runCommand(Arrays.asList("ollama", "pull", modelName), 
                                            null, MODEL_PULL_TIMEOUT);
            
            if (result.isSuccess()) {
                logMessage("INFO", "Successfully pulled " + modelName);
                return true;
            } else {
                logMessage("ERROR", "Failed to pull " + modelName + ": " + result.error);
                return false;
            }
        } catch (Exception e) {
            logMessage("ERROR", "Exception pulling " + modelName + ": " + e.getMessage());
            return false;
        }
    }
    
    private boolean removeModel(String modelName) {
        logMessage("INFO", "Removing model: " + modelName);
        
        try {
            CommandResult result = runCommand("ollama", "rm", modelName);
            
            if (result.isSuccess()) {
                logMessage("INFO", "Successfully removed " + modelName);
                return true;
            } else {
                logMessage("ERROR", "Failed to remove " + modelName + ": " + result.error);
                return false;
            }
        } catch (Exception e) {
            logMessage("ERROR", "Exception removing " + modelName + ": " + e.getMessage());
            return false;
        }
    }
    
    private void runModelInteractive(String modelName) {
        if (isAnsible) {
            logMessage("INFO", "Ansible mode: Model " + modelName + " is ready");
            return;
        }
        
        logMessage("INFO", "Starting interactive session with " + modelName);
        System.out.println(Colors.GREEN + "Starting " + modelName + "... (Ctrl+C to exit)" + Colors.RESET);
        
        try {
            ProcessBuilder pb = new ProcessBuilder("ollama", "run", modelName);
            pb.inheritIO();
            Process process = pb.start();
            process.waitFor();
        } catch (Exception e) {
            logMessage("ERROR", "Failed to run " + modelName + ": " + e.getMessage());
        }
    }
    
    // UI methods
    private void clearScreen() {
        if (!isAnsible) {
            try {
                if (config.getSystemInfo().isWindows) {
                    new ProcessBuilder("cmd", "/c", "cls").inheritIO().start().waitFor();
                } else {
                    new ProcessBuilder("clear").inheritIO().start().waitFor();
                }
            } catch (Exception e) {
                // Fallback: print newlines
                for (int i = 0; i < 50; i++) {
                    System.out.println();
                }
            }
        }
    }
    
    private void pause(String message) {
        if (!isAnsible) {
            System.out.print(Colors.CYAN + message + Colors.RESET);
            scanner.nextLine();
        }
    }
    
    private String getAnsibleChoice(String envVar, String defaultValue) {
        if (isAnsible) {
            String choice = System.getenv(envVar);
            if (choice != null) {
                logMessage("INFO", "Ansible mode: Using " + envVar + " = " + choice);
                return choice;
            }
            return defaultValue;
        }
        return null;
    }
    
    // Main application logic
    public void installAndRunModel() {
        clearScreen();
        
        // Install Ollama if needed
        if (!installOllama()) {
            return;
        }
        
        // Start Ollama service
        if (!startOllamaService()) {
            return;
        }
        
        // Check if model exists
        List<String> availableModels = listModels();
        boolean modelExists = availableModels.stream()
            .anyMatch(model -> model.startsWith(config.getSelectedModel()));
        
        if (!modelExists) {
            if (!pullModel(config.getSelectedModel())) {
                return;
            }
        }
        
        // Run model
        runModelInteractive(config.getSelectedModel());
    }
    
    public void selectModel() {
        while (true) {
            clearScreen();
            System.out.println(Colors.BOLD + Colors.BLUE + "=== Model Selection ===" + Colors.RESET);
            System.out.println("Current model: " + Colors.GREEN + config.getSelectedModel() + Colors.RESET);
            System.out.println();
            System.out.println("Popular models:");
            System.out.println("1) mistral (7B) - Fast and efficient");
            System.out.println("2) llama2 (7B) - Meta's base model");
            System.out.println("3) llama2:13b (13B) - Larger variant");
            System.out.println("4) codellama (7B) - Code-focused model");
            System.out.println("5) phi (2.7B) - Microsoft's small model");
            System.out.println("6) Custom model name");
            System.out.println("7) Return to main menu");
            System.out.println();
            
            String choice = getAnsibleChoice("ANSIBLE_MODEL_CHOICE", "1");
            if (choice == null) {
                System.out.print("Enter your choice (1-7): ");
                choice = scanner.nextLine().trim();
            }
            
            switch (choice) {
                case "1":
                    config.setSelectedModel("mistral");
                    break;
                case "2":
                    config.setSelectedModel("llama2");
                    break;
                case "3":
                    config.setSelectedModel("llama2:13b");
                    break;
                case "4":
                    config.setSelectedModel("codellama");
                    break;
                case "5":
                    config.setSelectedModel("phi");
                    break;
                case "6":
                    String customModel = getAnsibleChoice("ANSIBLE_CUSTOM_MODEL", "mistral");
                    if (customModel == null) {
                        System.out.print("Enter custom model name: ");
                        customModel = scanner.nextLine().trim();
                    }
                    if (!customModel.isEmpty()) {
                        config.setSelectedModel(customModel);
                    }
                    break;
                case "7":
                    return;
                default:
                    logMessage("WARN", "Invalid choice, keeping current model: " + config.getSelectedModel());
                    if (!isAnsible) {
                        try { Thread.sleep(1000); } catch (InterruptedException e) {}
                    }
                    continue;
            }
            
            logMessage("INFO", "Selected model: " + config.getSelectedModel());
            config.save();
            break;
        }
    }
    
    public void advancedOperations() {
        while (true) {
            clearScreen();
            System.out.println(Colors.BOLD + Colors.PURPLE + "=== Advanced Operations ===" + Colors.RESET);
            System.out.println("1) List all models");
            System.out.println("2) Remove models");
            System.out.println("3) Model information");
            System.out.println("4) System information");
            System.out.println("5) Return to main menu");
            System.out.println();
            
            String choice = getAnsibleChoice("ANSIBLE_ADVANCED_CHOICE", "5");
            if (choice == null) {
                System.out.print("Enter your choice (1-5): ");
                choice = scanner.nextLine().trim();
            }
            
            switch (choice) {
                case "1":
                    List<String> models = listModels();
                    if (!models.isEmpty()) {
                        System.out.println(Colors.GREEN + "Available models:" + Colors.RESET);
                        models.forEach(model -> System.out.println("  - " + model));
                    } else {
                        System.out.println(Colors.YELLOW + "No models installed." + Colors.RESET);
                    }
                    pause("Press Enter to continue...");
                    break;
                    
                case "2":
                    removeModelsMenu();
                    break;
                    
                case "3":
                    showModelInformation();
                    break;
                    
                case "4":
                    showSystemInformation();
                    break;
                    
                case "5":
                    return;
                    
                default:
                    logMessage("WARN", "Invalid option");
                    if (!isAnsible) {
                        try { Thread.sleep(1000); } catch (InterruptedException e) {}
                    }
                    break;
            }
        }
    }
    
    private void removeModelsMenu() {
        List<String> models = listModels();
        if (models.isEmpty()) {
            System.out.println(Colors.YELLOW + "No models to remove." + Colors.RESET);
            pause("Press Enter to continue...");
            return;
        }
        
        System.out.println(Colors.GREEN + "Available models:" + Colors.RESET);
        for (int i = 0; i < models.size(); i++) {
            System.out.println((i + 1) + ") " + models.get(i));
        }
        
        if (!isAnsible) {
            try {
                System.out.print("Select model to remove (number): ");
                int index = Integer.parseInt(scanner.nextLine().trim()) - 1;
                
                if (index >= 0 && index < models.size()) {
                    String modelToRemove = models.get(index);
                    System.out.print("Remove " + modelToRemove + "? (y/N): ");
                    String confirm = scanner.nextLine().trim().toLowerCase();
                    
                    if (confirm.equals("y")) {
                        if (removeModel(modelToRemove)) {
                            if (modelToRemove.equals(config.getSelectedModel())) {
                                config.setSelectedModel(DEFAULT_MODEL);
                                config.save();
                            }
                        }
                    }
                } else {
                    System.out.println("Invalid selection.");
                }
            } catch (NumberFormatException e) {
                System.out.println("Invalid input.");
            }
        }
        pause("Press Enter to continue...");
    }
    
    private void showModelInformation() {
        if (commandExists("ollama")) {
            try {
                System.out.println(Colors.GREEN + "Ollama version:" + Colors.RESET);
                CommandResult version = runCommand("ollama", "--version");
                System.out.println(version.output);
                
                System.out.println(Colors.GREEN + "Current model info:" + Colors.RESET);
                CommandResult info = runCommand("ollama", "show", config.getSelectedModel());
                if (info.isSuccess()) {
                    System.out.println(info.output);
                } else {
                    System.out.println(Colors.YELLOW + "Model " + config.getSelectedModel() + " not found." + Colors.RESET);
                }
            } catch (Exception e) {
                System.out.println(Colors.RED + "Error getting model information: " + e.getMessage() + Colors.RESET);
            }
        } else {
            System.out.println(Colors.RED + "Ollama not installed." + Colors.RESET);
        }
        pause("Press Enter to continue...");
    }
    
    private void showSystemInformation() {
        SystemInfo sysInfo = config.getSystemInfo();
        System.out.println(Colors.GREEN + "System Information:" + Colors.RESET);
        System.out.println("OS: " + sysInfo.osName + " " + sysInfo.osVersion);
        System.out.println("Architecture: " + sysInfo.osArch);
        System.out.println("Java Version: " + sysInfo.javaVersion);
        System.out.println("Package Manager: " + sysInfo.packageManager);
        System.out.println("Config Directory: " + configDir);
        System.out.println("Log File: " + logFile);
        System.out.println("Current Model: " + config.getSelectedModel());
        System.out.println("Ansible Mode: " + (isAnsible ? "Yes" : "No"));
        System.out.println("Is Windows: " + sysInfo.isWindows);
        System.out.println("Is macOS: " + sysInfo.isMacOS);
        System.out.println("Is Linux: " + sysInfo.isLinux);
        System.out.println("Is WSL: " + sysInfo.isWSL);
        pause("Press Enter to continue...");
    }
    
    public void mainMenu() {
        while (true) {
            clearScreen();
            System.out.println(Colors.BOLD + Colors.CYAN + "====================================" + Colors.RESET);
            System.out.println(Colors.BOLD + Colors.CYAN + "    OllamaTrauma Java v" + VERSION + "       " + Colors.RESET);
            System.out.println(Colors.BOLD + Colors.CYAN + "====================================" + Colors.RESET);
            System.out.println();
            System.out.println("Current OS: " + Colors.GREEN + config.getSystemInfo().osName + Colors.RESET);
            System.out.println("Current Model: " + Colors.GREEN + config.getSelectedModel() + Colors.RESET);
            if (isAnsible) {
                System.out.println("Mode: " + Colors.YELLOW + "Ansible Automation" + Colors.RESET);
            } else {
                System.out.println("Mode: " + Colors.BLUE + "Interactive" + Colors.RESET);
            }
            System.out.println();
            System.out.println("1) Install/Run Ollama Model");
            System.out.println("2) Select Different Model");
            System.out.println("3) Advanced Operations");
            System.out.println("4) View Logs");
            System.out.println("5) Exit");
            System.out.println("====================================");
            
            String choice = getAnsibleChoice("ANSIBLE_MAIN_CHOICE", "1");
            if (choice == null) {
                System.out.print("Enter your choice (1-5): ");
                choice = scanner.nextLine().trim();
            }
            
            switch (choice) {
                case "1":
                    installAndRunModel();
                    break;
                case "2":
                    selectModel();
                    break;
                case "3":
                    advancedOperations();
                    break;
                case "4":
                    viewLogs();
                    break;
                case "5":
                    logMessage("INFO", "Exiting OllamaTrauma Java");
                    System.out.println(Colors.GREEN + "Thank you for using OllamaTrauma!" + Colors.RESET);
                    return;
                default:
                    logMessage("WARN", "Invalid option: " + choice);
                    if (!isAnsible) {
                        try { Thread.sleep(1000); } catch (InterruptedException e) {}
                    }
                    break;
            }
            
            // In Ansible mode, exit after one operation
            if (isAnsible) {
                logMessage("INFO", "Ansible operation completed");
                return;
            }
        }
    }
    
    private void viewLogs() {
        try {
            if (Files.exists(logFile)) {
                System.out.println(Colors.GREEN + "Recent log entries:" + Colors.RESET);
                List<String> lines = Files.readAllLines(logFile);
                int start = Math.max(0, lines.size() - 20);
                for (int i = start; i < lines.size(); i++) {
                    System.out.println(lines.get(i));
                }
            } else {
                System.out.println(Colors.YELLOW + "No log file found." + Colors.RESET);
            }
        } catch (Exception e) {
            System.out.println(Colors.RED + "Error reading log file: " + e.getMessage() + Colors.RESET);
        }
        pause("Press Enter to continue...");
    }
    
    public void run() {
        try {
            // Check dependencies unless skipped in Ansible
            if (!isAnsible || System.getenv("ANSIBLE_SKIP_DEPS") == null) {
                checkDependencies();
            }
            
            // Start main menu
            mainMenu();
            
        } catch (Exception e) {
            logMessage("ERROR", "Unexpected error: " + e.getMessage());
            e.printStackTrace();
        } finally {
            config.save();
            scanner.close();
        }
    }
    
    // Main method and CLI
    public static void main(String[] args) {
        String configDir = null;
        String model = null;
        boolean installOnly = false;
        boolean quiet = false;
        boolean showVersion = false;
        boolean showHelp = false;
        
        // Parse command line arguments
        for (int i = 0; i < args.length; i++) {
            switch (args[i]) {
                case "--config-dir":
                    if (i + 1 < args.length) {
                        configDir = args[++i];
                    } else {
                        System.err.println("Error: --config-dir requires a value");
                        System.exit(1);
                    }
                    break;
                case "--model":
                    if (i + 1 < args.length) {
                        model = args[++i];
                    } else {
                        System.err.println("Error: --model requires a value");
                        System.exit(1);
                    }
                    break;
                case "--install-only":
                    installOnly = true;
                    break;
                case "--quiet":
                    quiet = true;
                    break;
                case "--version":
                    showVersion = true;
                    break;
                case "--help":
                case "-h":
                    showHelp = true;
                    break;
                default:
                    System.err.println("Unknown argument: " + args[i]);
                    showHelp = true;
                    break;
            }
        }
        
        if (showVersion) {
            System.out.println("OllamaTrauma Java v" + VERSION);
            System.exit(0);
        }
        
        if (showHelp) {
            System.out.println("OllamaTrauma Java - Cross-Platform Ollama Management Tool");
            System.out.println("Usage: java -jar ollama-trauma.jar [OPTIONS]");
            System.out.println();
            System.out.println("Options:");
            System.out.println("  --config-dir DIR    Configuration directory path");
            System.out.println("  --model MODEL       Set selected model");
            System.out.println("  --install-only      Install dependencies and Ollama only");
            System.out.println("  --quiet            Suppress non-critical output");
            System.out.println("  --version          Show version information");
            System.out.println("  --help, -h         Show this help message");
            System.out.println();
            System.out.println("Examples:");
            System.out.println("  java -jar ollama-trauma.jar");
            System.out.println("  java -jar ollama-trauma.jar --model llama2");
            System.out.println("  java -jar ollama-trauma.jar --config-dir /tmp/ollama --quiet");
            System.exit(0);
        }
        
        try {
            OllamaTrauma app = new OllamaTrauma(configDir, quiet);
            
            // Set model if specified
            if (model != null) {
                app.config.setSelectedModel(model);
                app.config.save();
            }
            
            // Handle install-only mode
            if (installOnly) {
                app.checkDependencies();
                app.installOllama();
                return;
            }
            
            // Run main application
            app.run();
            
        } catch (Exception e) {
            System.err.println("Fatal error: " + e.getMessage());
            e.printStackTrace();
            System.exit(1);
        }
    }
}
