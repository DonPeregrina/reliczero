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
echo "      DIAGNÓSTICO DE AUDIO PARA RASPIAUDIO MIC+      "
echo "======================================================"
echo -e "${NC}"

# 1. Diagnóstico de dispositivos de audio
info "Verificando dispositivos de audio..."
echo "--- Tarjetas de sonido detectadas: ---"
aplay -l
echo "--- Dispositivos de captura detectados: ---"
arecord -l
echo ""

# 2. Verificar módulos de kernel cargados
info "Verificando módulos del kernel relacionados con audio..."
lsmod | grep -E "snd|audio|voice|google"
echo ""

# 3. Verificar configuración actual de ALSA
info "Verificando configuración actual de ALSA..."

# Mostrar el contenido de asound.conf
echo "--- Contenido de /etc/asound.conf: ---"
cat /etc/asound.conf 2>/dev/null || echo "No existe el archivo /etc/asound.conf"
echo ""

# Verificar el estado actual de la tarjeta
echo "--- Estado actual de la tarjeta: ---"
amixer
echo ""

# 4. Pruebas de ajuste de volumen
info "Realizando pruebas de ajuste de volumen..."

# Identificar los controles disponibles
echo "--- Controles de volumen disponibles: ---"
amixer scontrols
echo ""

# Encontrar el control principal
CONTROL_PRINCIPAL=$(amixer scontrols | grep -i -E 'master|pcm|spea|dac' | head -n 1 | cut -d"'" -f2)

if [ -n "$CONTROL_PRINCIPAL" ]; then
    info "Control principal identificado: $CONTROL_PRINCIPAL"
    
    # Ajustar a nivel medio-bajo (20%)
    echo "--- Ajustando $CONTROL_PRINCIPAL al 20% ---"
    amixer set "$CONTROL_PRINCIPAL" 20%
    amixer get "$CONTROL_PRINCIPAL"
    
    # Prueba de sonido a volumen bajo
    info "Reproduciendo 3 segundos de sonido al 20% de volumen..."
    speaker-test -l1 -c2 -t wav
    
    # Preguntar al usuario
    read -p "¿Sonó mejor a este volumen? (si/no): " respuesta_volumen_bajo
    
    # Ajustar ganancia si es necesario
    if [[ "$respuesta_volumen_bajo" =~ ^[Ss][Ii]?$ ]]; then
        exito "El volumen bajo mejora la calidad. Vamos a hacer este ajuste permanente."
        amixer set "$CONTROL_PRINCIPAL" 20%
    else
        info "Probando con ajustes de volumen más específicos..."
    fi
else
    advertencia "No se pudo identificar un control principal."
fi

# 5. Verificando configuración de dtoverlay
info "Verificando configuración de dtoverlay en /boot/config.txt..."
DTOVERLAY=$(grep -i "dtoverlay=.*voice\|dtoverlay=.*audio" /boot/config.txt)
echo "Configuración actual: $DTOVERLAY"
echo ""

# 6. Probar diferentes frecuencias de muestreo
info "Probando diferentes tasas de muestreo para identificar problemas de calidad..."

echo "--- Prueba con 16kHz ---"
speaker-test -r 16000 -l1 -c2 -t sine -f 440
read -p "¿Cómo sonó la prueba a 16kHz? (bien/mal): " respuesta_16k

echo "--- Prueba con 44.1kHz ---"
speaker-test -r 44100 -l1 -c2 -t sine -f 440
read -p "¿Cómo sonó la prueba a 44.1kHz? (bien/mal): " respuesta_44k

echo "--- Prueba con 48kHz ---"
speaker-test -r 48000 -l1 -c2 -t sine -f 440
read -p "¿Cómo sonó la prueba a 48kHz? (bien/mal): " respuesta_48k

# 7. Prueba de formato de audio
info "Probando diferentes formatos de audio..."

echo "--- Prueba con formato S16_LE (16-bit) ---"
speaker-test -r 44100 -f S16_LE -l1 -c2 -t sine -f 440
read -p "¿Cómo sonó la prueba con formato 16-bit? (bien/mal): " respuesta_16bit

