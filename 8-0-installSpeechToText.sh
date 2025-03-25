#!/bin/bash
# Script para instalar correctamente SpeechRecognition y sus dependencias en un entorno virtual

echo "==== Instalando SpeechRecognition y dependencias ===="

# Instalar dependencias del sistema (necesita sudo)
echo "Instalando dependencias del sistema..."
sudo apt-get update
sudo apt-get install -y portaudio19-dev flac

# Verificar si la instalación fue exitosa
if [ $? -ne 0 ]; then
    echo "Error: No se pudieron instalar las dependencias del sistema."
    echo "Por favor, ejecuta 'sudo apt-get install -y portaudio19-dev flac' manualmente."
    exit 1
fi

# Instalar PyAudio (ahora debería funcionar con portaudio19-dev instalado)
echo "Instalando PyAudio..."
pip install PyAudio

# Verificar si la instalación fue exitosa
if [ $? -ne 0 ]; then
    echo "Error: No se pudo instalar PyAudio."
    echo "Intentando método alternativo..."
    
    # Intentar instalación con piwheels (optimizado para Raspberry Pi)
    pip install https://www.piwheels.org/simple/pyaudio/PyAudio-0.2.13-cp311-cp311-linux_aarch64.whl
    
    if [ $? -ne 0 ]; then
        echo "Error: Falló el método alternativo."
        echo "Por favor, intenta con: sudo apt-get install python3-pyaudio"
        exit 1
    fi
fi

# Instalar SpeechRecognition con la opción no-cache-dir
echo "Instalando SpeechRecognition..."
pip install --no-cache-dir SpeechRecognition

# Verificar si la instalación fue exitosa
if [ $? -ne 0 ]; then
    echo "Error: No se pudo instalar SpeechRecognition."
    exit 1
fi

# Instalar gTTS para text-to-speech
echo "Instalando gTTS para text-to-speech..."
pip install gtts

# Verificar si la instalación fue exitosa
if [ $? -ne 0 ]; then
    echo "Error: No se pudo instalar gTTS."
    exit 1
fi

# Instalar googletrans para soporte de español
echo "Instalando googletrans para soporte de español..."
pip install googletrans==4.0.0-rc1

echo "==== Instalación completada ===="
echo "Ahora puedes usar SpeechRecognition y gTTS en tu ambiente virtual."

# Verificar instalación con un pequeño test
echo "Realizando prueba básica de importación..."
python -c "import speech_recognition as sr; import gtts; print('Importación exitosa!')"

if [ $? -eq 0 ]; then
    echo "¡Todo instalado correctamente!"
else
    echo "Advertencia: Las bibliotecas se instalaron pero hay problemas al importarlas."
    echo "Es posible que necesites reiniciar tu entorno virtual o terminal."
fi
