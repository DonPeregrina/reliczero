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

# Ruta al archivo CSS para modo kiosk
CSS_DIR="$HOME/.config/raybanai"
CSS_FILE="$CSS_DIR/messenger-kiosk.css"

# Ruta al bookmarklet como archivo HTML
BOOKMARKLET_FILE="/tmp/raybanai-bookmarklet.html"

# Verificar si el servicio RaybanAI está en ejecución
is_raybanai_running() {
    if curl -s "$RAYBANAI_URL" -o /dev/null; then
        return 0  # true, is running
    else
        return 1  # false, not running
    fi
}

# Crear directorio si no existe
if [ ! -d "$CSS_DIR" ]; then
    mkdir -p "$CSS_DIR"
fi

# Crear archivo CSS para optimizar Messenger en pantalla pequeña
if [ ! -f "$CSS_FILE" ]; then
    print_message "Creando archivo CSS para optimizar Messenger..."
    cat > "$CSS_FILE" << 'EOL'
/* CSS para optimizar Facebook Messenger en pantalla pequeña (320x480) */

/* Hacer que todo sea más compacto */
body {
    overflow: hidden !important;
    font-size: 12px !important;
}

/* Ocultar elementos innecesarios */
[role="banner"],
[role="navigation"],
[aria-label="Información del chat"],
[aria-label="Chat info"],
[aria-label="Nuevo mensaje"],
[aria-label="New message"],
._5g-s,
div[data-pagelet="StoriesHelpFix"],
.uiScrollableAreaWrap .uiScrollableAreaTrack,
._4u-c._9hq1,  /* Lista de chats */
.jbf6nw7b.sfsefjzz.f8t7k2qy.f7l961vi.mw5e31w7 { /* Barra superior */
    display: none !important;
}

/* Aumentar la anchura del chat principal */
._4sp8, .rek2kq2y, ._1enh, ._4_j4, div._58al, .xhb8q0f {
    width: 100% !important;
    max-width: 100% !important;
}

/* Hacer que la área de chat sea más grande */
.j83agx80.cbu4d94t.ew0dbk1b.irj2b8pg {
    height: calc(100vh - 60px) !important;
}

/* Hacer que el cuadro de texto sea más pequeño pero visible */
.xzsf02u.x1a2a7pz.x1n2onr6.x14wi4xw.notranslate {
    max-height: 40px !important;
    min-height: 20px !important;
}

/* Ajustar tamaño de las imágenes */
img.i09qtzwb.n7fi1qx3.datstx6m {
    max-width: 280px !important;
    max-height: 240px !important;
}

/* Hacer que los mensajes sean más compactos */
.j83agx80, [role="main"] div {
    padding: 2px !important;
    margin: 1px !important;
}

/* Barras de desplazamiento delgadas */
::-webkit-scrollbar {
    width: 5px !important;
    height: 5px !important;
}

::-webkit-scrollbar-thumb {
    background-color: rgba(0, 0, 0, 0.3) !important;
    border-radius: 3px !important;
}

/* Hacer la interfaz más pequeña y compacta */
.l9j0dhe7.buofh1pr.j83agx80.bp9cbjyn {
    padding: 0 !important;
}

/* RaybanAI resultado más visible */
#raybanai-result {
    position: fixed !important;
    bottom: 10px !important;
    right: 10px !important;
    background: rgba(0, 0, 0, 0.8) !important;
    color: white !important;
    padding: 10px !important;
    border-radius: 5px !important;
    z-index: 9999 !important;
    max-width: 250px !important;
    font-size: 12px !important;
    font-family: Arial !important;
}
EOL
    print_success "Archivo CSS para Messenger creado correctamente"
fi

# Crear archivo HTML del bookmarklet
cat > "$BOOKMARKLET_FILE" << 'EOL'
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
            text-align: center;
            user-select: none;
        }
        .container {
            max-width: 280px;
        }
        h1 {
            font-size: 20px;
            margin-bottom: 15px;
        }
        .button {
            background-color: #42b72a;
            color: white;
            border: none;
            padding: 15px 20px;
            margin: 10px 0;
            border-radius: 5px;
            font-size: 16px;
            font-weight: bold;
            cursor: pointer;
            width: 100%;
            box-shadow: 0 2px 4px rgba(0,0,0,0.2);
        }
        .button:active {
            background-color: #36a420;
            transform: scale(0.98);
        }
        p {
            font-size: 14px;
            line-height: 1.5;
        }
        .logo {
            width: 60px;
            height: 60px;
            margin-bottom: 15px;
        }
        .instructions {
            font-size: 13px;
            opacity: 0.9;
            margin-top: 15px;
        }
    </style>
