#!/bin/bash

# Colors for messages
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Print formatted messages
print_message() {
    echo -e "${BLUE}[Messenger]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[✔] $1${NC}"
}

print_error() {
    echo -e "${RED}[✘] $1${NC}"
}

# Facebook Messenger chat URL
MESSENGER_URL="https://www.facebook.com/messages/e2ee/t/9009777702403556"

# RaybanAI service URL para verificar
RAYBANAI_URL="http://localhost:3103"

# El código de RaybanAI
RAYBAN_CODE="(function(){const API_URL='http://localhost:3103/api/raybanai';const resultDiv=document.createElement('div');resultDiv.style.cssText='position:fixed;bottom:20px;right:20px;background:rgba(0,0,0,0.8);color:white;padding:15px;border-radius:8px;z-index:9999;max-width:300px;font-family:Arial;';document.body.appendChild(resultDiv);let lastProcessedTime=Date.now();async function processImage(imgSrc){if(Date.now()-lastProcessedTime<1000)return;lastProcessedTime=Date.now();if(imgSrc.includes('profile')||imgSrc.includes('avatar'))return;resultDiv.textContent='Analyzing image...';console.log('Processing:',imgSrc);try{const response=await fetch(API_URL,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({type:'url',imageUrl:imgSrc})});const data=await response.json();console.log('Response:',data);resultDiv.textContent=data.response||data.description;}catch(error){console.error('Error:',error);resultDiv.textContent='Error processing image';}}const observer=new MutationObserver(mutations=>{for(const mutation of mutations){const addedNodes=Array.from(mutation.addedNodes);for(const node of addedNodes){if(node.nodeType===1&&node.classList&&node.classList.contains('x78zum5')){const images=node.getElementsByTagName('img');if(images.length>0){const lastImage=images[images.length-1];if(!lastImage.dataset.processed){lastImage.dataset.processed='true';processImage(lastImage.src);return;}}}}}});const chatContainer=document.querySelector('[role=\"main\"]');if(chatContainer){observer.observe(chatContainer,{childList:true,subtree:true});console.log('Observer started');resultDiv.textContent='Observer activated - Last images only';}else{console.error('Chat not found');resultDiv.textContent='Error: Chat not found';}})();"

# Archivo temporal para la notificación
HELP_FILE="/tmp/raybanai-code-help.html"

# Verificar si el servicio RaybanAI está en ejecución
is_raybanai_running() {
    if curl -s "$RAYBANAI_URL" -o /dev/null; then
        return 0  # true, is running
    else
        return 1  # false, not running
    fi
}

# Crear un archivo HTML con el código RaybanAI que sea fácil de copiar
cat > "$HELP_FILE" << EOL
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Código RaybanAI</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            background-color: #1e1e1e;
            color: #ddd;
            padding: 15px;
            margin: 0;
            line-height: 1.5;
        }
        h1 {
            color: #fff;
            font-size: 18px;
            margin-top: 0;
            margin-bottom: 15px;
            text-align: center;
        }
        .code-container {
            background-color: #2d2d2d;
            border-radius: 5px;
            padding: 10px;
            margin-bottom: 15px;
            border: 1px solid #3e3e3e;
        }
        #code-area {
            background-color: #262626;
            color: #e5c07b;
            font-family: monospace;
            font-size: 12px;
            padding: 10px;
            width: 100%;
            box-sizing: border-box;
            border: none;
            border-radius: 3px;
            height: 100px;
            resize: none;
            margin-bottom: 10px;
            white-space: pre-wrap;
            word-break: break-all;
            overflow-wrap: anywhere;
        }
        .button {
            background-color: #0078d7;
            color: #fff;
            border: none;
            border-radius: 4px;
            padding: 10px 15px;
            font-size: 14px;
            cursor: pointer;
            width: 100%;
            text-align: center;
            margin-bottom: 10px;
        }
        .copy-button {
            background-color: #107c10;
        }
        .instructions {
            background-color: rgba(255, 255, 255, 0.1);
            padding: 10px;
            border-radius: 5px;
            margin-bottom: 15px;
        }
        .step {
            margin-bottom: 8px;
            display: flex;
            align-items: flex-start;
        }
        .step-number {
            display: inline-block;
            width: 20px;
            height: 20px;
            background-color: #0078d7;
            color: white;
            border-radius: 50%;
            text-align: center;
            line-height: 20px;
            margin-right: 8px;
            flex-shrink: 0;
        }
        #status {
            color: #70c7ff;
            text-align: center;
            margin-top: 10px;
            min-height: 20px;
        }
    </style>
