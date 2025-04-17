#!/bin/bash

# Script de instalación para X120 en Raspberry Pi 5

# Colores para mensajes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Función para mostrar mensajes
mostrar_mensaje() {
    echo -e "${GREEN}$1${NC}"
}

# Función para mostrar errores
mostrar_error() {
    echo -e "${RED}$1${NC}"
}

# Función para mostrar advertencias
mostrar_advertencia() {
    echo -e "${YELLOW}$1${NC}"
}

# Verificar si se está ejecutando como root
if [ "$EUID" -ne 0 ]; then
    mostrar_error "Este script debe ejecutarse como root. Por favor, usa 'sudo'."
    exit 1
fi

# Menú principal
while true; do
    clear
    echo "============================================================"
    echo "      Instalador para X120 en Raspberry Pi 5"
    echo "============================================================"
    echo "Opciones disponibles:"
    echo "1. Editar configuración EEPROM (POWER_OFF_ON_HALT y PSU_MAX_CURRENT)"
    echo "2. Configurar Raspberry Pi para I2C (usando raspi-config)"
    echo "3. Descargar scripts de GitHub y detectar dispositivos I2C"
    echo "4. Ejecutar todo (instalar todos los componentes)"
    echo "0. Salir"
    echo "============================================================"
    echo "Notas adicionales:"
    echo "- Para leer el estado del UPS: sudo python3 merged.py"
    echo "- Para interfaz de escritorio: sudo python3 qtx120x.py"
    echo "============================================================"
    
    read -p "Selecciona una opción (0-4): " opcion
    
    case $opcion in
        1)
            # Editar configuración EEPROM
            mostrar_mensaje "Editando configuración EEPROM..."
            
            # Ejecutar rpi-eeprom-config -e
            mostrar_mensaje "Ejecutando sudo rpi-eeprom-config -e"
            mostrar_mensaje "Debes cambiar POWER_OFF_ON_HALT de 0 a 1 y añadir PSU_MAX_CURRENT=5000 al final del archivo"
            mostrar_advertencia "Presiona ENTER para abrir el editor. Cuando termines, guarda con CTRL+X, luego Y y ENTER"
            read -p "Presiona ENTER para continuar..."
            
            sudo rpi-eeprom-config -e
            
            mostrar_mensaje "Configuración EEPROM actualizada."
            mostrar_advertencia "Es necesario reiniciar para aplicar los cambios."
            
            read -p "¿Deseas reiniciar ahora? (s/n): " reiniciar
            if [[ $reiniciar == "s" || $reiniciar == "S" ]]; then
                sudo reboot
            fi
            
            read -p "Presiona Enter para continuar..."
            ;;
            
        2)
            # Configurar Raspberry Pi para I2C
            mostrar_mensaje "Configurando Raspberry Pi para I2C usando raspi-config..."
            mostrar_advertencia "Se abrirá raspi-config. Sigue estos pasos:"
            echo "1. Selecciona 'Interfacing Options'"
            echo "2. Selecciona 'I2C'"
            echo "3. Selecciona 'Yes'"
            echo "4. Selecciona 'Ok'"
            echo "5. Selecciona 'Finish'"
            
            read -p "Presiona ENTER para abrir raspi-config..."
            
            sudo raspi-config
            
            mostrar_mensaje "I2C configurado correctamente."
            mostrar_advertencia "Es recomendable reiniciar después de habilitar I2C."
            
            read -p "¿Deseas reiniciar ahora? (s/n): " reiniciar
            if [[ $reiniciar == "s" || $reiniciar == "S" ]]; then
                sudo reboot
            fi
            
            read -p "Presiona Enter para continuar..."
            ;;
            
        3)
            # Descargar scripts y detectar dispositivos I2C
            mostrar_mensaje "Descargando scripts de GitHub..."
            
            # Clonar repositorio
            git clone https://github.com/suptronics/x120x.git
            
            if [ $? -eq 0 ]; then
                mostrar_mensaje "Repositorio clonado correctamente en ~/x120x"
                
                # Detectar dispositivos I2C
                mostrar_mensaje "Ejecutando i2cdetect para ver dispositivos conectados..."
                sudo i2cdetect -y 1
                
                mostrar_mensaje "Puedes ejecutar los siguientes comandos para usar el X120:"
                echo "Para leer el estado del UPS: cd ~/x120x && sudo python3 merged.py"
                echo "Para interfaz de escritorio: cd ~/x120x && sudo python3 qtx120x.py"
                
                mostrar_advertencia "Es recomendable reiniciar después de la instalación."
                
                read -p "¿Deseas reiniciar ahora? (s/n): " reiniciar
                if [[ $reiniciar == "s" || $reiniciar == "S" ]]; then
                    sudo reboot
                fi
            else
                mostrar_error "Error al clonar el repositorio. Verifica tu conexión a internet."
            fi
            
            read -p "Presiona Enter para continuar..."
            ;;
            
        4)
            # Ejecutar todo
            mostrar_mensaje "Instalando todos los componentes..."
            
            # EEPROM
            mostrar_mensaje "Ejecutando sudo rpi-eeprom-config -e"
            mostrar_mensaje "Debes cambiar POWER_OFF_ON_HALT de 0 a 1 y añadir PSU_MAX_CURRENT=5000 al final del archivo"
            mostrar_advertencia "Presiona ENTER para abrir el editor. Cuando termines, guarda con CTRL+X, luego Y y ENTER"
            read -p "Presiona ENTER para continuar..."
            
            sudo rpi-eeprom-config -e
            
            # I2C
            mostrar_mensaje "Configurando Raspberry Pi para I2C usando raspi-config..."
            mostrar_advertencia "Se abrirá raspi-config. Sigue estos pasos:"
            echo "1. Selecciona 'Interfacing Options'"
            echo "2. Selecciona 'I2C'"
            echo "3. Selecciona 'Yes'"
            echo "4. Selecciona 'Ok'"
            echo "5. Selecciona 'Finish'"
            
            read -p "Presiona ENTER para abrir raspi-config..."
            
            sudo raspi-config
            
            # Clonar repositorio
            mostrar_mensaje "Descargando scripts de GitHub..."
            git clone https://github.com/suptronics/x120x.git
            
            if [ $? -eq 0 ]; then
                mostrar_mensaje "Repositorio clonado correctamente en ~/x120x"
                
                # Detectar dispositivos I2C
                mostrar_mensaje "Ejecutando i2cdetect para ver dispositivos conectados..."
                sudo i2cdetect -y 1
                
                mostrar_mensaje "Puedes ejecutar los siguientes comandos para usar el X120:"
                echo "Para leer el estado del UPS: cd ~/x120x && sudo python3 merged.py"
                echo "Para interfaz de escritorio: cd ~/x120x && sudo python3 qtx120x.py"
            else
                mostrar_error "Error al clonar el repositorio. Verifica tu conexión a internet."
            fi
            
            mostrar_mensaje "Instalación completa. Es necesario reiniciar para aplicar todos los cambios."
            
            read -p "¿Deseas reiniciar ahora? (s/n): " reiniciar
            if [[ $reiniciar == "s" || $reiniciar == "S" ]]; then
                sudo reboot
            fi
            
            read -p "Presiona Enter para continuar..."
            ;;
            
        0)
            # Salir
            mostrar_mensaje "Saliendo del instalador. ¡Gracias por usar este script!"
            
            # Recordatorio final
            mostrar_mensaje "Recuerda que puedes usar estos comandos para el X120:"
            echo "Para leer el estado del UPS: cd ~/x120x && sudo python3 merged.py"
            echo "Para interfaz de escritorio: cd ~/x120x && sudo python3 qtx120x.py"
            
            exit 0
            ;;
            
        *)
            mostrar_error "Opción inválida. Por favor, selecciona una opción entre 0 y 4."
            read -p "Presiona Enter para continuar..."
            ;;
    esac
done
