#!/bin/bash

# Colores para los mensajes
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Funciones de utilidad
print_status() { echo -e "${BLUE}➜ $1${NC}"; }
print_error() { echo -e "${RED}❌ ERROR: $1${NC}"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }

# Variables globales
VENV_PATH=""
VENV_NAME=""

# Función para preguntar sí/no
ask_yes_no() {
    while true; do
        read -p "$1 (s/n): " yn
        case $yn in
            [Ss]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo "Por favor responde sí (s) o no (n).";;
        esac
    done
}

# Verificar si se ejecuta como root
if [[ $EUID -ne 0 ]]; then
   print_error "Este script debe ejecutarse como root (usar sudo)"
   exit 1
fi

# Detectar el usuario actual
SUDO_USER=$(logname || echo $SUDO_USER)
if [ -z "$SUDO_USER" ]; then
    print_warning "No se pudo detectar el usuario automáticamente"
    read -p "Por favor, ingresa el nombre de usuario: " SUDO_USER
    if [ -z "$SUDO_USER" ]; then
        print_error "Se requiere un nombre de usuario válido"
        exit 1
    fi
fi

print_status "Usuario detectado: $SUDO_USER"

# Función para configurar el entorno virtual
setup_virtualenv() {
    if ! dpkg -l | grep -q "python3-virtualenv"; then
        print_status "Instalando virtualenv..."
        apt install -y python3-virtualenv python3-pip
    fi

    if ! dpkg -l | grep -q "python3-virtualenvwrapper"; then
        print_status "Instalando virtualenvwrapper..."
        apt install -y python3-virtualenvwrapper
    fi

    # Configurar virtualenvwrapper si no está configurado
    VENV_WRAPPER_PATH=$(find / -name virtualenvwrapper.sh 2>/dev/null | head -n 1)
    if [ -n "$VENV_WRAPPER_PATH" ]; then
        if ! grep -q "VIRTUALENVWRAPPER_PYTHON" "/home/$SUDO_USER/.bashrc"; then
            cat >> "/home/$SUDO_USER/.bashrc" << EOF

# Virtualenvwrapper settings
export WORKON_HOME=\$HOME/.virtualenvs
export VIRTUALENVWRAPPER_PYTHON=/usr/bin/python3
source $VENV_WRAPPER_PATH
EOF
            print_success "virtualenvwrapper configurado"
            source "/home/$SUDO_USER/.bashrc"
        fi
    fi

    # Preguntar si quiere crear nuevo entorno o usar existente
    if ask_yes_no "¿Deseas crear un nuevo entorno virtual?"; then
        read -p "Ingresa el nombre para el nuevo entorno virtual: " VENV_NAME
        if [ -n "$VENV_NAME" ]; then
            su - $SUDO_USER -c "source $VENV_WRAPPER_PATH && mkvirtualenv $VENV_NAME"
            print_success "Entorno virtual '$VENV_NAME' creado"
        fi
    else
        read -p "Ingresa el nombre del entorno virtual existente: " VENV_NAME
        if [ ! -d "/home/$SUDO_USER/.virtualenvs/$VENV_NAME" ]; then
            print_error "El entorno virtual '$VENV_NAME' no existe"
            exit 1
        fi
    fi
    
    VENV_PATH="/home/$SUDO_USER/.virtualenvs/$VENV_NAME"
}

# Función para instalar en el entorno virtual
install_in_venv() {
    local package=$1
    if [ -n "$VENV_PATH" ]; then
        print_status "Instalando $package..."
        echo "----------------------------------------------------------------"
        su - $SUDO_USER -c "source $VENV_PATH/bin/activate && pip install $package -v"
        echo "----------------------------------------------------------------"
        if [ $? -eq 0 ]; then
            print_success "$package instalado correctamente"
        else
            print_error "Error instalando $package"
            exit 1
        fi
    else
        print_error "No hay un entorno virtual configurado"
        exit 1
    fi
}

# Función para instalar y configurar Adafruit Blinka
install_adafruit_blinka() {
    if ask_yes_no "¿Deseas instalar Adafruit Blinka?"; then
        print_status "Instalando Adafruit Blinka en el entorno virtual $VENV_NAME..."
        install_in_venv "adafruit-blinka"
        install_in_venv "adafruit-python-shell"
        cd /home/$SUDO_USER
        wget https://raw.githubusercontent.com/adafruit/Raspberry-Pi-Installer-Scripts/master/raspi-blinka.py
        su - $SUDO_USER -c "source $VENV_PATH/bin/activate && python3 raspi-blinka.py"
        print_success "Adafruit Blinka instalado en el entorno virtual $VENV_NAME"
    fi
}

# Función para instalar voice card
install_voice_card() {
    if ask_yes_no "¿Deseas instalar seeed-voicecard?"; then
        print_status "Instalando seeed-voicecard..."
        echo "----------------------------------------------------------------"
        print_status "Clonando repositorio..."
        cd /home/$SUDO_USER
        rm -rf seeed-voicecard
        git clone https://github.com/HinTak/seeed-voicecard 2>&1
        if [ $? -ne 0 ]; then
            print_error "Error clonando repositorio"
            return 1
        fi
        
        cd seeed-voicecard
        print_status "Cambiando a versión v6.6..."
        git checkout v6.6 2>&1
        if [ $? -ne 0 ]; then
            print_error "Error cambiando a versión v6.6"
            return 1
        fi
        
        print_status "Ejecutando instalación..."
        ./install.sh 2>&1
        if [ $? -ne 0 ]; then
            print_error "Error durante la instalación"
            return 1
        fi
        echo "----------------------------------------------------------------"
        print_success "seeed-voicecard instalado correctamente"
    fi
}

# Función para instalar DotStar
install_dotstar() {
    if ask_yes_no "¿Deseas instalar la librería DotStar?"; then
        print_status "Instalando DotStar en el entorno virtual $VENV_NAME..."
        install_in_venv "adafruit-circuitpython-dotstar"
        print_success "DotStar instalado en el entorno virtual $VENV_NAME"
    fi
}

# Menú principal
clear
print_status "Bienvenido al script de configuración interactivo"
echo "Este script te ayudará a configurar varios componentes en tu Raspberry Pi."
echo

# Actualizar sistema
if ask_yes_no "¿Deseas actualizar el sistema antes de comenzar?"; then
    print_status "Actualizando sistema..."
    apt update && apt -y upgrade
    print_success "Sistema actualizado"
fi

# Configurar entorno virtual
setup_virtualenv

# Instalar componentes
install_adafruit_blinka
install_voice_card
install_dotstar

print_success "¡Configuración completada!"
print_status "Para usar las librerías instaladas, activa el entorno virtual con: workon $VENV_NAME"

if ask_yes_no "¿Deseas reiniciar el sistema ahora?"; then
    print_status "Reiniciando sistema..."
    reboot
fi