echo "--- Prueba con formato S24_LE (24-bit) ---"
speaker-test -r 44100 -f S24_LE -l1 -c2 -t sine -f 440
read -p "¿Cómo sonó la prueba con formato 24-bit? (bien/mal): " respuesta_24bit

# 8. Crear configuración ALSA optimizada según resultados
info "Creando configuración ALSA optimizada según los resultados..."

# Determinar mejor tasa de muestreo
MEJOR_TASA=""
if [[ "$respuesta_16k" == "bien" && "$respuesta_44k" != "bien" && "$respuesta_48k" != "bien" ]]; then
    MEJOR_TASA="16000"
elif [[ "$respuesta_44k" == "bien" && "$respuesta_16k" != "bien" && "$respuesta_48k" != "bien" ]]; then
    MEJOR_TASA="44100"
elif [[ "$respuesta_48k" == "bien" && "$respuesta_16k" != "bien" && "$respuesta_44k" != "bien" ]]; then
    MEJOR_TASA="48000"
else
    # Por defecto usar 44100
    MEJOR_TASA="44100"
    advertencia "No se pudo determinar una tasa óptima. Usando 44.1kHz por defecto."
fi

# Determinar mejor formato
MEJOR_FORMATO=""
if [[ "$respuesta_16bit" == "bien" && "$respuesta_24bit" != "bien" ]]; then
    MEJOR_FORMATO="S16_LE"
elif [[ "$respuesta_24bit" == "bien" && "$respuesta_16bit" != "bien" ]]; then
    MEJOR_FORMATO="S24_LE"
else
    # Por defecto usar S16_LE
    MEJOR_FORMATO="S16_LE"
    advertencia "No se pudo determinar un formato óptimo. Usando 16-bit por defecto."
fi

# 9. Crear archivo asound.conf optimizado
info "Creando archivo asound.conf optimizado con los mejores parámetros..."

sudo tee /etc/asound.conf > /dev/null << EOL
pcm.!default {
    type asym
    capture.pcm "mic"
    playback.pcm "speaker"
}

pcm.mic {
    type plug
    slave {
        pcm "hw:1,0"
        rate ${MEJOR_TASA}
        format ${MEJOR_FORMATO}
    }
}

pcm.speaker {
    type plug
    slave {
        pcm "hw:1,0"
        rate ${MEJOR_TASA}
        format ${MEJOR_FORMATO}
    }
}

# Configuración para limitar el volumen y mejorar la calidad
pcm.softvol {
    type softvol
    slave.pcm "speaker"
    control {
        name "Master"
        card 1
    }
    min_dB -20.0
    max_dB 0.0
}
EOL

exito "Archivo asound.conf optimizado creado correctamente."

# 10. Prueba final con configuración optimizada
info "Realizando prueba final con configuración optimizada..."
info "Para escuchar a un volumen moderado, ejecútalo así después:"
echo "speaker-test -D softvol -l2 -c2 -t wav"

info "Comandos útiles para recordar:"
echo "  - Para ajustar volumen: amixer -c 1 set 'Speaker' 50%"
echo "  - Para grabar audio optimizado: arecord -f ${MEJOR_FORMATO} -r ${MEJOR_TASA} -c1 -d 10 prueba.wav"
echo "  - Para reproducir: aplay -D softvol prueba.wav"
echo "  - Para ajustar configuración completa: alsamixer"

echo -e "${CYAN}"
echo "======================================================"
echo "        DIAGNÓSTICO DE AUDIO COMPLETADO              "
echo "======================================================"
echo -e "${NC}"
echo "Se recomienda reiniciar el sistema para que todos los cambios surtan efecto."
read -p "¿Quieres reiniciar ahora? (si/no): " reiniciar_ahora
if [[ "$reiniciar_ahora" =~ ^[Ss][Ii]?$ ]]; then
    info "Reiniciando sistema..."
    sudo reboot
else
    info "No se reiniciará. Puedes reiniciar manualmente más tarde con el comando 'sudo reboot'."
fi
