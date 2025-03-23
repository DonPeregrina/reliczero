#!/bin/bash

# Colors for messages
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Archivo de log
LOG_FILE="/tmp/raybanai_debug.log"

# Función para escribir mensajes en el log
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Función para escribir en la consola y en el log
print_message() {
    echo -e "${BLUE}[RaybanAI Debug]${NC} $1"
    log_message "$1"
}

print_success() {
    echo -e "${GREEN}[✔] $1${NC}"
    log_message "[SUCCESS] $1"
}

print_error() {
    echo -e "${RED}[✘] $1${NC}"
    log_message "[ERROR] $1"
}

print_warning() {
    echo -e "${YELLOW}[!] $1${NC}"
    log_message "[WARNING] $1"
}

# Iniciar archivo de log
echo "==== Iniciando depuración de RaybanAI $(date '+%Y-%m-%d %H:%M:%S') ====" > "$LOG_FILE"

# Verificar la existencia del directorio RaybanAI
RAYBAN_DIR="$HOME/Documents/git/RaybanAI"
if [ -d "$RAYBAN_DIR" ]; then
    print_success "Directorio RaybanAI encontrado en $RAYBAN_DIR"
    # Listar contenido del directorio
    log_message "Contenido del directorio:"
    ls -la "$RAYBAN_DIR" >> "$LOG_FILE" 2>&1
else
    print_error "Directorio RaybanAI NO encontrado en $RAYBAN_DIR"
    log_message "Buscando otros posibles directorios RaybanAI:"
    find "$HOME" -name "RaybanAI" -type d -o -name "raybanai" -type d 2>/dev/null >> "$LOG_FILE" 
fi

# Verificar el directorio backend
if [ -d "$RAYBAN_DIR/backend" ]; then
    print_success "Directorio backend encontrado"
    log_message "Contenido del directorio backend:"
    ls -la "$RAYBAN_DIR/backend" >> "$LOG_FILE" 2>&1
    
    # Verificar package.json
    if [ -f "$RAYBAN_DIR/backend/package.json" ]; then
        print_success "Archivo package.json encontrado"
        log_message "Contenido de package.json:"
        cat "$RAYBAN_DIR/backend/package.json" >> "$LOG_FILE" 2>&1
    else
        print_error "Archivo package.json NO encontrado"
    fi
else
    print_error "Directorio backend NO encontrado"
    log_message "Buscando otros posibles directorios backend:"
    find "$HOME" -name "backend" -type d 2>/dev/null >> "$LOG_FILE"
fi

# Verificar el script toggle-raybanai.sh
if [ -f "$HOME/toggle-raybanai.sh" ]; then
    print_success "Script toggle-raybanai.sh encontrado"
    # Verificar permisos
    ls -la "$HOME/toggle-raybanai.sh" >> "$LOG_FILE" 2>&1
else
    print_error "Script toggle-raybanai.sh NO encontrado"
fi

# Verificar si hay procesos nodejs o npm corriendo
print_message "Verificando procesos nodejs y npm:"
ps aux | grep -E 'node|npm' | grep -v grep >> "$LOG_FILE" 2>&1

# Verificar puertos en uso
print_message "Verificando puertos en uso:"
netstat -tulpn 2>/dev/null | grep LISTEN >> "$LOG_FILE" 2>&1 || ss -tulpn >> "$LOG_FILE" 2>&1

# Intentar iniciar el servicio
print_message "Intentando iniciar el servicio RaybanAI..."
log_message "Ejecutando: cd $RAYBAN_DIR/backend && npm start"

echo "===== SALIDA DEL COMANDO NPM START =====" >> "$LOG_FILE"
(cd "$RAYBAN_DIR/backend" && npm start) >> "$LOG_FILE" 2>&1 &
NPM_PID=$!

# Esperar unos segundos
print_message "Esperando 5 segundos para que el servicio inicie..."
sleep 5

# Verificar si el proceso sigue en ejecución
if ps -p $NPM_PID > /dev/null; then
    print_success "El proceso npm start está en ejecución (PID: $NPM_PID)"
else
    print_error "El proceso npm start ya no está en ejecución"
    log_message "Últimas líneas del log:"
    tail -n 20 "$LOG_FILE" >> "$LOG_FILE" 2>&1
fi

# Verificar si el servicio responde
print_message "Verificando si el servicio responde en http://localhost:3103/ ..."
if curl -s http://localhost:3103/ -o /dev/null; then
    print_success "¡El servicio está respondiendo correctamente!"
    
    # Intentar abrir en el navegador
    print_message "Intentando abrir en el navegador..."
    if command -v chromium-browser &> /dev/null; then
        chromium-browser http://localhost:3103/ &
    elif command -v chromium &> /dev/null; then
        chromium http://localhost:3103/ &
    elif command -v firefox &> /dev/null; then
        firefox http://localhost:3103/ &
    else
        xdg-open http://localhost:3103/ &
    fi
else
    print_error "El servicio NO está respondiendo en http://localhost:3103/"
    
    # Verificar logs y errores
    if [ -f "/tmp/raybanai.log" ]; then
        print_message "Contenido del log del servicio:"
        tail -n 30 "/tmp/raybanai.log" >> "$LOG_FILE" 2>&1
    fi
fi

# Mostrar un mensaje al usuario con la ubicación del archivo de log
print_message "===========================================" 
print_message "Depuración completada. Archivo de log disponible en:"
print_message "$LOG_FILE"
print_message "===========================================" 
print_message "Puedes ver el contenido del log con el comando:"
print_message "cat $LOG_FILE"
print_message "===========================================" 

# Abrir el log en un visor de texto
if command -v gedit &> /dev/null; then
    gedit "$LOG_FILE" &
elif command -v nano &> /dev/null; then
    xterm -e "nano $LOG_FILE" &
elif command -v leafpad &> /dev/null; then
    leafpad "$LOG_FILE" &
fi

exit 0
