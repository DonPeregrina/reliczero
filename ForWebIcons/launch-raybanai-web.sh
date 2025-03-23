#!/bin/bash

# Colors for messages
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Print formatted messages
print_message() {
    echo -e "${BLUE}[Messenger RaybanAI]${NC} $1"
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

# El código del bookmarklet (para copiarlo en el portapapeles)
BOOKMARKLET_CODE="(function(){const API_URL='http://localhost:3103/api/raybanai';const resultDiv=document.createElement('div');resultDiv.style.cssText='position:fixed;bottom:20px;right:20px;background:rgba(0,0,0,0.8);color:white;padding:15px;border-radius:8px;z-index:9999;max-width:300px;font-family:Arial;';document.body.appendChild(resultDiv);let lastProcessedTime=Date.now();async function processImage(imgSrc){if(Date.now()-lastProcessedTime<1000)return;lastProcessedTime=Date.now();if(imgSrc.includes('profile')||imgSrc.includes('avatar'))return;resultDiv.textContent='Analyzing image...';console.log('Processing:',imgSrc);try{const response=await fetch(API_URL,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({type:'url',imageUrl:imgSrc})});const data=await response.json();console.log('Response:',data);resultDiv.textContent=data.response||data.description;}catch(error){console.error('Error:',error);resultDiv.textContent='Error processing image';}}const observer=new MutationObserver(mutations=>{for(const mutation of mutations){const addedNodes=Array.from(mutation.addedNodes);for(const node of addedNodes){if(node.nodeType===1&&node.classList&&node.classList.contains('x78zum5')){const images=node.getElementsByTagName('img');if(images.length>0){const lastImage=images[images.length-1];if(!lastImage.dataset.processed){lastImage.dataset.processed='true';processImage(lastImage.src);return;}}}}}});const chatContainer=document.querySelector('[role=\"main\"]');if(chatContainer){observer.observe(chatContainer,{childList:true,subtree:true});console.log('Observer started');resultDiv.textContent='Observer activated - Last images only';}else{console.error('Chat not found');resultDiv.textContent='Error: Chat not found';}})();"

# Ruta al archivo HTML con instrucciones
INSTRUCTIONS_FILE="/tmp/raybanai-messenger-instructions.html"

# Verificar si el servicio RaybanAI está en ejecución
is_raybanai_running() {
    if curl -s "$RAYBANAI_URL" -o /dev/null; then
        return 0  # true, is running
    else
        return 1  # false, not running
    fi
}

# Crear archivo HTML con instrucciones y código copiable
cat > "$INSTRUCTIONS_FILE" << EOL
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>RaybanAI Bookmarklet</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            background-color: #1877f2;
            color: white;
            margin: 0;
            padding: 20px;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            height: 100vh;
            box-sizing: border-box;
        }
        .container {
            background-color: white;
            color: #333;
            border-radius: 8px;
            padding: 20px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.2);
            max-width: 90%;
            width: 320px;
        }
        h1 {
            font-size: 20px;
            margin-top: 0;
            color: #1877f2;
            border-bottom: 1px solid #eee;
            padding-bottom: 10px;
            text-align: center;
        }
        .button {
            display: block;
            width: 100%;
            background-color: #1877f2;
            color: white;
            border: none;
            border-radius: 6px;
            padding: 12px;
            margin-bottom: 15px;
            font-size: 16px;
            font-weight: bold;
            cursor: pointer;
        }
        .button:active {
            transform: scale(0.98);
            background-color: #166fe5;
        }
        .green-button {
            background-color: #42b72a;
        }
        .green-button:active {
            background-color: #36a420;
        }
        .instruction {
            margin-bottom: 20px;
            font-size: 14px;
            color: #444;
        }
        .step {
            display: flex;
            margin-bottom: 15px;
            align-items: flex-start;
        }
        .step-number {
            background-color: #1877f2;
            color: white;
            width: 24px;
            height: 24px;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            font-weight: bold;
            margin-right: 10px;
            flex-shrink: 0;
        }
        .step-text {
            flex: 1;
            font-size: 14px;
            color: #444;
        }
        .code-area {
            background-color: #f5f5f5;
            border: 1px solid #ddd;
            border-radius: 6px;
            padding: 15px;
            margin-bottom: 15px;
            font-family: monospace;
            font-size: 13px;
            overflow-y: auto;
            max-height: 150px;
            color: #333;
            word-break: break-all;
            white-space: pre-wrap;
            display: none;
        }
        .success-message {
            background-color: #42b72a;
            color: white;
            padding: 10px;
            border-radius: 6px;
            margin-top: 15px;
            text-align: center;
            display: none;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>RaybanAI para Messenger</h1>
        
        <div class="instruction">
            <div class="step">
                <div class="step-number">1</div>
                <div class="step-text">Abre Facebook Messenger en otra ventana.</div>
            </div>
            
            <div class="step">
                <div class="step-number">2</div>
                <div class="step-text">Usa los botones abajo para mostrar y copiar el código RaybanAI.</div>
            </div>
            
            <div class="step">
                <div class="step-number">3</div>
                <div class="step-text">En Messenger, abre la consola (F12) y pega el código.</div>
            </div>
        </div>
        
        <div class="code-area" id="codeArea">$BOOKMARKLET_CODE</div>
        
        <button class="button" id="openMessengerBtn">ABRIR MESSENGER</button>
        <button class="button" id="showCodeBtn">MOSTRAR CÓDIGO</button>
        <button class="button green-button" id="copyCodeBtn">COPIAR CÓDIGO</button>
        
        <div class="success-message" id="successMessage">¡Código copiado al portapapeles!</div>
    </div>
    
    <script>
        // Referencias a elementos
        const codeArea = document.getElementById('codeArea');
        const showCodeBtn = document.getElementById('showCodeBtn');
        const copyCodeBtn = document.getElementById('copyCodeBtn');
        const openMessengerBtn = document.getElementById('openMessengerBtn');
        const successMessage = document.getElementById('successMessage');
        
        // Evento para mostrar/ocultar código
        showCodeBtn.addEventListener('click', function() {
            if (codeArea.style.display === 'none' || codeArea.style.display === '') {
                codeArea.style.display = 'block';
                showCodeBtn.textContent = 'OCULTAR CÓDIGO';
            } else {
                codeArea.style.display = 'none';
                showCodeBtn.textContent = 'MOSTRAR CÓDIGO';
            }
        });
        
        // Evento para copiar código
        copyCodeBtn.addEventListener('click', function() {
            // Si el código no está visible, mostrarlo primero
            if (codeArea.style.display === 'none' || codeArea.style.display === '') {
                codeArea.style.display = 'block';
                showCodeBtn.textContent = 'OCULTAR CÓDIGO';
            }
            
            // Intentar copiar al portapapeles
            try {
                // Usar la API moderna si está disponible
                if (navigator.clipboard && navigator.clipboard.writeText) {
                    navigator.clipboard.writeText(codeArea.textContent)
                        .then(function() {
                            showSuccess();
                        })
                        .catch(function(err) {
                            console.error('Error al copiar con API moderna:', err);
                            // Intentar método alternativo
                            fallbackCopy();
                        });
                } else {
                    // Usar método alternativo
                    fallbackCopy();
                }
            } catch (err) {
                console.error('Error general al copiar:', err);
                // Último intento
                fallbackCopy();
            }
        });
        
        // Método alternativo de copia
        function fallbackCopy() {
            try {
                // Crear elemento temporal
                const textArea = document.createElement('textarea');
                textArea.value = codeArea.textContent;
                
                // Hacer que no sea visible
                textArea.style.position = 'fixed';
                textArea.style.left = '-999999px';
                textArea.style.top = '-999999px';
                
                document.body.appendChild(textArea);
                textArea.focus();
                textArea.select();
                
                // Ejecutar el comando de copia
                const successful = document.execCommand('copy');
                if (successful) {
                    showSuccess();
                } else {
                    console.error('execCommand falló');
                }
                
                document.body.removeChild(textArea);
            } catch (err) {
                console.error('Error en método alternativo:', err);
            }
        }
        
        // Mostrar mensaje de éxito
        function showSuccess() {
            successMessage.style.display = 'block';
            setTimeout(function() {
                successMessage.style.display = 'none';
            }, 2000);
        }
        
        // Evento para abrir Messenger
        openMessengerBtn.addEventListener('click', function() {
            window.open('$MESSENGER_URL', '_blank');
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
        # Intentar iniciar el servicio usando el script existente
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

print_message "Abriendo ayudante de RaybanAI para Messenger..."

# Abrir el archivo HTML en el navegador
case $BROWSER in
    "chromium-browser"|"chromium")
        $BROWSER --app="file://$INSTRUCTIONS_FILE" \
                 --window-size=320,480 \
                 --window-position=0,0
        ;;
    "firefox")
        firefox -width 320 -height 480 "file://$INSTRUCTIONS_FILE"
        ;;
    *)
        $BROWSER "file://$INSTRUCTIONS_FILE"
        ;;
esac

print_success "Ayudante de RaybanAI para Messenger iniciado"
exit 0
