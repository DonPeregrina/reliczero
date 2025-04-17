#!/bin/bash

# Script para grabar audio con RaspiAudio MIC+
# Uso: ./grabar_audio.sh [duración_en_segundos] [nombre_archivo.wav]

# Colores para los mensajes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Valores predeterminados
DURACION=10
ARCHIVO="grabacion_pulse_$(date +%Y%m%d_%H%M%S).wav"
DIRECTORIO="$HOME/grabaciones"

# Verificar si se proporcionó un argumento para la duración
if [ ! -z "$1" ]; then
    # Verificar que el argumento sea un número
    if [[ "$1" =~ ^[0-9]+$ ]]; then
        DURACION=$1
    else
        echo -e "${RED}Error:${NC} La duración debe ser un número entero."
        echo "Uso: $0 [duración_en_segundos] [nombre_archivo.wav]"
        exit 1
    fi
fi

# Verificar si se proporcionó un nombre de archivo
if [ ! -z "$2" ]; then
    ARCHIVO=$2
    # Agregar extensión .wav si no la tiene
    if [[ ! "$ARCHIVO" =~ \.wav$ ]]; then
        ARCHIVO="${ARCHIVO}.wav"
    fi
fi

# Crear directorio de grabaciones si no existe
if [ ! -d "$DIRECTORIO" ]; then
    mkdir -p "$DIRECTORIO"
    echo -e "${YELLOW}Información:${NC} Se ha creado el directorio $DIRECTORIO"
fi

# Ruta completa del archivo a grabar
RUTA_COMPLETA="$DIRECTORIO/$ARCHIVO"

# Mostrar información de la grabación
echo -e "${YELLOW}Iniciando grabación de audio${NC}"
echo -e "Duración: ${DURACION} segundos"
echo -e "Archivo: ${RUTA_COMPLETA}"
echo -e "Formato: CD quality (16-bit, 44.1kHz), mono"
echo -e "Presiona Ctrl+C para cancelar"
echo

# Iniciar cuenta regresiva
echo -e "${YELLOW}La grabación comenzará en:${NC}"
for i in {3..1}
do
   echo -e "$i..."
   sleep 1
done
echo -e "${GREEN}¡Grabando!${NC}"

# Ejecutar el comando de grabación
arecord -D pulse -f cd -d $DURACION -V mono "$RUTA_COMPLETA"

# Verificar si la grabación fue exitosa
if [ $? -eq 0 ]; then
    echo -e "\n${GREEN}Grabación completada exitosamente.${NC}"
    echo -e "El audio ha sido guardado en: ${RUTA_COMPLETA}"
    
    # Preguntar si desea reproducir la grabación
    echo -e "\n${YELLOW}¿Desea reproducir la grabación? (s/n)${NC}"
    read -n 1 -r RESPUESTA
    echo
    if [[ $RESPUESTA =~ ^[Ss]$ ]]; then
        echo -e "${YELLOW}Reproduciendo grabación...${NC}"
        aplay "$RUTA_COMPLETA"
    fi
else
    echo -e "\n${RED}Error durante la grabación.${NC}"
fi

exit 0
