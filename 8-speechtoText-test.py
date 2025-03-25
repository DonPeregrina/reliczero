#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Script de prueba para la funcionalidad de reconocimiento de voz (speech-to-text)
Graba audio y lo convierte a texto utilizando la biblioteca SpeechRecognition.
"""

import os
import time
import speech_recognition as sr
import subprocess

def record_audio_with_arecord(duration=5, output_path="/tmp/test_recording.wav"):
    """Graba audio utilizando arecord."""
    print(f"Grabando audio durante {duration} segundos...")
    try:
        # Usar arecord para grabar audio
        cmd = f"arecord -D pulse -f cd -d {duration} -V mono {output_path}"
        subprocess.run(cmd, shell=True, check=True)
        print(f"Audio grabado y guardado en {output_path}")
        return output_path
    except subprocess.SubprocessError as e:
        print(f"Error al grabar audio: {e}")
        return None

def speech_to_text(audio_path):
    """Convierte un archivo de audio a texto."""
    print("Convirtiendo audio a texto...")
    
    recognizer = sr.Recognizer()
    try:
        with sr.AudioFile(audio_path) as source:
            # Ajustar para ruido ambiental (opcional)
            print("Ajustando para ruido ambiental...")
            recognizer.adjust_for_ambient_noise(source)
            
            # Obtener los datos de audio
            print("Procesando audio...")
            audio_data = recognizer.record(source)
            
            # Intentar reconocimiento con Google Speech Recognition
            print("Enviando a Google Speech Recognition...")
            text = recognizer.recognize_google(audio_data, language="es-ES")
            return text
    except sr.UnknownValueError:
        print("Google Speech Recognition no pudo entender el audio")
        return None
    except sr.RequestError as e:
        print(f"Error en la solicitud a Google Speech Recognition: {e}")
        return None
    except Exception as e:
        print(f"Error inesperado: {e}")
        return None

def main():
    try:
        print("==== Prueba de reconocimiento de voz ====")
        print("Este script grabará audio y lo convertirá a texto.")
        
        while True:
            input("Presiona Enter para comenzar a grabar (5 segundos)...")
            
            # Grabar audio
            audio_path = record_audio_with_arecord()
            
            if audio_path and os.path.exists(audio_path):
                # Convertir a texto
                text = speech_to_text(audio_path)
                
                # Mostrar resultado
                if text:
                    print(f"\nTexto reconocido: '{text}'")
                else:
                    print("\nNo se pudo reconocer ningún texto.")
            else:
                print("No se pudo grabar el audio o el archivo no existe.")
            
            # Preguntar si se desea continuar
            cont = input("\n¿Deseas probar de nuevo? (s/n): ")
            if cont.lower() != 's':
                break
        
    except KeyboardInterrupt:
        print("\nPrueba interrumpida por el usuario.")
    except Exception as e:
        print(f"Error: {e}")
    finally:
        print("Prueba finalizada.")

if __name__ == "__main__":
    main()
