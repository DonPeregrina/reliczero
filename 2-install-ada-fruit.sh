#!/bin/bash

# Colores para los mensajes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Función para verificar si un paquete pip está instalado
check_pip_package() {
    pip show $1 > /dev/null 2>&1
}

# Función para verificar si un paquete apt está instalado
check_apt_package() {
    if dpkg -l | grep -q "^ii  $1 "; then
        return 0 # Ya está instalado
    else
        return 1 # No está instalado
    fi
}

echo -e "${BLUE}Iniciando instalación de Adafruit Voice Bonnet para Desktop...${NC}"

# Instalar RPi.GPIO si no está instalado
if ! check_pip_package "RPi.GPIO"; then
    echo -e "${GREEN}1. Instalando RPi.GPIO...${NC}"
    pip install RPi.GPIO
else
    echo -e "${YELLOW}RPi.GPIO ya está instalado. Saltando...${NC}"
fi

# Instalar libraspberrypi-dev si no está instalado
if ! check_apt_package "libraspberrypi-dev"; then
    echo -e "${GREEN}2. Instalando libraspberrypi-dev...${NC}"
    sudo apt-get install libraspberrypi-dev -y
else
    echo -e "${YELLOW}libraspberrypi-dev ya está instalado. Saltando...${NC}"
fi

# Instalar git si no está instalado
if ! check_apt_package "git"; then
    echo -e "${GREEN}3. Instalando git...${NC}"
    sudo apt install git -y
else
    echo -e "${YELLOW}git ya está instalado. Saltando...${NC}"
fi

# Instalar i2c-tools si no está instalado
if ! check_apt_package "i2c-tools"; then
    echo -e "${GREEN}4. Instalando i2c-tools...${NC}"
    sudo apt-get install i2c-tools -y
else
    echo -e "${YELLOW}i2c-tools ya está instalado. Saltando...${NC}"
fi

# Instalar adafruit-python-shell si no está instalado
if ! check_pip_package "adafruit-python-shell"; then
    echo -e "${GREEN}5. Instalando adafruit-python-shell...${NC}"
    pip install --upgrade adafruit-python-shell
else
    echo -e "${YELLOW}adafruit-python-shell ya está instalado. Saltando...${NC}"
fi

# Descargar e instalar Blinka solo si no existe el archivo
if [ ! -f "raspi-blinka.py" ]; then
    echo -e "${GREEN}6. Descargando script de instalación de Blinka...${NC}"
    wget -4 https://raw.githubusercontent.com/adafruit/Raspberry-Pi-Installer-Scripts/master/raspi-blinka.py
    echo -e "${GREEN}7. Ejecutando instalación de Blinka...${NC}"
    sudo -E env PATH=$PATH python3 raspi-blinka.py
else
    echo -e "${YELLOW}Script de Blinka ya existe. Saltando descarga...${NC}"
fi

# Añadir configuraciones de audio sin tocar video
echo -e "${GREEN}8. Configurando audio...${NC}"
if ! grep -q "dtoverlay=i2s-mmap" /boot/firmware/config.txt; then
    echo -e "${YELLOW}Agregando configuración de I2S...${NC}"
    sudo sh -c 'echo "\n# Audio configuration for Voice Bonnet
dtparam=i2s=on
dtparam=i2c=on
dtoverlay=i2s-mmap" >> /boot/firmware/config.txt'
fi



# Instalar adafruit-circuitpython-dotstar
if ! check_pip_package "adafruit-circuitpython-dotstar"; then
    echo -e "${GREEN}10. Instalando adafruit-circuitpython-dotstar...${NC}"
    pip install adafruit-circuitpython-dotstar
else
    echo -e "${YELLOW}adafruit-circuitpython-dotstar ya está instalado. Saltando...${NC}"
fi

echo -e "${BLUE}Instalación completada.${NC}"
echo -e "${YELLOW}IMPORTANTE: Por favor, reinicia manualmente el sistema con 'sudo reboot'${NC}"
echo -e "${YELLOW}Después del reinicio, ejecuta el script de verificación para comprobar la instalación.${NC}"