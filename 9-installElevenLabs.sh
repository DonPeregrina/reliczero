#!/bin/bash
# Script para instalar las dependencias de Eleven Labs y configurar la API key

echo "==== Instalando dependencias para Eleven Labs ===="

# Instalar elevenlabs, soundfile y sounddevice
echo "Instalando bibliotecas Python necesarias..."
pip install elevenlabs soundfile sounddevice

# Verificar si la instalación fue exitosa
if [ $? -ne 0 ]; then
    echo "Error: No se pudieron instalar las bibliotecas."
    exit 1
fi

# Solicitar API key si no existe en .env
if [ ! -f .env ] || ! grep -q "ELEVENLABS_API_KEY" .env; then
    echo "No se encontró la API key de Eleven Labs en el archivo .env"
    echo "Por favor, ingresa tu API key de Eleven Labs:"
    read api_key
    
    # Crear o actualizar archivo .env
    if [ ! -f .env ]; then
        echo "ELEVENLABS_API_KEY=$api_key" > .env
    else
        echo "ELEVENLABS_API_KEY=$api_key" >> .env
    fi
    
    echo "API key guardada en el archivo .env"
else
    echo "Se encontró una API key de Eleven Labs en el archivo .env"
fi

echo "==== Instalación completada ===="
echo "Ahora puedes usar Eleven Labs para síntesis de voz avanzada."
