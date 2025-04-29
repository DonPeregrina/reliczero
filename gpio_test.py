#!/usr/bin/env python3
import gpiod
import time
from gpiod.line import Direction, Value

CHIP = "/dev/gpiochip0"  # Ruta completa al chip
LINE_OFFSET = 25         # Número de línea que quieres usar (GPIO25)

try:
    # Versión para libgpiod 2.x
    print(f"Intentando acceder a {CHIP}, línea {LINE_OFFSET}...")
    with gpiod.request_lines(
        CHIP,
        consumer="Test gpiod LED",
        config={
            LINE_OFFSET: gpiod.LineSettings(
                direction=Direction.OUTPUT,
                output_value=Value.INACTIVE
            )
        }
    ) as request:
        # Parpadear el LED 5 veces
        for i in range(5):
            request.set_value(LINE_OFFSET, Value.ACTIVE)
            print("LED ON")
            time.sleep(1)
            request.set_value(LINE_OFFSET, Value.INACTIVE)
            print("LED OFF")
            time.sleep(1)
    
    print("¡Prueba completada con éxito! Acceso a GPIO funcionando correctamente.")
except Exception as e:
    print(f"Error al acceder a GPIO: {e}")
    exit(1)
