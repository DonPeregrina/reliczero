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

# Ruta al archivo CSS personalizado
CSS_DIR="$HOME/.config/raybanai"
CSS_FILE="$CSS_DIR/enable-scrollbars.css"

# Ruta al proyecto RaybanAI (actualizada)
RAYBAN_DIR="/home/aimless/Documents/git/RaybanAI"

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

# Verificar si el archivo CSS existe
if [ ! -f "$CSS_FILE" ]; then
    print_message "Creando archivo CSS para habilitar barras de desplazamiento..."
    cat > "$CSS_FILE" << 'EOL'
/* CSS para forzar barras de desplazamiento en la interfaz de RaybanAI */
:root {
  scrollbar-width: auto !important;
  scrollbar-color: rgba(0, 0, 0, 0.5) rgba(0, 0, 0, 0.1) !important;
}

html, body {
  overflow-y: auto !important;
  overflow-x: auto !important;
}

* {
  scrollbar-width: auto !important;
}

/* Estilos para navegadores basados en WebKit (Chrome, Safari) */
::-webkit-scrollbar {
  width: 12px !important;
  height: 12px !important;
  display: block !important;
}

::-webkit-scrollbar-track {
  background: rgba(0, 0, 0, 0.1) !important;
  border-radius: 10px !important;
}

::-webkit-scrollbar-thumb {
  background-color: rgba(0, 0, 0, 0.5) !important;
  border-radius: 10px !important;
  border: 3px solid rgba(0, 0, 0, 0.1) !important;
}

::-webkit-scrollbar-thumb:hover {
  background-color: rgba(0, 0, 0, 0.7) !important;
}

/* Asegúrate de que todos los contenedores mantengan scrollbars */
div, section, article, main, aside, nav {
  overflow: visible !important;
  max-height: none !important;
}

/* Para contenedores con altura fija */
.fixed-height-container {
  overflow-y: auto !important;
  max-height: 100vh !important;
}
EOL
    print_success "Archivo CSS creado correctamente"
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

# Detectar el navegador disponible
if command -v chromium-browser &> /dev/null; then
    BROWSER="chromium-browser"
elif command -v chromium &> /dev/null; then
    BROWSER="chromium"
elif command -v firefox &> /dev/null; then
    BROWSER="firefox"
else
    BROWSER="xdg-open"
fi

print_message "Abriendo RaybanAI en el navegador ($BROWSER)..."

# Abrir la página con el CSS personalizado
case $BROWSER in
    "chromium-browser"|"chromium")
        $BROWSER --user-stylesheet="$CSS_FILE" http://localhost:3103/
        ;;
    "firefox")
        # Firefox necesita una configuración diferente para estilos personalizados
        # Por ahora, simplemente abrimos la URL
        $BROWSER http://localhost:3103/
        ;;
    *)
        $BROWSER http://localhost:3103/
        ;;
esac

print_success "Navegador abierto con RaybanAI"
exit 0
