#!/bin/bash

# Colores para mejor visualización
VERDE='\033[0;32m'
AMARILLO='\033[1;33m'
ROJO='\033[0;31m'
AZUL='\033[0;34m'
NC='\033[0m' # No Color

# Función para mostrar mensajes
mostrar_mensaje() {
    echo -e "${VERDE}[INFO]${NC} $1"
}

# Función para mostrar errores
mostrar_error() {
    echo -e "${ROJO}[ERROR]${NC} $1"
}

# Función para mostrar advertencias
mostrar_advertencia() {
    echo -e "${AMARILLO}[ADVERTENCIA]${NC} $1"
}

# Función para comprobar si estamos en un entorno virtual
comprobar_virtualenv() {
    if [ -z "$VIRTUAL_ENV" ]; then
        mostrar_advertencia "No parece que estés en un entorno virtual. Se recomienda usar un entorno virtual para la instalación."
        read -p "¿Quieres continuar de todos modos? (s/n): " respuesta
        if [[ $respuesta != "s" && $respuesta != "S" ]]; then
            exit 1
        fi
    else
        mostrar_mensaje "Entorno virtual detectado: $VIRTUAL_ENV"
    fi
}

# Función para instalar Vosk
instalar_vosk() {
    mostrar_mensaje "Instalando Vosk y dependencias..."
    pip install vosk
    
    # Comprobar si se instaló correctamente
    if pip show vosk > /dev/null; then
        mostrar_mensaje "Vosk instalado correctamente."
    else
        mostrar_error "Error al instalar Vosk."
        exit 1
    fi
    
    # Instalar dependencias adicionales para procesamiento de audio
    mostrar_mensaje "Instalando dependencias adicionales..."
    pip install sounddevice numpy
    
    mostrar_mensaje "Instalando FFmpeg (necesario para algunos formatos de audio)..."
    if command -v apt-get > /dev/null; then
        sudo apt-get update
        sudo apt-get install -y ffmpeg
    elif command -v yum > /dev/null; then
        sudo yum install -y ffmpeg
    elif command -v brew > /dev/null; then
        brew install ffmpeg
    else
        mostrar_advertencia "No se pudo instalar FFmpeg automáticamente. Por favor, instálalo manualmente según tu sistema operativo."
    fi
}

