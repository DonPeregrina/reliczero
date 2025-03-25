#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Script de prueba para la síntesis de voz con Eleven Labs v1.54.0
Convierte texto a voz usando la API de Eleven Labs y reproduce el audio.
"""

import os
import io
import soundfile as sf
import sounddevice as sd
from elevenlabs import ElevenLabs
from dotenv import load_dotenv

# Cargar variables de entorno desde el archivo .env
load_dotenv()

# Obtener la API key de Eleven Labs desde las variables de entorno
ELEVENLABS_API_KEY = os.getenv('ELEVENLABS_API_KEY')

if not ELEVENLABS_API_KEY:
    raise ValueError("No se encontró la API key de Eleven Labs. Por favor, configúrala en el archivo .env")

class ElevenSpeech:
    def __init__(self):
        # Inicializar el cliente de Eleven Labs
        self.client = ElevenLabs(api_key=ELEVENLABS_API_KEY)
        
    def gen_dub(self, text):
        try:
            print("Generando audio...")
            
            if not text.strip():
                print("Error: El texto está vacío")
                return
            
            # Generar audio con Eleven Labs
            # Usamos un generador para obtener el audio en chunks
            audio_stream = self.client.generate(
                text=text,
                voice="Rachel",
                model="eleven_multilingual_v2"
            )
            
            # Convertir el generador a bytes
            audio_bytes = b"".join(chunk for chunk in audio_stream)
            
            # Convertir bytes a un formato reproducible
            audio_io = io.BytesIO(audio_bytes)
            data, samplerate = sf.read(audio_io)
            
            # Reproducir el audio
            print("Reproduciendo audio...")
            sd.play(data, samplerate)
            sd.wait()
            
            print("Audio reproducido exitosamente")
            
        except Exception as e:
            print(f"Error generando/reproduciendo audio: {e}")
            import traceback
            traceback.print_exc()

def main():
    try:
        print("==== Prueba de síntesis de voz con Eleven Labs ====")
        print("Este script convertirá texto a voz y reproducirá el audio.")
        
        # Crear instancia de ElevenSpeech
        speech = ElevenSpeech()
        
        while True:
            # Solicitar texto para convertir a voz
            text = input("\nIngresa el texto a convertir a voz (o 'salir' para terminar): ")
            
            if text.lower() == 'salir':
                break
            
            # Generar y reproducir audio
            speech.gen_dub(text)
            
    except KeyboardInterrupt:
        print("\nPrueba interrumpida por el usuario.")
    except Exception as e:
        print(f"Error: {e}")
        import traceback
        traceback.print_exc()
    finally:
        print("Prueba finalizada.")

if __name__ == "__main__":
    main()
