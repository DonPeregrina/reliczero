#!/bin/bash

# Colors for messages
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Print formatted messages
print_message() {
    echo -e "${BLUE}[RaybanAI]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[✔] $1${NC}"
}

print_error() {
    echo -e "${RED}[✘] $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}[!] $1${NC}"
}

# Path to RaybanAI (actualizada según la ubicación correcta)
RAYBAN_DIR="/home/aimless/Documents/git/RaybanAI"
# File to track if service is running
STATUS_FILE="/tmp/raybanai_running"
# Lock file to prevent multiple instances
LOCK_FILE="/tmp/raybanai_toggle.lock"

# Check if another instance is running
if [ -f "$LOCK_FILE" ]; then
    print_error "Another instance of this script is already running"
    exit 1
fi

# Create lock file
touch "$LOCK_FILE"

# Cleanup function to remove lock file
cleanup() {
    rm -f "$LOCK_FILE"
    exit
}

# Set trap to ensure cleanup on exit
trap cleanup EXIT INT TERM

# Check if the service is running
is_running() {
    PORT_PROCESS=$(lsof -ti:3103 2>/dev/null)
    if [ ! -z "$PORT_PROCESS" ]; then
        return 0  # true, is running
    else
        return 1  # false, not running
    fi
}

# Start the service using the existing restart.sh script
start_service() {
    print_message "🚀 Iniciando servicio RaybanAI..."
    
    # Check if directory exists
    if [ ! -d "$RAYBAN_DIR" ]; then
        print_error "No se encontró el directorio RaybanAI en $RAYBAN_DIR"
        exit 1
    fi
    
    # Check if restart.sh exists
    if [ -f "$RAYBAN_DIR/restart.sh" ]; then
        print_message "Usando script restart.sh existente..."
        # Change to project directory and run the restart script
        cd "$RAYBAN_DIR" && bash restart.sh
        
        # Check if it started successfully
        sleep 5
        if is_running; then
            print_success "Servicio RaybanAI iniciado correctamente"
            # Create status file to track that service is running
            echo $! > "$STATUS_FILE"
            zenity --notification --text="Servicio RaybanAI iniciado" --timeout=3
        else
            print_error "Falló al iniciar el servicio RaybanAI"
            zenity --error --text="Falló al iniciar el servicio RaybanAI" --timeout=3
        fi
    else
        print_error "El script restart.sh no existe en $RAYBAN_DIR"
        print_message "Intentando iniciar manualmente..."
        
        # Kill any existing process on port 3103
        PORT_PROCESS=$(lsof -ti:3103 2>/dev/null)
        if [ ! -z "$PORT_PROCESS" ]; then
            print_message "Terminando proceso existente en puerto 3103..."
            kill -9 $PORT_PROCESS
            sleep 1
        fi
        
        # Start the service in the background
        if [ -d "$RAYBAN_DIR/backend" ]; then
            cd "$RAYBAN_DIR/backend" && nohup npm start > /tmp/raybanai.log 2>&1 &
            
            # Check if it started successfully
            sleep 5
            if is_running; then
                print_success "Servicio RaybanAI iniciado correctamente"
                # Create status file to track that service is running
                echo $! > "$STATUS_FILE"
                zenity --notification --text="Servicio RaybanAI iniciado" --timeout=3
            else
                print_error "Falló al iniciar el servicio RaybanAI"
                zenity --error --text="Falló al iniciar el servicio RaybanAI" --timeout=3
            fi
        else
            print_error "No se encontró el directorio backend"
            zenity --error --text="No se encontró el directorio backend" --timeout=3
        fi
    fi
}

# Stop the service
stop_service() {
    print_message "🛑 Deteniendo servicio RaybanAI..."
    
    PORT_PROCESS=$(lsof -ti:3103 2>/dev/null)
    if [ ! -z "$PORT_PROCESS" ]; then
        kill -9 $PORT_PROCESS
        sleep 1
        if ! is_running; then
            print_success "Servicio RaybanAI detenido correctamente"
            rm -f "$STATUS_FILE"
            zenity --notification --text="Servicio RaybanAI detenido" --timeout=3
        else
            print_error "No se pudo detener el servicio RaybanAI"
            zenity --error --text="No se pudo detener el servicio RaybanAI" --timeout=3
        fi
    else
        print_warning "El servicio RaybanAI no estaba en ejecución"
        rm -f "$STATUS_FILE"
    fi
}

# Toggle service state
toggle_service() {
    if is_running; then
        stop_service
    else
        start_service
    fi
}

# Show current status with dialog
show_status() {
    if is_running; then
        zenity --question --title="RaybanAI" --text="El servicio RaybanAI está en ejecución.\n\n¿Desea detener el servicio?" --ok-label="Detener" --cancel-label="Cancelar"
        if [ $? -eq 0 ]; then
            stop_service
        fi
    else
        zenity --question --title="RaybanAI" --text="El servicio RaybanAI no está en ejecución.\n\n¿Desea iniciar el servicio?" --ok-label="Iniciar" --cancel-label="Cancelar"
        if [ $? -eq 0 ]; then
            start_service
        fi
    fi
}

# Main execution
if [ "$1" == "--toggle" ]; then
    toggle_service
elif [ "$1" == "--start" ]; then
    start_service
elif [ "$1" == "--stop" ]; then
    stop_service
else
    show_status
fi

exit 0