# Función para descargar el modelo en español
descargar_modelo_espanol() {
    MODELO_DIR="modelo_vosk_es"
    
    # Comprobar si el directorio ya existe
    if [ -d "$MODELO_DIR" ]; then
        mostrar_advertencia "El directorio $MODELO_DIR ya existe."
        read -p "¿Quieres descargar el modelo de nuevo? (s/n): " respuesta
        if [[ $respuesta != "s" && $respuesta != "S" ]]; then
            return
        fi
        rm -rf "$MODELO_DIR"
    fi
    
    mostrar_mensaje "Descargando el modelo de español (es)..."
    
    # Modelo español pequeño (elija el tamaño adecuado según sus necesidades)
    MODELO_URL="https://alphacephei.com/vosk/models/vosk-model-small-es-0.42.zip"
    
    # Descargar el modelo
    if command -v wget > /dev/null; then
        wget "$MODELO_URL" -O modelo_es.zip
    elif command -v curl > /dev/null; then
        curl -L "$MODELO_URL" -o modelo_es.zip
    else
        mostrar_error "Se necesita wget o curl para descargar el modelo."
        exit 1
    fi
    
    # Crear directorio para el modelo
    mkdir -p "$MODELO_DIR"
    
    # Descomprimir el modelo
    mostrar_mensaje "Descomprimiendo el modelo..."
    if command -v unzip > /dev/null; then
        unzip modelo_es.zip -d "$MODELO_DIR"
        # Mover contenido (generalmente el archivo está dentro de una carpeta)
        mv "$MODELO_DIR"/*/* "$MODELO_DIR" 2>/dev/null
    else
        mostrar_error "Se necesita unzip para descomprimir el modelo."
        exit 1
    fi
    
    # Limpiar
    rm modelo_es.zip
    
    mostrar_mensaje "Modelo en español descargado y descomprimido en $MODELO_DIR"
}

# Función para crear un script de prueba
crear_script_prueba() {
    mostrar_mensaje "Creando script de prueba para reconocimiento de voz..."
    
    cat > test_vosk.py << 'EOF'
#!/usr/bin/env python3

import os
import sys
import json
import wave
import pyaudio
from vosk import Model, KaldiRecognizer

# Verificar si se proporciona la ruta del modelo
if len(sys.argv) > 1:
    model_path = sys.argv[1]
else:
    model_path = "modelo_vosk_es"  # Ruta predeterminada

# Verificar si existe el modelo
if not os.path.exists(model_path):
    print(f"Error: El modelo en {model_path} no existe.")
    print("Ejecute primero la opción de descargar el modelo o especifique la ruta correcta.")
    sys.exit(1)

# Cargar modelo
print(f"Cargando modelo desde {model_path}...")
model = Model(model_path)
print("Modelo cargado.")

# Configuración de audio
FRAME_RATE = 16000
CHUNK_SIZE = 8000

# Inicializar reconocedor
rec = KaldiRecognizer(model, FRAME_RATE)

# Inicializar PyAudio
p = pyaudio.PyAudio()
stream = p.open(format=pyaudio.paInt16, channels=1, rate=FRAME_RATE, input=True, frames_per_buffer=CHUNK_SIZE)

print("Escuchando... (Habla en español, presiona Ctrl+C para salir)")

try:
    while True:
        data = stream.read(CHUNK_SIZE)
        if len(data) == 0:
            break
            
        if rec.AcceptWaveform(data):
            result = json.loads(rec.Result())
            if result['text']:
                print(f"Reconocido: {result['text']}")
        else:
            partial = json.loads(rec.PartialResult())
            if partial['partial']:
                print(f"Parcial: {partial['partial']}", end='\r')
except KeyboardInterrupt:
    print("\nSaliendo...")
finally:
    stream.stop_stream()
    stream.close()
    p.terminate()
    print("Reconocimiento de voz finalizado.")
EOF
    
    chmod +x test_vosk.py
    mostrar_mensaje "Script de prueba creado: test_vosk.py"
}

# Función para ejecutar la prueba
ejecutar_prueba() {
    # Verificar si existe el script de prueba
    if [ ! -f "test_vosk.py" ]; then
        mostrar_error "No se encuentra el script de prueba. Ejecútalo primero la opción 3."
        return
    fi
    
    # Verificar si el modelo existe
    MODELO_DIR="modelo_vosk_es"
    if [ ! -d "$MODELO_DIR" ]; then
        mostrar_error "No se encuentra el modelo en español. Ejecuta primero la opción 2."
        return
    fi
    
    mostrar_mensaje "Ejecutando prueba de reconocimiento de voz..."
    python test_vosk.py "$MODELO_DIR"
}

# Función para procesar un archivo de audio
procesar_archivo_audio() {
    mostrar_mensaje "Creando script para procesar un archivo de audio..."
    
    cat > procesar_audio.py << 'EOF'
#!/usr/bin/env python3

import sys
import json
import wave
import os
from vosk import Model, KaldiRecognizer

if len(sys.argv) < 2:
    print("Uso: python procesar_audio.py [archivo_audio.wav] [ruta_modelo]")
    sys.exit(1)

# Ruta del archivo de audio
archivo_audio = sys.argv[1]

# Verificar si existe el archivo
if not os.path.exists(archivo_audio):
    print(f"Error: El archivo {archivo_audio} no existe.")
    sys.exit(1)

# Verificar formato
if not archivo_audio.lower().endswith('.wav'):
    print("Error: Solo se admiten archivos WAV.")
    print("Consejo: Puedes convertir otros formatos a WAV con ffmpeg:")
    print("  ffmpeg -i tu_archivo.mp3 -ar 16000 -ac 1 salida.wav")
    sys.exit(1)

# Ruta del modelo
if len(sys.argv) > 2:
    model_path = sys.argv[2]
else:
    model_path = "modelo_vosk_es"  # Ruta predeterminada

# Verificar si existe el modelo
if not os.path.exists(model_path):
    print(f"Error: El modelo en {model_path} no existe.")
    sys.exit(1)

# Cargar modelo
print(f"Cargando modelo desde {model_path}...")
model = Model(model_path)
print("Modelo cargado.")

# Abrir el archivo de audio
wf = wave.open(archivo_audio, "rb")

# Verificar formato
if wf.getnchannels() != 1:
    print("Error: El archivo de audio debe ser mono (1 canal).")
    sys.exit(1)

sample_rate = wf.getframerate()
print(f"Frecuencia de muestreo: {sample_rate} Hz")

# Inicializar reconocedor
rec = KaldiRecognizer(model, sample_rate)
rec.SetWords(True)

# Procesar el archivo
print(f"Procesando {archivo_audio}...")
resultados = []

while True:
    data = wf.readframes(4000)
    if len(data) == 0:
        break
    
    if rec.AcceptWaveform(data):
        resultado = json.loads(rec.Result())
        if resultado['text']:
            resultados.append(resultado['text'])
            print(f"Segmento: {resultado['text']}")

# Obtener cualquier resultado final
resultado_final = json.loads(rec.FinalResult())
if resultado_final['text']:
    resultados.append(resultado_final['text'])
    print(f"Segmento final: {resultado_final['text']}")

# Guardar resultado completo en un archivo
nombre_salida = os.path.splitext(os.path.basename(archivo_audio))[0] + "_transcripcion.txt"
with open(nombre_salida, "w", encoding="utf-8") as f:
    for i, texto in enumerate(resultados):
        f.write(f"{texto}\n")

print(f"\nTranscripción completa guardada en {nombre_salida}")
EOF
    
    chmod +x procesar_audio.py
    mostrar_mensaje "Script para procesar archivos de audio creado: procesar_audio.py"
    mostrar_mensaje "Uso: python procesar_audio.py archivo.wav [ruta_modelo]"
    mostrar_mensaje "Nota: El archivo debe estar en formato WAV mono con frecuencia adecuada."
    mostrar_mensaje "Para convertir otros formatos, usa FFmpeg: ffmpeg -i entrada.mp3 -ar 16000 -ac 1 salida.wav"
}

# Menú principal
mostrar_menu() {
    echo -e "${AZUL}============================================${NC}"
    echo -e "${AZUL}  INSTALADOR DE VOSK PARA SPEECH-TO-TEXT   ${NC}"
    echo -e "${AZUL}============================================${NC}"
    echo "1. Instalar Vosk y dependencias"
    echo "2. Descargar modelo de español"
    echo "3. Crear script de prueba"
    echo "4. Ejecutar prueba de reconocimiento de voz (micrófono)"
    echo "5. Crear script para procesar archivos de audio"
    echo "0. Salir"
    echo -e "${AZUL}============================================${NC}"
    read -p "Seleccione una opción: " opcion
    return $opcion
}

# Comprobar entorno virtual
comprobar_virtualenv

# Loop principal
while true; do
    mostrar_menu
    opcion=$?
    
    case $opcion in
        1)
            instalar_vosk
            read -p "Presiona Enter para continuar..."
            ;;
        2)
            descargar_modelo_espanol
            read -p "Presiona Enter para continuar..."
            ;;
        3)
            crear_script_prueba
            read -p "Presiona Enter para continuar..."
            ;;
        4)
            ejecutar_prueba
            read -p "Presiona Enter para continuar..."
            ;;
        5)
            procesar_archivo_audio
            read -p "Presiona Enter para continuar..."
            ;;
        0)
            mostrar_mensaje "¡Gracias por usar el instalador de Vosk!"
            exit 0
            ;;
        *)
            mostrar_error "Opción inválida. Intenta de nuevo."
            read -p "Presiona Enter para continuar..."
            ;;
    esac
done