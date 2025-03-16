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

# Función para mensajes de error
error() {
    echo -e "${ROJO}[ERROR]${NC} $1"
    exit 1
}

# Función para pausas con mensaje
pausa() {
    echo -e "${MAGENTA}[PAUSA]${NC} $1"
    sleep 2
}

# Función para comprobar si un comando se ejecutó correctamente
comprobar_comando() {
    if [ $? -eq 0 ]; then
        exito "$1"
    else
        error "$2"
    fi
}

# Banner de inicio
echo -e "${CYAN}"
echo "======================================================"
echo "      INSTALACIÓN Y CONFIGURACIÓN DE RASPIAUDIO      "
echo "======================================================"
echo -e "${NC}"

# Comprobar si se está ejecutando como root
if [ "$(id -u)" -ne 0 ]; then
    error "Este script debe ejecutarse como root (usa sudo)."
fi


# Instalar dependencias necesarias
info "Instalando dependencias necesarias..."
apt-get install -y build-essential wget ffmpeg
comprobar_comando "Dependencias instaladas correctamente." "No se pudieron instalar las dependencias."

# Instalar WiringPi (necesario para RaspiAudio)
info "Verificando si WiringPi está instalado..."
if command -v gpio >/dev/null 2>&1; then
    exito "WiringPi ya está instalado."
    gpio -v
else
    info "Instalando WiringPi desde GitHub..."
    cd /tmp
    git clone https://github.com/WiringPi/WiringPi.git
    comprobar_comando "Repositorio WiringPi clonado correctamente." "No se pudo clonar el repositorio WiringPi."
    
    cd WiringPi
    ./build
    comprobar_comando "WiringPi compilado e instalado correctamente." "No se pudo compilar WiringPi."
    
    # Verificar la instalación
    gpio -v
    comprobar_comando "WiringPi instalado y funcionando correctamente." "No se pudo verificar la instalación de WiringPi."
fi

# Instalar RaspiAudio
info "Instalando RaspiAudio MIC+..."
pausa "A continuación se instalará el módulo RaspiAudio MIC+"
wget -O - mic.raspiaudio.com | bash
comprobar_comando "RaspiAudio MIC+ instalado correctamente." "No se pudo instalar RaspiAudio MIC+."

# Ejecutar prueba de RaspiAudio
info "Ejecutando prueba de RaspiAudio..."
pausa "A continuación se ejecutará la prueba de RaspiAudio"
wget -O - test.raspiaudio.com | bash
comprobar_comando "Prueba de RaspiAudio ejecutada correctamente." "No se pudo ejecutar la prueba de RaspiAudio."

# Instalar pydub si se está usando Python
if [ -n "$VIRTUAL_ENV" ]; then
    info "Ambiente virtual de Python detectado: $VIRTUAL_ENV"
    info "Instalando pydub dentro del ambiente virtual..."
    pip install pydub
    comprobar_comando "pydub instalado correctamente en el ambiente virtual." "No se pudo instalar pydub."
else
    info "Instalando pydub globalmente..."
    pip3 install pydub
    comprobar_comando "pydub instalado correctamente." "No se pudo instalar pydub."
fi

# Ajustar volumen al 50%
info "Ajustando volumen al 50%..."
amixer set Master 50%
comprobar_comando "Volumen ajustado al 50%." "No se pudo ajustar el volumen."

# Prueba de reproducción de audio
info "Ahora vamos a probar la reproducción de audio..."
pausa "Se reproducirá un tono de prueba. Por favor, escucha atentamente."

# Generar un tono de prueba
speaker-test -t sine -f 440 -c 2 -s 2
comprobar_comando "Tono de prueba reproducido." "No se pudo reproducir el tono de prueba."

# Preguntar al usuario si pudo escuchar el sonido
echo -e "${CYAN}"
echo "======================================================"
echo "        ¿Pudiste escuchar el tono de prueba?         "
echo "======================================================"
echo -e "${NC}"
read -p "Responde 'si' o 'no': " respuesta

if [[ "$respuesta" =~ ^[Ss][Ii]?$ ]]; then
    exito "¡Excelente! La reproducción de audio funciona correctamente."
else
    advertencia "No se pudo escuchar el audio. Verificaremos la configuración..."
    # Mostrar información de dispositivos de audio
    aplay -l
    pausa "Estos son tus dispositivos de audio. Revisa la configuración si es necesario."
fi

# Prueba de grabación de audio
info "Ahora vamos a probar la grabación de audio..."
pausa "Se grabará durante 5 segundos. Por favor, habla cerca del micrófono."

# Grabar audio de prueba
arecord -d 5 --format=S16_LE --rate=44100 -c1 /tmp/test_grabacion.wav
comprobar_comando "Audio grabado correctamente." "No se pudo grabar audio."

# Reproducir la grabación
info "Reproduciendo la grabación..."
pausa "A continuación escucharás lo que se grabó:"
aplay /tmp/test_grabacion.wav
comprobar_comando "Audio reproducido correctamente." "No se pudo reproducir el audio grabado."

# Preguntar al usuario si pudo escuchar la grabación
echo -e "${CYAN}"
echo "======================================================"
echo "       ¿Pudiste escuchar tu voz en la grabación?     "
echo "======================================================"
echo -e "${NC}"
read -p "Responde 'si' o 'no': " respuesta_grabacion

if [[ "$respuesta_grabacion" =~ ^[Ss][Ii]?$ ]]; then
    exito "¡Perfecto! La grabación de audio funciona correctamente."
else
    advertencia "No se pudo escuchar la grabación. Verificaremos la configuración del micrófono..."
    # Mostrar configuración del micrófono
    amixer get Mic
    pausa "Esta es la configuración de tu micrófono. Puede que necesites ajustar los niveles."
fi

# Resumen final
echo -e "${CYAN}"
echo "======================================================"
echo "      INSTALACIÓN DE RASPIAUDIO MIC+ COMPLETADA      "
echo "======================================================"
echo -e "${NC}"

info "Comandos útiles para recordar:"
echo "  - Para grabar audio: arecord -d [segundos] --format=S16_LE --rate=44100 -c1 [archivo.wav]"
echo "  - Para reproducir audio: aplay [archivo.wav]"
echo "  - Para ajustar volumen: amixer set Master [porcentaje]%"
echo "  - Para configurar dispositivos de audio: alsamixer"

exito "¡La instalación y configuración de RaspiAudio MIC+ se ha completado!"
echo ""
echo -e "${VERDE}Para hacer ejecutable este script, usa: chmod +x 3-raspiaudio.sh${NC}"
echo -e "${VERDE}Para ejecutarlo, usa: sudo ./3-raspiaudio.sh${NC}"
