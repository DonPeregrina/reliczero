#!/bin/bash

# Script para instalar pantalla LCD 3.5" en Raspberry Pi
# Creado: 8 de marzo de 2025

echo "===== Iniciando instalación de pantalla LCD 3.5 pulgadas ====="
echo "Este script configurará su Raspberry Pi para usar una pantalla LCD de 3.5 pulgadas"

# Verificar si el directorio LCD-show existe
if [ ! -d "LCD-show" ]; then
    echo "El directorio LCD-show no existe. ¿Desea descargarlo? (s/n)"
    read respuesta
    if [ "$respuesta" = "s" ]; then
        echo "Descargando los controladores LCD-show..."
        git clone https://github.com/goodtft/LCD-show.git
    else
        echo "Instalación cancelada. El directorio LCD-show es necesario para continuar."
        exit 1
    fi
fi

# Establecer permisos
echo "Estableciendo permisos en el directorio LCD-show..."
chmod -R 755 LCD-show

# Cambiar al directorio LCD-show
echo "Cambiando al directorio LCD-show..."
cd LCD-show/

# Ejecutar el script de instalación
echo "Ejecutando el script de instalación para LCD 3.5 pulgadas..."
echo "NOTA: El sistema se reiniciará automáticamente después de la instalación"
echo "¿Desea continuar? (s/n)"
read confirmacion
if [ "$confirmacion" = "s" ]; then
    sudo ./LCD35-show
else
    echo "Instalación cancelada por el usuario."
    exit 0
fi

# Este código no se ejecutará debido al reinicio, pero lo incluimos para completitud
echo "Instalación completada. Si está viendo este mensaje, el reinicio automático no ocurrió."
echo "Por favor, reinicie manualmente su Raspberry Pi."

exit 0
