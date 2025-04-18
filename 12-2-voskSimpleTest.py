#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script simplificado para probar Vosk por sí solo
Graba audio y lo reconoce usando Vosk
"""

import os
import sys
import json
import wave
import subprocess
import time

# Ruta al modelo de Vosk
MODEL_PATH = os.path.join(os.getcwd(), "vosk-model-small-es-0.42")
AUDIO_FILE = "/tmp/recording.wav"

def record_audio():
    """Graba audio hasta que se presione Ctrl+C"""
    print("Iniciando grabación... Habla y presiona Ctrl+C cuando termines.")
    
    try:
        # Comando para grabar audio
        cmd = f"arecord --format=S16_LE --rate=16000 -c1 {AUDIO_FILE}"
        process = subprocess.Popen(cmd.split())
        
        # Esperar hasta que el usuario presione Ctrl+C
        try:
            process.wait()
        except KeyboardInterrupt:
            process.terminate()
            process.wait()
            print("\nGrabación detenida.")
        
        return AUDIO_FILE if os.path.exists(AUDIO_FILE) else None
    except Exception as e:
        print(f"Error al grabar audio: {e}")
        return None

def recognize_speech(audio_file):
    """Reconoce el habla en el archivo de audio usando Vosk"""
    print(f"Procesando audio con Vosk...")
    
    try:
        from vosk import Model, KaldiRecognizer
        
        # Cargar el modelo
        print(f"Cargando modelo desde {MODEL_PATH}")
        model = Model(MODEL_PATH)
        
        # Abrir el archivo de audio
        wf = wave.open(audio_file, "rb")
        
        # Verificar formato del audio
        if wf.getnchannels() != 1 or wf.getsampwidth() != 2 or wf.getcomptype() != "NONE":
            print("El formato de audio no es compatible")
            return None
        
        # Crear reconocedor
        recognizer = KaldiRecognizer(model, wf.getframerate())
        recognizer.SetWords(True)
        
        # Procesar el audio
        results = []
        
        # Medir tiempo de procesamiento
        start_time = time.time()
        
        # Procesar todo el archivo
        while True:
            data = wf.readframes(4000)
            if len(data) == 0:
                break
            
            if recognizer.AcceptWaveform(data):
                result = json.loads(recognizer.Result())
                if "text" in result and result["text"].strip():
                    results.append(result["text"])
        
        # Obtener el resultado final
        final_result = json.loads(recognizer.FinalResult())
        if "text" in final_result and final_result["text"].strip():
            results.append(final_result["text"])
        
        # Calcular tiempo total
        elapsed_time = time.time() - start_time
        
        # Unir todos los resultados
        full_text = " ".join(results)
        
        print(f"Reconocimiento completado en {elapsed_time:.2f} segundos")
        return full_text
    
    except Exception as e:
        print(f"Error en el reconocimiento: {e}")
        return None

def main():
    print("=== Test Simple de Vosk ===")
    
    # Verificar si el modelo existe
    if not os.path.exists(MODEL_PATH):
        print(f"Error: El modelo no existe en {MODEL_PATH}")
        print("Ejecuta primero el script completo para descargar el modelo")
        return
    
    # Grabar audio
    audio_file = record_audio()
    if not audio_file:
        print("No se pudo grabar audio")
        return
    
    # Reconocer texto
    text = recognize_speech(audio_file)
    
    if text:
        print("\n=== Resultado ===")
        print(f"Texto reconocido: \"{text}\"")
    else:
        print("No se pudo reconocer ningún texto")

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\nPrograma interrumpido")
        sys.exit(0)