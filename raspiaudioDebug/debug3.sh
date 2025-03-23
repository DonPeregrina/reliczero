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
echo "      REPARACIÓN FINAL DE AUDIO PARA RASPIAUDIO      "
echo "======================================================"
echo -e "${NC}"

# Detectar tarjeta de sonido y parámetros
info "Detectando tarjetas de sonido..."
aplay -l

# Verificar específicamente la tarjeta RaspiAudio
CARD_ID=$(aplay -l | grep -i "googlevoicehat\|voicehat" | head -n 1 | awk -F': ' '{print $1}' | awk '{print $2}')

if [ -z "$CARD_ID" ]; then
    advertencia "No se pudo detectar la tarjeta RaspiAudio automáticamente."
    info "Asumiendo que es la tarjeta 0 según los resultados anteriores."
    CARD_ID=0
else
    exito "RaspiAudio detectado como tarjeta $CARD_ID"
fi

# 1. Crear archivo asound.conf directo con hw
info "Creando una configuración ALSA básica y limpia..."

sudo tee /etc/asound.conf > /dev/null << EOL
pcm.!default {
    type hw
    card $CARD_ID
    device 0
}

ctl.!default {
    type hw
    card $CARD_ID
}
EOL

exito "Archivo asound.conf básico creado para depuración."

# 2. Reiniciar el servicio de sonido correctamente
info "Reiniciando el servicio de sonido..."
sudo pkill -9 pulseaudio 2>/dev/null || true
sudo service alsa-utils restart 2>/dev/null || true
sudo alsactl kill quit 2>/dev/null || true
sudo alsactl store 2>/dev/null || true

# En algunos sistemas, los comandos pueden variar
if command -v systemctl > /dev/null; then
    sudo systemctl restart alsa-restore 2>/dev/null || true
fi

exito "Servicios de audio reiniciados."

# 3. Ajustar volumen con amixer si el control existe
info "Intentando ajustar el volumen..."
amixer -c $CARD_ID scontrols

# Intentar ajustar cualquier control que encontremos
CONTROL=$(amixer -c $CARD_ID scontrols | head -n 1 | cut -d"'" -f2)
if [ -n "$CONTROL" ]; then
    info "Ajustando el control '$CONTROL' al 30%..."
    amixer -c $CARD_ID set "$CONTROL" 30%
    exito "Volumen ajustado al 30%."
else
    advertencia "No se encontraron controles de volumen para ajustar."
fi

# 4. Verificar estado actual
info "Estado actual de la configuración de audio:"
amixer -c $CARD_ID contents

# 5. Prueba simple con la configuración básica
info "Probando reproducción de audio con configuración básica..."
info "Ejecutando speaker-test directamente con hw..."

echo "Probando tono de 440Hz a volumen bajo:"
speaker-test -D hw:$CARD_ID,0 -t sine -f 440 -l1 -c2

# 6. Si la prueba básica funciona, añadir configuración más sofisticada
info "Creando configuración ALSA mejorada..."

sudo tee /etc/asound.conf > /dev/null << EOL
pcm.!default {
    type plug
    slave.pcm "dmixer"
}

pcm.dmixer {
    type dmix
    ipc_key 1024
    slave {
        pcm "hw:$CARD_ID,0"
        period_time 0
        period_size 1024
        buffer_size 4096
        rate 48000
    }
}

ctl.!default {
    type hw
    card $CARD_ID
}

# Configuración para grabación
pcm.mic {
    type plug
    slave {
        pcm "hw:$CARD_ID,0"
        rate 44100
        channels 1
    }
}
EOL

exito "Configuración ALSA mejorada creada."

# 7. Probando la nueva configuración
info "Probando la configuración mejorada..."
info "Ejecutando speaker-test con la nueva configuración..."

speaker-test -l1 -c2 -t sine -f 440

echo -e "${CYAN}"
echo "======================================================"
echo "            PRUEBA FINAL - AJUSTE FINO               "
echo "======================================================"
echo -e "${NC}"

info "Vamos a probar grabando y reproduciendo un archivo..."

info "Grabando 3 segundos de audio... (habla al micrófono)"
arecord -d 3 -f cd -t wav /tmp/test_mic.wav

info "Reproduciendo la grabación..."
aplay /tmp/test_mic.wav

info "Comandos útiles para el futuro:"
echo "1. Grabar audio: arecord -f cd -d [segundos] [archivo.wav]"
echo "2. Reproducir audio: aplay [archivo.wav]"
echo "3. Ajustar volumen: amixer -c $CARD_ID set '$CONTROL' [0-100]%"
echo "4. Ver controles: amixer -c $CARD_ID scontrols"
echo "5. Configuración avanzada: alsamixer -c $CARD_ID"

echo -e "${VERDE}Esta configuración debe proporcionar una calidad de audio mejorada.${NC}"
echo -e "${VERDE}Si el audio sigue con problemas, reinicia el sistema con: sudo reboot${NC}"

read -p "¿Quieres reiniciar el sistema ahora? (si/no): " reiniciar_ahora
if [[ "$reiniciar_ahora" =~ ^[Ss][Ii]?$ ]]; then
    info "Reiniciando sistema..."
    sudo reboot
else
    info "No se reiniciará. Prueba la configuración y reinicia manualmente si es necesario."
fi
