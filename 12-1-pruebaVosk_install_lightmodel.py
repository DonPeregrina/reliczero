#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Test de reconocimiento de voz con Vosk en Raspberry Pi
Este script graba audio del micrófono y lo convierte a texto localmente usando Vosk
"""

import os
import sys
import json
import wave
import subprocess
import time
import signal
import logging

# Configurar logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S',
)
logger = logging.getLogger(__name__)

# Ruta para el modelo - CORREGIDO
MODEL_PATH = os.path.join(os.getcwd(), "vosk-model-small-es-0.42")
AUDIO_FILE = "/tmp/recording.wav"

# Duración de la grabación en segundos (0 para grabar hasta detener manualmente)
RECORD_DURATION = 0

def check_and_install_vosk():
    """Verifica si Vosk está instalado y lo instala si es necesario"""
    try:
        import vosk
        logger.info("Vosk ya está instalado")
        return True
    except ImportError:
        logger.info("Instalando Vosk...")
        try:
            subprocess.check_call([sys.executable, "-m", "pip", "install", "vosk"])
            logger.info("Vosk instalado correctamente")
            return True
        except Exception as e:
            logger.error(f"Error al instalar Vosk: {e}")
            return False

def download_model():
    """Descarga un modelo de Vosk si no existe localmente"""
    if os.path.exists(MODEL_PATH) and os.path.isdir(MODEL_PATH):
        logger.info(f"Modelo ya existe en {MODEL_PATH}")
        return True
    
    logger.info("Descargando modelo de español pequeño de Vosk...")
    try:
        # Descargar modelo pequeño en español (85MB)
        subprocess.check_call([
            "wget", 
            "https://alphacephei.com/vosk/models/vosk-model-small-es-0.42.zip", 
            "-O", "model.zip"
        ])
        
        # Descomprimir el modelo
        logger.info("Descomprimiendo modelo...")
        subprocess.check_call(["unzip", "model.zip", "-d", "."])
        
        # Verificar que el directorio existe
        if os.path.exists(MODEL_PATH) and os.path.isdir(MODEL_PATH):
            logger.info(f"Modelo extraído correctamente en {MODEL_PATH}")
            
            # Eliminar el zip
            os.remove("model.zip")
            return True
        else:
            logger.error(f"El directorio del modelo no existe después de la extracción: {MODEL_PATH}")
            return False
    except Exception as e:
        logger.error(f"Error al descargar el modelo: {e}")
        return False

def record_audio(duration=0):
    """Graba audio del micrófono.
    
    Args:
        duration: Duración en segundos (0 para grabar hasta Ctrl+C)
    
    Returns:
        Ruta al archivo de audio grabado o None si hay error
    """
    logger.info(f"Iniciando grabación de audio {'hasta Ctrl+C' if duration == 0 else f'por {duration} segundos'}...")
    
    try:
        if duration > 0:
            # Grabar por duración específica
            cmd = f"arecord --format=S16_LE --rate=16000 -c1 --duration={duration} {AUDIO_FILE}"
            subprocess.call(cmd.split())
        else:
            # Grabar hasta que se detenga manualmente
            cmd = f"arecord --format=S16_LE --rate=16000 -c1 {AUDIO_FILE}"
            process = subprocess.Popen(cmd.split())
            
            print("Grabando... Presiona Ctrl+C para detener.")
            try:
                process.wait()
            except KeyboardInterrupt:
                process.terminate()
                process.wait()
                print("\nGrabación detenida.")
        
        if os.path.exists(AUDIO_FILE) and os.path.getsize(AUDIO_FILE) > 0:
            logger.info(f"Audio grabado en {AUDIO_FILE}")
            return AUDIO_FILE
        else:
            logger.error("Archivo de audio no creado o vacío")
            return None
    except Exception as e:
        logger.error(f"Error al grabar audio: {e}")
        return None

def recognize_with_vosk(audio_file):
    """Reconoce texto desde un archivo de audio usando Vosk"""
    logger.info(f"Procesando audio con Vosk: {audio_file}")
    
    try:
        from vosk import Model, KaldiRecognizer
        
        # Verificar que el modelo existe
        if not os.path.exists(MODEL_PATH) or not os.path.isdir(MODEL_PATH):
            logger.error(f"El directorio del modelo no existe: {MODEL_PATH}")
            # Listar el directorio actual para depuración
            logger.info(f"Contenido del directorio actual: {os.listdir(os.getcwd())}")
            return None
        
        # Listar contenido del directorio del modelo para depuración
        logger.info(f"Contenido del directorio del modelo: {os.listdir(MODEL_PATH)}")
        
        # Cargar el modelo
        logger.info(f"Cargando modelo desde {MODEL_PATH}")
        model = Model(MODEL_PATH)
        
        # Abrir el archivo de audio
        wf = wave.open(audio_file, "rb")
        
        # Verificar formato (debe ser mono 16kHz 16-bit para Vosk)
        if wf.getnchannels() != 1 or wf.getsampwidth() != 2 or wf.getcomptype() != "NONE":
            logger.error("El formato de audio no es compatible con Vosk")
            logger.info(f"Canales: {wf.getnchannels()}, Ancho: {wf.getsampwidth()}, Compresión: {wf.getcomptype()}")
            return None
        
        # Crear reconocedor
        recognizer = KaldiRecognizer(model, wf.getframerate())
        recognizer.SetWords(True)  # Para obtener marcas de tiempo por palabra
        
        # Procesar el audio en fragmentos
        results = []
        chunk_size = 4000  # Tamaño del fragmento en bytes
        
        logger.info("Reconociendo audio...")
        start_time = time.time()
        
        data = wf.readframes(chunk_size)
        while len(data) > 0:
            if recognizer.AcceptWaveform(data):
                result = json.loads(recognizer.Result())
                if "text" in result and result["text"].strip():
                    results.append(result["text"])
            data = wf.readframes(chunk_size)
        
        # Obtener resultado final
        final_result = json.loads(recognizer.FinalResult())
        if "text" in final_result and final_result["text"].strip():
            results.append(final_result["text"])
        
        end_time = time.time()
        
        # Unir todos los resultados
        full_text = " ".join(results)
        
        logger.info(f"Reconocimiento completado en {end_time - start_time:.2f} segundos")
        logger.info(f"Texto reconocido: '{full_text}'")
        
        return full_text
    except Exception as e:
        logger.error(f"Error en el reconocimiento con Vosk: {e}")
        return None

def main():
    """Función principal"""
    print("=== Test de Reconocimiento de Voz con Vosk en Raspberry Pi ===")
    
    # Verificar que Vosk está instalado
    if not check_and_install_vosk():
        print("No se pudo instalar Vosk. Saliendo.")
        return
    
    # Descargar modelo si es necesario
    if not download_model():
        print("No se pudo descargar el modelo. Saliendo.")
        return
    
    print(f"Usando modelo en: {MODEL_PATH}")
    
    # Grabar audio
    print("\nVamos a grabar audio. Habla algo cuando estés listo.")
    audio_file = record_audio(RECORD_DURATION)
    
    if not audio_file:
        print("No se pudo grabar audio. Saliendo.")
        return
    
    # Reconocer texto
    print("\nProcesando audio con Vosk...")
    text = recognize_with_vosk(audio_file)
    
    if text:
        print("\n=== Resultado ===")
        print(f"Texto reconocido: {text}")
    else:
        print("No se pudo reconocer ningún texto.")

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\nPrograma interrumpido por el usuario.")
        sys.exit(0)