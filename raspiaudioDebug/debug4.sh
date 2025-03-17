#!/bin/bash

# Colores para mejor visualización
ROJO='\033[0;31m'
VERDE='\033[0;32m'
AMARILLO='\033[0;33m'
AZUL='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # Sin Color

# Función para mensajes informativos
info() {
    echo -e "${AZUL}[INFO]${NC} $1"
}

# Función para mensajes de éxito
exito() {
    echo -e "${VERDE}[ÉXITO]${NC} $1"
}

# Función para mensajes de advertencia
advertencia() {
    echo -e "${AMARILLO}[ADVERTENCIA]${NC} $1"
}

# Banner de inicio
echo -e "${CYAN}"
echo "======================================================"
echo "         CONFIGURACIÓN DE GRABACIÓN RASPIAUDIO        "
echo "======================================================"
echo -e "${NC}"

# Detectar tarjeta de sonido
info "Detectando tarjetas de sonido..."
aplay -l
arecord -l

# Verificar la tarjeta RaspiAudio
CARD_ID=$(arecord -l | grep -i "googlevoicehat\|voicehat" | head -n 1 | awk -F': ' '{print $1}' | awk '{print $2}')

if [ -z "$CARD_ID" ]; then
    info "No se pudo detectar automáticamente. Usando tarjeta 0 según resultados anteriores."
    CARD_ID=0
else
    exito "RaspiAudio detectado como tarjeta $CARD_ID para grabación"
fi

# Crear una configuración ALSA que separe reproducción y grabación
info "Creando configuración ALSA optimizada para grabación y reproducción..."

# Crear el archivo asound.conf con configuración separada para grabación y reproducción
sudo tee /etc/asound.conf > /dev/null << EOL
# Dispositivo predeterminado
pcm.!default {
    type asym
    playback.pcm "playback"
    capture.pcm "capture"
}

# Configuración para reproducción
pcm.playback {
    type plug
    slave.pcm "hw:$CARD_ID,0"
    slave.format S16_LE
    slave.rate 48000
    slave.channels 2
}

# Configuración para grabación
pcm.capture {
    type plug
    slave.pcm "hw:$CARD_ID,0"
    slave.format S16_LE
    slave.rate 16000
    slave.channels 1
}

# Control predeterminado
ctl.!default {
    type hw
    card $CARD_ID
}
EOL

exito "Archivo asound.conf configurado para separar grabación y reproducción."

# Reiniciar servicios de audio
info "Reiniciando servicios de audio..."
sudo pkill -9 pulseaudio 2>/dev/null || true
sudo service alsa-utils restart 2>/dev/null || true
sudo alsactl kill quit 2>/dev/null || true
sudo alsactl store 2>/dev/null || true

# Establecer volumen a un nivel adecuado
info "Estableciendo volumen a un nivel adecuado..."
amixer -c $CARD_ID set 'Master' 30% 2>/dev/null || true

info "Verificando controles de captura..."
amixer -c $CARD_ID scontrols | grep -i "cap\|mic"

# Intentar habilitar y aumentar la captura si hay controles
if amixer -c $CARD_ID scontrols | grep -i -q "capture"; then
    info "Ajustando control de captura..."
    CAPTURE_CONTROL=$(amixer -c $CARD_ID scontrols | grep -i "capture" | head -n 1 | cut -d"'" -f2)
    amixer -c $CARD_ID set "$CAPTURE_CONTROL" 90% unmute 2>/dev/null || true
fi

if amixer -c $CARD_ID scontrols | grep -i -q "mic"; then
    info "Ajustando control de micrófono..."
    MIC_CONTROL=$(amixer -c $CARD_ID scontrols | grep -i "mic" | head -n 1 | cut -d"'" -f2)
    amixer -c $CARD_ID set "$MIC_CONTROL" 90% unmute 2>/dev/null || true
fi

# Verificar que el módulo está cargado correctamente
info "Verificando que el módulo GoogleVoiceHAT está cargado correctamente..."
lsmod | grep -i "googlevoicehat"

# Verificar la configuración en config.txt
info "Verificando configuración en /boot/config.txt..."
grep -i "dtoverlay=googlevoicehat" /boot/config.txt

# Probar grabación directamente con el dispositivo hw
info "Probando grabación directamente con el dispositivo hw..."
echo "Grabando 3 segundos... (habla al micrófono)"
arecord -D hw:$CARD_ID,0 -d 3 -f S16_LE -r 16000 -c1 /tmp/test_direct.wav

if [ $? -eq 0 ]; then
    exito "Grabación directa exitosa."
    info "Reproduciendo grabación..."
    aplay /tmp/test_direct.wav
else
    advertencia "La grabación directa falló. Probando método alternativo..."
    
    # Probar grabación con plughw
    info "Probando grabación con plughw..."
    arecord -D plughw:$CARD_ID,0 -d 3 -f S16_LE -r 16000 -c1 /tmp/test_plug.wav
    
    if [ $? -eq 0 ]; then
        exito "Grabación con plughw exitosa."
        info "Reproduciendo grabación..."
        aplay /tmp/test_plug.wav
    else
        advertencia "La grabación con plughw también falló."
    fi
fi

# Probar grabación con la nueva configuración
info "Probando grabación con la configuración ALSA personalizada..."
echo "Grabando 3 segundos... (habla al micrófono)"
arecord -D capture -d 3 /tmp/test_config.wav

if [ $? -eq 0 ]; then
    exito "¡Grabación exitosa!"
    info "Reproduciendo grabación..."
    aplay -D playback /tmp/test_config.wav
else
    advertencia "La grabación falló. Esto podría requerir un reinicio del sistema."
fi

echo -e "${CYAN}"
echo "======================================================"
echo "              CONFIGURACIÓN COMPLETADA                "
echo "======================================================"
echo -e "${NC}"

info "Comandos recomendados para usar tu RaspiAudio MIC+:"
echo "1. Para grabar: arecord -D capture -d [segundos] [archivo.wav]"
echo "2. Para reproducir: aplay -D playback [archivo.wav]"
echo "3. Para grabar en mejor calidad: arecord -D capture -f S16_LE -r 16000 -c1 [archivo.wav]"

info "Para usar RaspiAudio con Python y pydub, activa tu entorno virtual y ejecuta:"
echo "pip install pydub"
echo "sudo apt-get install ffmpeg"

echo -e "${VERDE}Si sigues teniendo problemas con la grabación, un reinicio del sistema es recomendable.${NC}"
read -p "¿Quieres reiniciar el sistema ahora? (si/no): " reiniciar_ahora
if [[ "$reiniciar_ahora" =~ ^[Ss][Ii]?$ ]]; then
    info "Reiniciando sistema..."
    sudo reboot
else
    info "No se reiniciará. Puedes reiniciar manualmente más tarde si es necesario."
fi
