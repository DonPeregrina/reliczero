#!/bin/bash

# Colores para una mejor visualizaciones
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Función para mostrar mensajes con estilo
print_message() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[ÉXITO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[AVISO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Función para verificar si estamos en una Raspberry Pi
check_raspberry() {
    if [ ! -f /proc/device-tree/model ]; then
        print_error "Este script debe ejecutarse en una Raspberry Pi."
        exit 1
    fi
    
    model=$(tr -d '\0' < /proc/device-tree/model)
    print_message "Modelo detectado: $model"
    
    if [[ "$model" != *"Raspberry Pi"* ]]; then
        print_error "Este script debe ejecutarse en una Raspberry Pi."
        exit 1
    fi
    
    print_success "Ejecutando en una Raspberry Pi."
}

# Función para hacer una copia de seguridad del archivo config.txt
backup_config() {
    CONFIG_FILE="/boot/firmware/config.txt"
    BACKUP_FILE="/boot/firmware/config.txt.bak.$(date +%Y%m%d%H%M%S)"
    
    # Si el archivo config.txt no existe en /boot/firmware, intentar en /boot
    if [ ! -f "$CONFIG_FILE" ]; then
        CONFIG_FILE="/boot/config.txt"
        BACKUP_FILE="/boot/config.txt.bak.$(date +%Y%m%d%H%M%S)"
        
        if [ ! -f "$CONFIG_FILE" ]; then
            print_error "No se pudo encontrar el archivo config.txt ni en /boot/firmware ni en /boot."
            exit 1
        fi
    fi
    
    print_message "Haciendo copia de seguridad de $CONFIG_FILE en $BACKUP_FILE"
    sudo cp "$CONFIG_FILE" "$BACKUP_FILE"
    
    if [ $? -eq 0 ]; then
        print_success "Copia de seguridad creada correctamente."
    else
        print_error "Error al crear la copia de seguridad."
        exit 1
    fi
}

# Función para modificar el archivo config.txt
modify_config() {
    CONFIG_FILE="/boot/firmware/config.txt"
    
    # Si el archivo config.txt no existe en /boot/firmware, intentar en /boot
    if [ ! -f "$CONFIG_FILE" ]; then
        CONFIG_FILE="/boot/config.txt"
        
        if [ ! -f "$CONFIG_FILE" ]; then
            print_error "No se pudo encontrar el archivo config.txt ni en /boot/firmware ni en /boot."
            exit 1
        fi
    fi
    
    print_message "Modificando archivo $CONFIG_FILE para habilitar RaspiAudio (GoogleVoiceHat)..."
    
    # Verificar si la línea dtparam=audio=on ya está comentada
    if grep -q "^dtparam=audio=on" "$CONFIG_FILE"; then
        print_message "Comentando la línea dtparam=audio=on..."
        sudo sed -i 's/^dtparam=audio=on/#dtparam=audio=on/' "$CONFIG_FILE"
    elif grep -q "^#dtparam=audio=on" "$CONFIG_FILE"; then
        print_message "La línea dtparam=audio=on ya está comentada."
    else
        print_warning "No se encontró la línea dtparam=audio=on en el archivo config.txt."
    fi
    
    # Verificar si la línea dtoverlay=googlevoicehat-soundcard ya existe
    if grep -q "dtoverlay=googlevoicehat-soundcard" "$CONFIG_FILE"; then
        print_message "La línea dtoverlay=googlevoicehat-soundcard ya existe en el archivo."
    else
        print_message "Añadiendo dtoverlay=googlevoicehat-soundcard al archivo..."
        echo "dtoverlay=googlevoicehat-soundcard" | sudo tee -a "$CONFIG_FILE" > /dev/null
    fi
    
    print_success "Archivo config.txt modificado correctamente."
    
    # Mostrar las modificaciones realizadas
    print_message "Contenido actual de las líneas relevantes en $CONFIG_FILE:"
    grep -E "dtparam=audio|dtoverlay=googlevoicehat" "$CONFIG_FILE"
}

# Función para reiniciar el sistema
reboot_system() {
    print_message "Es necesario reiniciar el sistema para aplicar los cambios."
    read -p "¿Deseas reiniciar ahora? (s/n): " choice
    
    if [[ "$choice" =~ ^[Ss]$ ]]; then
        print_message "Reiniciando el sistema en 5 segundos..."
        sleep 5
        sudo reboot
    else
        print_warning "No se reiniciará el sistema. Recuerda reiniciar manualmente para aplicar los cambios."
    fi
}

# Función para mostrar instrucciones post-instalación
show_post_instructions() {
    echo ""
    echo "===== INSTRUCCIONES POST-INSTALACIÓN ====="
    echo "Después de reiniciar, puedes verificar que la tarjeta de sonido esté funcionando con estos comandos:"
    echo ""
    echo "1. Listar dispositivos de audio:"
    echo "   aplay -l"
    echo ""
    echo "2. Probar la salida de audio:"
    echo "   speaker-test -t wav -c 2"
    echo ""
    echo "3. Grabar audio (presiona Ctrl+C para detener):"
    echo "   arecord -f cd -d 10 test.wav"
    echo ""
    echo "4. Reproducir audio grabado:"
    echo "   aplay test.wav"
    echo "========================================"
    echo ""
}

# Función principal
main() {
    echo "===== INSTALACIÓN DE RASPIAUDIO (GOOGLEVOICEHAT) ====="
    
    # Verificar si estamos en una Raspberry Pi
    check_raspberry
    
    # Hacer copia de seguridad del archivo config.txt
    backup_config
    
    # Modificar el archivo config.txt
    modify_config
    
    # Mostrar instrucciones post-instalación
    show_post_instructions
    
    # Preguntar si se desea reiniciar
    reboot_system
}

# Ejecutar la función principal
main
