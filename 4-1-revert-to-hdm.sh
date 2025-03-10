#!/bin/bash

# Script para revertir la configuración de la pantalla LCD 3.5" 
# y volver a la configuración HDMI estándar en Raspberry Pi
# Creado: 8 de marzo de 2025

echo "===== Iniciando reversión a configuración HDMI estándar ====="
echo "Este script revertirá la configuración de su Raspberry Pi para usar HDMI en lugar de la pantalla LCD"

# Verificar si el directorio LCD-show existe
if [ ! -d "LCD-show" ]; then
    echo "El directorio LCD-show no existe. ¿Desea descargarlo? (s/n)"
    read respuesta
    if [ "$respuesta" = "s" ]; then
        echo "Descargando los controladores LCD-show..."
        git clone https://github.com/goodtft/LCD-show.git
    else
        echo "Reversión cancelada. El directorio LCD-show es necesario para continuar."
        exit 1
    fi
fi

# Establecer permisos si es necesario
echo "Estableciendo permisos en el directorio LCD-show..."
chmod -R 755 LCD-show

# Cambiar al directorio LCD-show
echo "Cambiando al directorio LCD-show..."
cd LCD-show/

# Ejecutar el script para volver a HDMI
echo "Ejecutando el script para volver a la configuración HDMI..."
echo "NOTA: El sistema se reiniciará automáticamente después de la reversión"
echo "¿Desea continuar? (s/n)"
read confirmacion
if [ "$confirmacion" = "s" ]; then
    sudo ./LCD-hdmi
else
    echo "Reversión cancelada por el usuario."
    exit 0
fi

# Este código no se ejecutará debido al reinicio, pero lo incluimos para completitud
echo "Reversión completada. Si está viendo este mensaje, el reinicio automático no ocurrió."
echo "Por favor, reinicie manualmente su Raspberry Pi."

exit 0
