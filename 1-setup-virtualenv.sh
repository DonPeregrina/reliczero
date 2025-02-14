#!/bin/bash

# Colores para los mensajes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}Iniciando configuración del entorno virtual...${NC}"

# Actualizar el sistema
echo -e "${GREEN}1. Actualizando el sistema...${NC}"
sudo apt update
sudo apt -y upgrade

# Instalar virtualenv y dependencias
echo -e "${GREEN}2. Instalando virtualenv y dependencias...${NC}"
sudo apt install virtualenv -y
sudo apt install python3-pip -y
sudo apt install python3-virtualenvwrapper -y
sudo apt-get install python3-setuptools -y

# Configurar virtualenvwrapper
echo -e "${GREEN}3. Configurando virtualenvwrapper...${NC}"
echo "export WORKON_HOME=$HOME/.virtualenvs" >> ~/.bashrc
echo "export VIRTUALENVWRAPPER_PYTHON=/usr/bin/python3" >> ~/.bashrc
echo "source /usr/share/virtualenvwrapper/virtualenvwrapper.sh" >> ~/.bashrc

# Recargar bashrc
echo -e "${GREEN}4. Recargando configuración...${NC}"
source ~/.bashrc

# Solicitar nombre del ambiente virtual
echo -e "${BLUE}¡Instalación completada!${NC}"
echo -e "${BLUE}Por favor, ingresa el nombre que deseas para tu ambiente virtual:${NC}"
read env_name

# Crear ambiente virtual
echo -e "${GREEN}5. Creando ambiente virtual '$env_name'...${NC}"
mkvirtualenv $env_name

echo -e "${BLUE}¡Listo! Para activar tu ambiente virtual usa: ${GREEN}workon $env_name${NC}"
echo -e "${BLUE}Para desactivarlo usa: ${GREEN}deactivate${NC}"