</head>
<body>
    <div class="container">
        <svg class="logo" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512">
            <circle cx="256" cy="256" r="256" fill="#FFFFFF"/>
            <path fill="#42b72a" d="M256.55 100C180.52 100 120 160.34 120 235.57c0 40.3 16.71 76.78 45.07 102.94 8.36 7.51 6.63 11.86 8.05 58.23 0.4 12.17 9.84 20.07 22 18.86 20.21-3.9 40.26-12.13 55.27-20 9.43-4.65 15.38-5.47 31-5.47 75 0 135.44-60.49 135.44-154.71C416.78 160.4 332.28 100 256.55 100z"/>
            <path fill="#FFFFFF" d="M192.51 249.13l65-101.64a5.9 5.9 0 019.65.11l26.69 46.27a5.9 5.9 0 008.42 1.8l49.94-32.65a5.9 5.9 0 018.95 6.3l-45.32 129.81a5.9 5.9 0 01-9.53 2.11l-44.89-48.62a5.9 5.9 0 00-8.24-.49l-49.93 41.82a5.9 5.9 0 01-9.15-6.3l19.95-69.17"/>
        </svg>
        
        <h1>Activar RaybanAI</h1>
        
        <p>Presiona el botón para activar el análisis automático de imágenes en Messenger</p>
        
        <a id="bookmarkletBtn" class="button" href="javascript:(function(){const API_URL='http://localhost:3103/api/raybanai';const resultDiv=document.createElement('div');resultDiv.style.cssText='position:fixed;bottom:20px;right:20px;background:rgba(0,0,0,0.8);color:white;padding:15px;border-radius:8px;z-index:9999;max-width:300px;font-family:Arial;';document.body.appendChild(resultDiv);let lastProcessedTime=Date.now();async function processImage(imgSrc){if(Date.now()-lastProcessedTime<1000)return;lastProcessedTime=Date.now();if(imgSrc.includes('profile')||imgSrc.includes('avatar'))return;resultDiv.textContent='Analyzing image...';console.log('Processing:',imgSrc);try{const response=await fetch(API_URL,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({type:'url',imageUrl:imgSrc})});const data=await response.json();console.log('Response:',data);resultDiv.textContent=data.response||data.description;}catch(error){console.error('Error:',error);resultDiv.textContent='Error processing image';}}const observer=new MutationObserver(mutations=>{for(const mutation of mutations){const addedNodes=Array.from(mutation.addedNodes);for(const node of addedNodes){if(node.nodeType===1&&node.classList&&node.classList.contains('x78zum5')){const images=node.getElementsByTagName('img');if(images.length>0){const lastImage=images[images.length-1];if(!lastImage.dataset.processed){lastImage.dataset.processed='true';processImage(lastImage.src);return;}}}}}});const chatContainer=document.querySelector('[role=\"main\"]');if(chatContainer){observer.observe(chatContainer,{childList:true,subtree:true});console.log('Observer started');resultDiv.textContent='Observer activated - Last images only';}else{console.error('Chat not found');resultDiv.textContent='Error: Chat not found';}})();">
            ACTIVAR RAYBANAI
        </a>
        
        <p class="instructions">
            1. Presiona el botón verde<br>
            2. Arrástralo a tus marcadores<br>
            3. Úsalo cuando estés en Messenger
        </p>
    </div>
    
    <script>
        // Para facilitar su uso
        document.getElementById('bookmarkletBtn').addEventListener('click', function(e) {
            e.preventDefault();
            alert('Guarda este botón en tus marcadores arrastrándolo a la barra de marcadores, o haz clic en él cuando estés en Messenger.');
        });
    </script>
</body>
</html>
EOL

# Verificar si el servicio RaybanAI está en ejecución
if ! is_raybanai_running; then
    print_message "El servicio RaybanAI no está en ejecución"
    zenity --question --title="Messenger RaybanAI" --text="El servicio RaybanAI no está en ejecución.\n\n¿Desea iniciarlo antes de abrir Messenger?" --ok-label="Iniciar" --cancel-label="Cancelar"
    
    if [ $? -eq 0 ]; then
        # Intentar iniciar el servicio
        if [ -f "$HOME/toggle-raybanai.sh" ]; then
            print_message "Iniciando servicio RaybanAI..."
            bash "$HOME/toggle-raybanai.sh" --start
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

# Mostrar el diálogo al usuario
zenity --question --title="Messenger RaybanAI" --text="¿Qué deseas abrir?" \
       --ok-label="Messenger" --cancel-label="Bookmarklet" --width=300

CHOICE=$?

if [ $CHOICE -eq 0 ]; then
    # El usuario eligió abrir Messenger
    print_message "Abriendo Messenger en modo kiosk con $BROWSER..."
    
    case $BROWSER in
        "chromium-browser"|"chromium")
            # Abrir Facebook Messenger en modo kiosk con Chromium
            $BROWSER --app="$MESSENGER_URL" \
                     --user-stylesheet="$CSS_FILE" \
                     --window-size=320,480 \
                     --window-position=0,0 \
                     --disable-features=TranslateUI \
                     --disable-extensions \
                     --disable-notifications \
                     --disable-infobars \
                     --disable-pinch
            ;;
        "firefox")
            # Firefox no tiene un modo kiosk tan completo
            firefox -width 320 -height 480 -private-window "$MESSENGER_URL"
            ;;
        *)
            # Fallback a xdg-open
            $BROWSER "$MESSENGER_URL"
            ;;
    esac
    
    print_success "Messenger abierto en modo kiosk"
else
    # El usuario eligió abrir el Bookmarklet
    print_message "Abriendo página del Bookmarklet RaybanAI con $BROWSER..."
    
    case $BROWSER in
        "chromium-browser"|"chromium")
            # Abrir la página del bookmarklet
            $BROWSER --app="file://$BOOKMARKLET_FILE" \
                     --window-size=320,480 \
                     --window-position=0,0
            ;;
        "firefox")
            # Firefox
            firefox -width 320 -height 480 "file://$BOOKMARKLET_FILE"
            ;;
        *)
            # Fallback a xdg-open
            $BROWSER "file://$BOOKMARKLET_FILE"
            ;;
    esac
    
    print_success "Página del Bookmarklet RaybanAI abierta"
fi

exit 0
