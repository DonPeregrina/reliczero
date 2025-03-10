#!/bin/bash

# Colores para los mensajes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}Verificando instalación del Voice Bonnet...${NC}"

# Verificar/Instalar i2c-tools
if ! command -v i2cdetect &> /dev/null; then
    echo -e "${YELLOW}Instalando i2c-tools...${NC}"
    sudo apt-get install -y i2c-tools
fi

# Verificar/Instalar alsa-utils
if ! command -v aplay &> /dev/null; then
    echo -e "${YELLOW}Instalando alsa-utils...${NC}"
    sudo apt-get install -y alsa-utils
fi

echo -e "\n${GREEN}1. Verificando tarjeta de audio:${NC}"
aplay -l

echo -e "\n${GREEN}2. Verificando I2C (buscando dirección 1a):${NC}"
sudo i2cdetect -y 1

echo -e "\n${GREEN}3. Verificando carga de módulos de audio:${NC}"
lsmod | grep "snd_soc_wm8960\|snd_soc_seeed\|snd_soc_core"

echo -e "\n${YELLOW}Si ves la dirección '1a' en la tabla de I2C, el hardware está siendo detectado.${NC}"
echo -e "${YELLOW}Si no ves ningún módulo de audio cargado, puede que necesites reiniciar.${NC}"