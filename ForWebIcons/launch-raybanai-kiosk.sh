#!/bin/bash

# Colors for messages
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Print formatted messages
print_message() {
    echo -e "${BLUE}[RaybanAI Web]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[✔] $1${NC}"
}

print_error() {
    echo -e "${RED}[✘] $1${NC}"
}

# Ruta al proyecto RaybanAI
RAYBAN_DIR="/home/aimless/Documents/git/RaybanAI"

# Ruta al archivo CSS personalizado para optimizar la interfaz
CSS_DIR="$HOME/.config/raybanai"
CSS_FILE="$CSS_DIR/kiosk-mode.css"

# Crear directorio si no existe
if [ ! -d "$CSS_DIR" ]; then
    mkdir -p "$CSS_DIR"
fi

# Verificar si el servicio está en ejecución
is_running() {
    if curl -s http://localhost:3103/ -o /dev/null; then
        return 0  # true, is running
    else
        return 1  # false, not running
    fi
}

# Crear archivo CSS para modo kiosk y pantalla pequeña
if [ ! -f "$CSS_FILE" ]; then
    print_message "Creando archivo CSS para modo kiosk y pantalla pequeña..."
    cat > "$CSS_FILE" << 'EOL'
/* CSS para modo kiosk en pantalla pequeña (320x480) */

/* Estilos generales para toda la aplicación */
body {
    margin: 0 !important;
    padding: 0 !important;
    width: 100vw !important;
    height: 100vh !important;
    overflow-x: hidden !important;
    max-width: 100% !important;
    font-size: 14px !important;
}

/* Hacer que todos los contenedores se ajusten a la pantalla pequeña */
.container, div.container {
    max-width: 320px !important;
    padding: 10px !important;
    margin: 0 auto !important;
    box-sizing: border-box !important;
}

/* Reducir márgenes y paddings */
.card, .card-body, .form-group {
    margin-bottom: 10px !important;
    padding: 10px !important;
}

/* Hacer que los botones sean más pequeños pero fáciles de tocar */
.btn {
    padding: 8px 12px !important;
    margin-right: 5px !important;
    margin-bottom: 5px !important;
    font-size: 14px !important;
}

/* Ajustar selects y inputs para que sean más pequeños */
.form-control, .form-select {
    height: 34px !important;
    padding: 4px 8px !important;
    font-size: 14px !important;
}

/* Ajustar tamaños de texto */
h1 {
    font-size: 20px !important;
    margin-bottom: 10px !important;
}

h2 {
    font-size: 18px !important;
}

h3, h4, h5, h6 {
    font-size: 16px !important;
}

/* Mejorar barras de desplazamiento */
:root {
    scrollbar-width: thin !important;
    scrollbar-color: rgba(0, 0, 0, 0.5) rgba(0, 0, 0, 0.1) !important;
}

/* Estilos para barras de desplazamiento en WebKit */
::-webkit-scrollbar {
    width: 8px !important;
    height: 8px !important;
}

::-webkit-scrollbar-track {
    background: rgba(0, 0, 0, 0.1) !important;
    border-radius: 4px !important;
}

::-webkit-scrollbar-thumb {
    background-color: rgba(0, 0, 0, 0.5) !important;
    border-radius: 4px !important;
}

/* Ajustes para pantallas multi-columna */
.row {
    margin-left: -5px !important;
    margin-right: -5px !important;
}

.col, .col-md-4, .col-md-6, .col-md-8, [class*="col-"] {
    padding-left: 5px !important;
    padding-right: 5px !important;
}

/* Ajustes específicos para la página de MongoDB History */
.history-item {
    margin-bottom: 15px !important;
    padding: 10px !important;
}

.flex-container {
    flex-direction: column !important;
}

.image-container {
    flex: 0 0 auto !important;
    max-width: 100% !important;
    margin-right: 0 !important;
    margin-bottom: 10px !important;
}

.image-container img {
    max-width: 100% !important;
    max-height: 160px !important;
}

.content-container {
    flex: 1 !important;
    min-width: 100% !important;
}

/* Ajustes específicos para formularios y textarea */
textarea.prompt-editor {
    min-height: 120px !important;
}

/* Ajustes para la navegación por pestañas */
.nav-pills .nav-link {
    padding: 6px 10px !important;
    font-size: 14px !important;
}

/* Ajustes específicos para la página de configuración */
pre {
    max-height: 150px !important;
    overflow-y: auto !important;
    font-size: 12px !important;
}

/* Estilo para la página de inicio */
.back-link {
    margin-bottom: 10px !important;
    display: inline-block !important;
}
EOL
    print_success "Archivo CSS para modo kiosk creado correctamente"
fi

# Verificar si el servicio está en ejecución
if ! is_running; then
    print_message "El servicio RaybanAI no está en ejecución"
    zenity --question --title="RaybanAI Web" --text="El servicio RaybanAI no está en ejecución.\n\n¿Desea iniciarlo antes de abrir la interfaz web?" --ok-label="Iniciar" --cancel-label="Cancelar"
    
    if [ $? -eq 0 ]; then
        # Intentar iniciar el servicio usando el script restart.sh del proyecto
        if [ -f "$RAYBAN_DIR/restart.sh" ]; then
            print_message "Iniciando servicio con restart.sh..."
            cd "$RAYBAN_DIR" && bash restart.sh
        else
            # Intentar con toggle-raybanai.sh si está disponible
            if [ -f "$HOME/toggle-raybanai.sh" ]; then
                print_message "Iniciando servicio con toggle-raybanai.sh..."
                bash "$HOME/toggle-raybanai.sh" --start
            else
                print_error "No se encontraron scripts para iniciar el servicio"
                zenity --error --text="No se pudo iniciar el servicio RaybanAI.\nPor favor, inicie el servicio manualmente antes de abrir la interfaz web."
                exit 1
            fi
        fi
        
        # Esperar a que el servicio esté disponible
        print_message "Esperando a que el servicio esté disponible..."
        for i in {1..10}; do
            if is_running; then
                break
            fi
            sleep 1
        done
    else
        exit 0
    fi
fi

# Verificar nuevamente si el servicio está en ejecución
if ! is_running; then
    print_error "No se pudo conectar al servicio RaybanAI"
    zenity --error --text="No se pudo conectar a RaybanAI en http://localhost:3103/\nAsegúrese de que el servicio esté en ejecución."
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

print_message "Abriendo RaybanAI en modo kiosk con $BROWSER..."

# Abrir en navegador sin barra de direcciones y con CSS personalizado
case $BROWSER in
    "chromium-browser"|"chromium")
        # Modo kiosk para Chromium/Chrome
        $BROWSER --app=http://localhost:3103/ \
                 --user-stylesheet="$CSS_FILE" \
                 --window-size=320,480 \
                 --window-position=0,0 \
                 --disable-features=TranslateUI,OverscrollHistoryNavigation \
                 --disable-extensions \
                 --disable-infobars \
                 --disable-pinch \
                 --force-device-scale-factor=1
        ;;
    "firefox")
        # Firefox no tiene un modo kiosk tan completo, pero hacemos lo mejor posible
        firefox -width 320 -height 480 \
                -private-window http://localhost:3103/
        ;;
    *)
        # Fallback a xdg-open
        $BROWSER http://localhost:3103/
        ;;
esac

print_success "Navegador abierto en modo kiosk"
exit 0
