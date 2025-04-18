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
