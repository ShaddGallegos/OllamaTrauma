@echo off
REM OllamaTrauma - Windows Batch Launcher
REM This script detects the best environment and runs the appropriate version

echo ===== Ollama Management Tool - Windows Launcher =====
echo.

REM Check if we're in WSL
if defined WSL_DISTRO_NAME (
    echo Detected WSL environment. Running bash version...
    bash OllamaTrauma.sh
    goto :EOF
)

REM Check if we're in Git Bash or similar
if defined MSYSTEM (
    echo Detected Git Bash environment. Running bash version...
    bash OllamaTrauma.sh
    goto :EOF
)

REM Check if PowerShell is available and preferred
powershell -Command "exit 0" >nul 2>&1
if %errorlevel% equ 0 (
    echo PowerShell detected. Choose your preferred environment:
    echo 1) PowerShell ^(Recommended for Windows^)
    echo 2) Git Bash ^(if installed^)
    echo 3) Exit
    set /p choice="Enter choice (1-3): "
    
    if "!choice!"=="1" (
        echo Running PowerShell version...
        powershell -ExecutionPolicy Bypass -File OllamaTrauma.ps1
        goto :EOF
    )
    
    if "!choice!"=="2" (
        bash --version >nul 2>&1
        if !errorlevel! equ 0 (
            echo Running bash version...
            bash OllamaTrauma.sh
        ) else (
            echo Git Bash not found. Please install Git for Windows.
            echo Download from: https://git-scm.com/download/win
            pause
        )
        goto :EOF
    )
    
    if "!choice!"=="3" (
        exit /b 0
    )
    
    echo Invalid choice. Exiting...
    pause
    goto :EOF
)

REM Fallback: Try to run bash version
bash --version >nul 2>&1
if %errorlevel% equ 0 (
    echo Running bash version...
    bash OllamaTrauma.sh
) else (
    echo Neither PowerShell nor bash is available.
    echo Please install one of the following:
    echo 1) Git for Windows ^(includes bash^): https://git-scm.com/download/win
    echo 2) Windows Subsystem for Linux ^(WSL^)
    echo 3) Enable PowerShell ^(usually pre-installed^)
    pause
)

:EOF
