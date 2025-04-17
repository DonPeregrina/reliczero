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