</head>
<body>
    <h1>Código RaybanAI para Messenger</h1>
    
    <div class="instructions">
        <div class="step">
            <div class="step-number">1</div>
            <div>En Messenger, pulsa F12 para abrir la consola de desarrollador</div>
        </div>
        <div class="step">
            <div class="step-number">2</div>
            <div>Haz clic en "Copiar código" abajo</div>
        </div>
        <div class="step">
            <div class="step-number">3</div>
            <div>Pega el código en la consola del navegador y presiona Enter</div>
        </div>
    </div>
    
    <div class="code-container">
        <textarea id="code-area" readonly>${RAYBAN_CODE}</textarea>
        <button id="copy-button" class="button copy-button">COPIAR CÓDIGO</button>
    </div>
    
    <div id="status"></div>
    
    <script>
        // Referencias a elementos
        const codeArea = document.getElementById('code-area');
        const copyButton = document.getElementById('copy-button');
        const status = document.getElementById('status');
        
        // Seleccionar todo el código al hacer clic en el textarea
        codeArea.addEventListener('click', function() {
            this.select();
        });
        
        // Copiar código al hacer clic en el botón
        copyButton.addEventListener('click', function() {
            codeArea.select();
            
            try {
                // Intentar usar clipboard API
                if (navigator.clipboard && navigator.clipboard.writeText) {
                    navigator.clipboard.writeText(codeArea.value)
                        .then(function() {
                            status.textContent = '✓ Código copiado al portapapeles';
                            setTimeout(() => { status.textContent = ''; }, 2000);
                        })
                        .catch(function(err) {
                            // Si falla, usar el método alternativo
                            tryCopyFallback();
                        });
                } else {
                    // Si no está disponible clipboard API, usar método alternativo
                    tryCopyFallback();
                }
            } catch(e) {
                tryCopyFallback();
            }
        });
        
        // Método alternativo para copiar
        function tryCopyFallback() {
            try {
                const successful = document.execCommand('copy');
                if (successful) {
                    status.textContent = '✓ Código copiado al portapapeles';
                } else {
                    status.textContent = 'No se pudo copiar automáticamente. Selecciona el código manualmente.';
                }
                setTimeout(() => { status.textContent = ''; }, 2000);
            } catch (err) {
                status.textContent = 'No se pudo copiar. Selecciona el código manualmente con Ctrl+A y luego Ctrl+C';
                setTimeout(() => { status.textContent = ''; }, 3000);
            }
        }
        
        // Inicializar
        window.addEventListener('load', function() {
            // Seleccionar el código automáticamente al cargar
            codeArea.focus();
            codeArea.select();
        });
    </script>
</body>
</html>
EOL

# Verificar si el servicio RaybanAI está en ejecución
if ! is_raybanai_running; then
    print_message "El servicio RaybanAI no está en ejecución"
    zenity --question --title="RaybanAI" --text="El servicio RaybanAI no está en ejecución.\n\n¿Desea iniciarlo antes de continuar?" --ok-label="Iniciar" --cancel-label="Cancelar"
    
    if [ $? -eq 0 ]; then
        # Intentar iniciar el servicio
        RAYBANAI_WEB_SCRIPT="$HOME/Documents/git/reliczero/ForWebIcons/launch-raybanai-web.sh"
        if [ -f "$RAYBANAI_WEB_SCRIPT" ]; then
            print_message "Iniciando servicio RaybanAI..."
            bash "$RAYBANAI_WEB_SCRIPT"
            sleep 5
        else
            print_error "No se encontró el script para iniciar el servicio"
            zenity --error --text="No se pudo iniciar el servicio RaybanAI.\nPor favor, inicie el servicio manualmente antes de continuar."
            exit 1
        fi
    else
        exit 0
    fi
fi

# Verificar nuevamente si el servicio está en ejecución
if ! is_raybanai_running; then
    print_error "No se pudo conectar al servicio RaybanAI"
    zenity --error --text="No se pudo conectar a RaybanAI en $RAYBANAI_URL\nAsegúrese de que el servicio esté en ejecución."
    exit 1
fi

# Detectar navegador instalado (prioridad: chromium)
if command -v chromium-browser &> /dev/null; then
    BROWSER="chromium-browser"
elif command -v chromium &> /dev/null; then
    BROWSER="chromium"
elif command -v firefox &> /dev/null; then
    BROWSER="firefox"
else
    BROWSER="xdg-open"
fi

# Mostrar ayuda con el código RaybanAI
print_message "Mostrando ayuda con el código RaybanAI..."
$BROWSER --app="file://$HELP_FILE" --window-size=320,480 --window-position=320,0 &

# Dejar unos segundos para que se abra la ventana de ayuda
sleep 1

# Abrir Messenger con consola de desarrollador activa
print_message "Abriendo Messenger con consola de desarrollador..."
case $BROWSER in
    "chromium-browser"|"chromium")
        $BROWSER --auto-open-devtools-for-tabs "$MESSENGER_URL" --window-size=320,480 --window-position=0,0
        ;;
    "firefox")
        # Firefox no tiene una opción para abrir DevTools automáticamente
        firefox -width 320 -height 480 "$MESSENGER_URL"
        ;;
    *)
        $BROWSER "$MESSENGER_URL"
        ;;
esac

print_success "Messenger abierto con consola de desarrollador"
exit 0
