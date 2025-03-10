#!/bin/bash

echo "🎤 Iniciando prueba de micrófono..."

# Instalar dependencias necesarias si no están instaladas
if ! command -v arecord &> /dev/null || ! command -v aplay &> /dev/null; then
    echo "Instalando dependencias necesarias..."
    sudo apt-get update
    sudo apt-get install -y alsa-utils
fi

# Listar dispositivos de audio
echo -e "\n📋 Lista de dispositivos de captura:"
arecord -l

echo -e "\n📋 Lista de tarjetas de sonido:"
cat /proc/asound/cards

# Identificar el dispositivo de captura predeterminado
DEFAULT_DEVICE=$(arecord -L | grep -m1 "plughw")

echo -e "\n🎯 Dispositivo predeterminado detectado: $DEFAULT_DEVICE"

# Definir archivo temporal para la grabación
TEMP_FILE="/tmp/test_recording.wav"

# Función para limpiar al salir
cleanup() {
    echo -e "\n🧹 Limpiando archivos temporales..."
    rm -f $TEMP_FILE
}
trap cleanup EXIT

# Grabar audio
echo -e "\n🔴 Iniciando grabación (duración: 5 segundos)..."
echo "¡Habla algo!"
arecord -D $DEFAULT_DEVICE -f cd -d 5 -t wav $TEMP_FILE

# Verificar si la grabación fue exitosa
if [ $? -eq 0 ]; then
    echo -e "\n✅ Grabación completada"
    
    # Reproducir la grabación
    echo -e "\n🔊 Reproduciendo grabación..."
    aplay $TEMP_FILE
    
    # Verificar si la reproducción fue exitosa
    if [ $? -eq 0 ]; then
        echo -e "\n✨ Prueba completada exitosamente"
    else
        echo -e "\n❌ Error al reproducir el audio"
    fi
else
    echo -e "\n❌ Error al grabar el audio"
fi

# Mostrar información de volumen
echo -e "\n🔊 Niveles de volumen actuales:"
amixer sget Capture

echo -e "\n💡 Si necesitas ajustar el volumen, puedes usar: alsamixer"