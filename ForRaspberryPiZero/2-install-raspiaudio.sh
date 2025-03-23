#!/bin/bash

# Script de instalación y configuración de RaspiAudio MIC+ para Raspberry Pi Zero
# Autor: Claude
# Fecha: 20 de marzo de 2025

# Colores para la salida
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Función para mostrar mensajes de estado
function show_status() {
    echo -e "${YELLOW}[INFO]${NC} $1"
}

# Función para mostrar mensajes de éxito
function show_success() {
    echo -e "${GREEN}[ÉXITO]${NC} $1"
}

# Función para mostrar mensajes de error
function show_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Función para verificar si el comando se ejecutó correctamente
function check_status() {
    if [ $? -eq 0 ]; then
        show_success "$1"
    else
        show_error "$2"
        exit 1
    fi
}

# Comprobar si se está ejecutando como root
if [ "$(id -u)" != "0" ]; then
   show_error "Este script debe ejecutarse como root (sudo)."
   exit 1
fi

# Inicio de la instalación
show_status "Iniciando la instalación de RaspiAudio MIC+ para Raspberry Pi Zero..."
show_status "Actualizando listas de paquetes..."
apt-get update
check_status "Lista de paquetes actualizada." "Error al actualizar la lista de paquetes."

# Instalación del driver de RaspiAudio MIC+
show_status "Instalando el driver principal de RaspiAudio MIC+..."
wget -O - mic.raspiaudio.com | bash
check_status "Driver principal instalado correctamente." "Error al instalar el driver principal."

# Instalación de las utilidades de prueba
show_status "Instalando utilidades de prueba de RaspiAudio..."
wget -O - test.raspiaudio.com | bash
check_status "Utilidades de prueba instaladas correctamente." "Error al instalar las utilidades de prueba."

# Configuración para la grabación de audio
show_status "Configurando parámetros optimizados para grabación de audio..."

# Crear archivo de configuración ALSA para RaspiAudio si no existe
if [ ! -f /etc/asound.conf ]; then
    cat > /etc/asound.conf << EOL
pcm.!default {
  type asym
  capture.pcm "mic"
  playback.pcm "speaker"
}

pcm.mic {
  type plug
  slave {
    pcm "hw:1,0"
  }
}

pcm.speaker {
  type plug
  slave {
    pcm "hw:0,0"
  }
}
EOL
    check_status "Archivo de configuración ALSA creado." "Error al crear el archivo de configuración ALSA."
fi

# Crear directorio para pruebas de audio
mkdir -p /home/pi/audio_tests
check_status "Directorio para pruebas de audio creado." "Error al crear directorio para pruebas."

# Crear script para probar la grabación
cat > /home/pi/audio_tests/test_recording.sh << EOL
#!/bin/bash
echo "Grabando audio de prueba (4 segundos)..."
arecord -d 4 --format=S16_LE --rate=44100 -c1 /home/pi/audio_tests/test.wav
echo "Reproduciendo grabación..."
aplay /home/pi/audio_tests/test.wav
echo "Archivo guardado en /home/pi/audio_tests/test.wav"
EOL

# Hacer ejecutable el script de prueba
chmod +x /home/pi/audio_tests/test_recording.sh
check_status "Script de prueba de grabación creado." "Error al crear script de prueba."

# Crear script para ajustar volumen del micrófono
cat > /home/pi/audio_tests/adjust_mic.sh << EOL
#!/bin/bash
echo "Abriendo control de volumen del micrófono..."
alsamixer -c 1
EOL

# Hacer ejecutable el script de ajuste de volumen
chmod +x /home/pi/audio_tests/adjust_mic.sh
check_status "Script para ajustar volumen del micrófono creado." "Error al crear script de ajuste de volumen."

# Cambiar propietario de los archivos creados al usuario pi
chown -R pi:pi /home/pi/audio_tests
check_status "Permisos de archivos ajustados." "Error al ajustar permisos."

# Reiniciar servicios de audio
show_status "Reiniciando servicios de audio..."
systemctl restart alsa-restore.service
check_status "Servicios de audio reiniciados." "Error al reiniciar servicios de audio."

# Mostrar instrucciones finales
echo ""
echo "=========================================="
echo "  INSTALACIÓN COMPLETADA CORRECTAMENTE"
echo "=========================================="
echo ""
echo "Para probar la grabación, ejecute:"
echo "  cd /home/pi/audio_tests"
echo "  ./test_recording.sh"
echo ""
echo "Para ajustar el volumen del micrófono, ejecute:"
echo "  cd /home/pi/audio_tests"
echo "  ./adjust_mic.sh"
echo ""
echo "Comando para grabar audio manualmente:"
echo "  arecord -d [segundos] --format=S16_LE --rate=44100 -c1 [archivo].wav"
echo ""
echo "Ejemplo: arecord -d 10 --format=S16_LE --rate=44100 -c1 grabacion.wav"
echo "=========================================="

exit 0
