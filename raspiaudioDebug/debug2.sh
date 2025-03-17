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
echo "        REPARACIÓN DE AUDIO PARA RASPIAUDIO MIC+      "
echo "======================================================"
echo -e "${NC}"

# 1. Verificar configuración del GPIO
info "Verificando configuración del módulo GPIO..."
if ! grep -q "dtparam=audio=off" /boot/config.txt; then
    info "Añadiendo dtparam=audio=off a /boot/config.txt"
    echo "dtparam=audio=off" | sudo tee -a /boot/config.txt
    exito "Configuración añadida correctamente."
else
    exito "Configuración GPIO ya está correcta."
fi

# 2. Arreglar asound.conf para usar la tarjeta correcta con configuración más robusta
info "Creando un archivo asound.conf mejorado..."

sudo tee /etc/asound.conf > /dev/null << EOL
pcm.!default {
    type asym
    playback.pcm {
        type plug
        slave.pcm "dmixer"
    }
    capture.pcm {
        type plug
        slave.pcm "mic"
    }
}

pcm.dmixer {
    type dmix
    ipc_key 1024
    slave {
        pcm "hw:0,0"
        period_time 0
        period_size 1024
        buffer_size 8192
        rate 16000
        channels 2
    }
    bindings {
        0 0
        1 1
    }
}

pcm.mic {
    type plug
    slave {
        pcm "hw:0,0"
        rate 16000
        channels 1
    }
}

ctl.!default {
    type hw
    card 0
}
EOL

exito "Archivo asound.conf optimizado creado correctamente."

# 3. Verificar estado de alsa-utils
info "Verificando instalación de alsa-utils..."
if ! dpkg -s alsa-utils &> /dev/null; then
    info "Instalando alsa-utils..."
    sudo apt-get update
    sudo apt-get install -y alsa-utils
    exito "alsa-utils instalado correctamente."
else
    exito "alsa-utils ya está instalado."
fi

# 4. Reiniciar el servicio de sonido
info "Reiniciando el servicio de sonido..."
sudo alsactl kill quit
sudo alsa force-reload
exito "Servicio de sonido reiniciado."

# 5. Tratar de configurar el volumen a un nivel bajo
info "Intentando configurar el volumen a un nivel bajo..."

# Intenta encontrar controles específicos del GoogleVoiceHAT
echo "Buscando controles de volumen disponibles para la tarjeta 0..."
amixer -c 0 scontrols

# Intenta ajustar el volumen de diferentes maneras
amixer -c 0 set 'Speaker' 30% 2>/dev/null || true
amixer -c 0 set 'PCM' 30% 2>/dev/null || true
amixer -c 0 set 'Master' 30% 2>/dev/null || true
amixer -c 0 set 'Playback' 30% 2>/dev/null || true

# 6. Crear un archivo .asoundrc en el directorio home
info "Creando un archivo .asoundrc en tu directorio home para mejor compatibilidad..."

tee ~/.asoundrc > /dev/null << EOL
pcm.!default {
    type asym
    playback.pcm {
        type plug
        slave.pcm "softvol"
    }
    capture.pcm {
        type plug
        slave.pcm "mic"
    }
}

pcm.softvol {
    type softvol
    slave.pcm "dmixer"
    control {
        name "Master"
        card 0
    }
    min_dB -30.0
    max_dB -10.0
}

pcm.dmixer {
    type dmix
    ipc_key 1024
    slave {
        pcm "hw:0,0"
        period_time 0
        period_size 1024
        buffer_size 8192
        rate 16000
        channels 2
    }
}

pcm.mic {
    type plug
    slave {
        pcm "hw:0,0"
        rate 16000
        channels 1
    }
}

ctl.!default {
    type hw
    card 0
}
EOL

exito "Archivo .asoundrc creado correctamente."

# 7. Probar con speaker-test a bajo volumen con la configuración mejorada
info "Probando reproducción de audio con la nueva configuración..."
info "Ejecutando prueba con volumen limitado..."

echo "Prueba 1: tono simple con volumen limitado"
speaker-test -D softvol -c2 -l1 -t sine -f 440

echo "Prueba 2: wav con volumen limitado"
speaker-test -D softvol -c2 -l1 -t wav

echo -e "${CYAN}"
echo "======================================================"
echo "            SOLUCIÓN DE AUDIO COMPLETADA             "
echo "======================================================"
echo -e "${NC}"

info "Recomendaciones:"
echo "1. Si el audio sigue sonando mal, reinicia el sistema con: sudo reboot"
echo "2. Para grabar, usa: arecord -D mic -f S16_LE -r 16000 -c1 -d 10 prueba.wav"
echo "3. Para reproducir con volumen controlado: aplay -D softvol prueba.wav"
echo "4. Si necesitas ajustar aún más, prueba: alsamixer -c 0"

echo -e "${VERDE}Esta solución incluye:"
echo "- Configuración optimizada para evitar distorsión"
echo "- Limitación de volumen para evitar que suene demasiado fuerte"
echo "- Optimización para la tarjeta RaspiAudio MIC+"
echo "- Configuración de tasas de muestreo compatibles"
echo -e "${NC}"

read -p "¿Quieres reiniciar el sistema para aplicar todos los cambios? (si/no): " reiniciar_ahora
if [[ "$reiniciar_ahora" =~ ^[Ss][Ii]?$ ]]; then
    info "Reiniciando sistema..."
    sudo reboot
else
    info "No se reiniciará. Prueba la configuración y reinicia manualmente si es necesario."
fi
