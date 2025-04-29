#!/bin/bash

echo "==== Instalador de PyAudio para Raspberry Pi ===="
echo ""
echo "Por favor, selecciona una opción:"
echo "1) Instalar PyAudio con pip (recomendado)"
echo "2) Instalar PyAudio con apt-get"
echo "3) Instalar solo las dependencias"
echo "4) Salir"
echo ""

read -p "Ingresa tu opción (1-4): " opcion

case $opcion in
    1)
        echo "Instalando dependencias y PyAudio con pip..."
        sudo apt-get install -y portaudio19-dev
        pip3 install pyaudio
        echo "Verificando instalación..."
        python3 -c "import pyaudio; print('PyAudio importado correctamente')" || echo "Error al importar PyAudio"
        ;;
    2)
        echo "Instalando PyAudio con apt-get..."
        sudo apt-get install -y python3-pyaudio
        echo "Verificando instalación..."
        python3 -c "import pyaudio; print('PyAudio importado correctamente')" || echo "Error al importar PyAudio"
        ;;
    3)
        echo "Instalando solo las dependencias de PyAudio..."
        sudo apt-get install -y portaudio19-dev
        echo "Dependencias instaladas. Ahora puedes instalar PyAudio manualmente."
        ;;
    4)
        echo "Saliendo..."
        exit 0
        ;;
    *)
        echo "Opción no válida. Saliendo..."
        exit 1
        ;;
esac

echo ""
echo "Proceso completado."
