#!/usr/bin/env python3
"""
Script de prueba para gpiozero
Utiliza un botón en el pin BCM 23 y un LED en el pin BCM 25
No debería requerir privilegios sudo si los permisos están configurados correctamente
"""

from gpiozero import Button, LED
import time
import signal
import sys

# Configurar el botón (pin BCM 23) y LED (pin BCM 25)
button = Button(23)  # Pull-up está habilitado por defecto
led = LED(25)

# Función para manejar la salida limpia
def signal_handler(sig, frame):
    led.off()  # Asegurarse de que el LED esté apagado al salir
    print("\nPrueba finalizada.")
    sys.exit(0)

# Registrar el handler para Ctrl+C
signal.signal(signal.SIGINT, signal_handler)

def main():
    # Contador de pulsaciones
    presses = 0
    
    print("Prueba de gpiozero iniciada. Presiona el botón (pin BCM 23) para encender el LED.")
    print("Presiona Ctrl+C para finalizar la prueba.")
    
    # Configurar callbacks
    def button_pressed():
        nonlocal presses
        presses += 1
        print(f"¡Botón presionado! Pulsación #{presses} detectada")
        led.on()
    
    def button_released():
        print("Botón liberado")
        led.off()
    
    # Asignar callbacks
    button.when_pressed = button_pressed
    button.when_released = button_released
    
    # Mantener el programa en ejecución
    while True:
        time.sleep(0.1)

if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        print(f"Error: {e}")
    finally:
        led.off()  # Asegurarse de que el LED esté apagado al salir
