#!/usr/bin/env python3
import gpiod
import time
from gpiod.line import Direction, Value, Bias, Edge

# Configuración
CHIP = "/dev/gpiochip0"  # Ruta completa al chip
BUTTON_PIN = 23         # Botón en GPIO23
LED_PIN = 25            # LED en GPIO25

try:
    print(f"=== Prueba de Botón GPIO en {CHIP} ===")
    print(f"Botón en pin {BUTTON_PIN}, LED en pin {LED_PIN}")
    print("Presiona el botón para encender el LED")
    print("Presiona Ctrl+C para salir")
    
    # Configurar botón como entrada con pull-up
    button_config = {
        BUTTON_PIN: gpiod.LineSettings(
            direction=Direction.INPUT,
            bias=Bias.PULL_UP,
            edge_detection=Edge.BOTH
        )
    }
    
    # Configurar LED como salida
    led_config = {
        LED_PIN: gpiod.LineSettings(
            direction=Direction.OUTPUT,
            output_value=Value.INACTIVE
        )
    }
    
    # Solicitar líneas
    button_request = gpiod.request_lines(
        CHIP,
        consumer="Button Test",
        config=button_config
    )
    
    led_request = gpiod.request_lines(
        CHIP,
        consumer="LED Test",
        config=led_config
    )
    
    print("\nMonitoreando estado del botón...")
    
    last_state = None
    count = 0
    
    while True:
        # Leer estado del botón
        button_state = button_request.get_value(BUTTON_PIN)
        
        # Detectar cambio de estado
        if button_state != last_state:
            if button_state == Value.INACTIVE:  # Con pull-up, INACTIVE significa presionado
                print("Botón PRESIONADO - Encendiendo LED")
                led_request.set_value(LED_PIN, Value.ACTIVE)  # Encender LED
            else:
                print("Botón LIBERADO - Apagando LED")
                led_request.set_value(LED_PIN, Value.INACTIVE)  # Apagar LED
            
            last_state = button_state
        
        # Mostrar que seguimos vivos
        count += 1
        if count % 10 == 0:
            print(".", end="", flush=True)
        
        # Pequeña pausa
        time.sleep(0.1)

except KeyboardInterrupt:
    print("\nPrueba finalizada por el usuario")
except Exception as e:
    print(f"\nError: {e}")
finally:
    # Limpiar recursos
    if 'led_request' in locals():
        led_request.set_value(LED_PIN, Value.INACTIVE)  # Apagar LED al salir
        led_request.release()
    
    if 'button_request' in locals():
        button_request.release()
    
    print("Recursos GPIO liberados")