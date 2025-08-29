@echo off
setlocal

REM OllamaTrauma Java Windows Wrapper
REM Automatically detects Java and runs the application

set JAVA_EXE=java
set JAR_FILE=%~dp0ollama-trauma.jar

REM Check if we're running from the build directory
if not exist "%JAR_FILE%" (
    set JAR_FILE=%~dp0target\ollama-trauma.jar
)

REM Still not found? Try the Gradle build directory
if not exist "%JAR_FILE%" (
    set JAR_FILE=%~dp0build\libs\ollama-trauma.jar
)

REM Try to find Java
if defined JAVA_HOME (
    set JAVA_EXE=%JAVA_HOME%\bin\java
    echo Using Java from JAVA_HOME: %JAVA_EXE%
) else (
    where java >nul 2>nul
    if errorlevel 1 (
        echo Error: Java not found in PATH and JAVA_HOME not set
        echo Please install Java 11 or later and ensure it's in your PATH
        echo.
        echo You can download Java from:
        echo - Oracle JDK: https://www.oracle.com/java/technologies/downloads/
        echo - OpenJDK: https://openjdk.org/
        echo - Adoptium: https://adoptium.net/
        pause
        exit /b 1
    ) else (
        echo Using Java from PATH: %JAVA_EXE%
    )
)

REM Check Java version
echo Checking Java version...
"%JAVA_EXE%" -version 2>&1 | findstr /i "version" >nul
if errorlevel 1 (
    echo Error: Unable to determine Java version
    pause
    exit /b 1
)

REM Check if JAR file exists
if not exist "%JAR_FILE%" (
    echo Error: JAR file not found: %JAR_FILE%
    echo.
    echo Please build the project first:
    echo   mvn clean package    ^(for Maven^)
    echo   gradle shadowJar     ^(for Gradle^)
    echo.
    pause
    exit /b 1
)

REM Set JVM arguments for better performance and cross-platform compatibility
set JVM_ARGS=-XX:+UseG1GC -Xms256m -Xmx1g -Dfile.encoding=UTF-8

REM Enable ANSI colors on Windows 10+
set JVM_ARGS=%JVM_ARGS% -Dforce.color=true

REM Set environment variables for Ansible integration if not set
if not defined ANSIBLE_STDOUT_CALLBACK (
    if "%1"=="--ansible" (
        set ANSIBLE_STDOUT_CALLBACK=json
        set ANSIBLE_MAIN_CHOICE=1
        set ANSIBLE_SKIP_DEPS=true
        shift
    )
)

echo Starting OllamaTrauma Java...
echo JAR: %JAR_FILE%
echo Args: %*
echo.

REM Run the application
"%JAVA_EXE%" %JVM_ARGS% -jar "%JAR_FILE%" %*

REM Capture exit code
set EXIT_CODE=%ERRORLEVEL%

if %EXIT_CODE% neq 0 (
    echo.
    echo Application exited with code: %EXIT_CODE%
    pause
)

endlocal
exit /b %EXIT_CODE%
