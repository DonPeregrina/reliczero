#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Script mejorado de prueba de GPIO con gpiozero
- Se ejecuta por un tiempo limitado
- Limpia adecuadamente los recursos al terminar
- Usa atexit para garantizar la limpieza en caso de error
"""

from gpiozero import Button, LED
import time
import signal
import sys
import atexit

# Configuración de pines
BUTTON_PIN = 23  # BCM 23
LED_PIN = 25     # BCM 25

# Tiempo máximo de ejecución en segundos
MAX_RUNTIME = 30

# Variables globales para los dispositivos
button = None
led = None

def cleanup():
    """Función de limpieza que se ejecutará al salir."""
    print("\nLimpiando recursos...")
    # gpiozero maneja la limpieza automáticamente,
    # pero podemos asegurarnos cerrando explícitamente los dispositivos
    global button, led
    if led is not None:
        led.off()  # Asegurar que el LED esté apagado
        led.close()
    if button is not None:
        button.close()
    print("Limpieza completada.")

# Registrar la función de limpieza para que se ejecute al salir
atexit.register(cleanup)

def signal_handler(sig, frame):
    """Manejador para señales de interrupción."""
    print("\nSeñal de interrupción recibida. Terminando programa...")
    # La limpieza se realizará automáticamente gracias a atexit
    sys.exit(0)

# Registrar manejador de señales
signal.signal(signal.SIGINT, signal_handler)
signal.signal(signal.SIGTERM, signal_handler)

def main():
    global button, led
    
    print("Prueba mejorada de GPIO con gpiozero")
    print(f"Esta prueba se ejecutará por {MAX_RUNTIME} segundos como máximo.")
    print("Presiona Ctrl+C para terminar antes.\n")
    
    # Inicializar dispositivos con manejo de excepciones
    try:
        print(f"Inicializando Button en pin {BUTTON_PIN}...")
        button = Button(BUTTON_PIN)
        
        print(f"Inicializando LED en pin {LED_PIN}...")
        led = LED(LED_PIN)
        
        # Contador de pulsaciones
        count = 0
        
        # Definir callbacks
        def button_pressed():
            nonlocal count
            count += 1
            print(f"¡Botón presionado! Pulsación #{count}")
            led.on()
        
        def button_released():
            print("Botón liberado")
            led.off()
        
        # Asignar callbacks
        button.when_pressed = button_pressed
        button.when_released = button_released
        
        print("\nTodo configurado. Presiona el botón para probar...")
        
        # Tiempo de inicio
        start_time = time.time()
        
        # Ejecutar hasta alcanzar el tiempo máximo
        while (time.time() - start_time) < MAX_RUNTIME:
            time.sleep(0.1)
            # Mostrar tiempo restante cada 5 segundos
            elapsed = time.time() - start_time
            if elapsed % 5 < 0.1:
                remaining = MAX_RUNTIME - elapsed
                print(f"Tiempo restante: {remaining:.1f} segundos")
        
        print(f"\nTiempo máximo de {MAX_RUNTIME} segundos alcanzado.")
        print(f"Se detectaron {count} pulsaciones del botón.")
            
    except Exception as e:
        print(f"Error: {e}")
        # La limpieza se realizará automáticamente gracias a atexit

if __name__ == "__main__":
    main()
    # Mensaje final
    print("Prueba finalizada correctamente.")
