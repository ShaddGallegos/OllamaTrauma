#!/bin/bash
# Monitor batch download progress

clear
echo "==================================================================="
echo "  OllamaTrauma Batch Download Monitor"
echo "==================================================================="
echo ""
echo "Press Ctrl+C to stop monitoring (download will continue)"
echo ""

while true; do
    echo "==================================================================="
    echo "Time: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "───────────────────────────────────────────────────────────────────"
    
    # Show downloaded models
    echo ""
    echo "Downloaded Models:"
    if command -v ollama &>/dev/null; then
        ollama list 2>/dev/null || echo "  (Ollama not running yet)"
    else
        echo "  (Ollama not installed yet)"
    fi
    
    # Show disk space
    echo ""
    echo "Disk Space:"
    df -h / | grep -E "Filesystem|/dev/mapper" | head -2
    
    echo ""
    echo "==================================================================="
    echo "Refreshing in 10 seconds... (Ctrl+C to exit)"
    
    sleep 10
    clear
done
