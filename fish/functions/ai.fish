########################################################################
##  SnowDots — SnowAi                             Version: v1.0.0    ##
##  Last Edited: 2026-04-29                                           ##
########################################################################

function ai --description "Manage Freezer's AI Stack"
    set -l command $argv[1]

    switch "$command"
	case start
            echo "🚀 Waking up the Brain and Face..."
            sudo docker start ollama open-webui
            # The -d flag runs it in the background so your terminal stays free
            sudo docker exec -d ollama ollama run gemma2:2b --keepalive 1h
            echo "✅ 2B model pre-loading for 1 hour."
        case stop
            echo "💤 Shutting down AI suite to save resources..."
            sudo docker stop open-webui ollama
        
        case status
            echo "📊 [Container Status]"
            sudo docker ps --filter "name=ollama|open-webui" --format "table {{.Names}}\t{{.Status}}"
            echo ""
            echo "🧠 [VRAM / Models Loaded]"
            sudo docker exec -it ollama ollama ps
            
	case game
            echo "🎮 Optimizing for Gaming..."
            sudo docker exec -it ollama ollama stop gemma2:9b
            sudo docker exec -d ollama ollama run gemma2:2b --keepalive 1h
            echo "✅ VRAM cleared. 2B helper pinned for 1 hour."

        case help
            echo "Usage: ai [start|stop|status|game]"
            echo "  start  : Launch Docker containers"
            echo "  stop   : Stop Docker containers"
            echo "  status : See what's running and using VRAM"
            echo "  game   : Swap 9B for 2B to free up GPU space"

        case '*'
            ai help
    end
end
