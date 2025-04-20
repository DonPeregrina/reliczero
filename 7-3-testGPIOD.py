#!/usr/bin/env python3
import gpiod
import time

#CHIP = "gpiochip0"    # Nombre del chip que se ve en gpiodetect
CHIP = "/dev/gpiochip0"
LINE_OFFSET = 25      # Número de línea que quieres usar (GPIO25)

# Abrimos el chip
chip = gpiod.Chip(CHIP)

# Obtenemos la línea con ese offset
line = chip.get_line(LINE_OFFSET)

# Solicitamos la línea como salida
line.request(
    consumer="Test gpiod LED",
    type=gpiod.LINE_REQ_DIR_OUT
)

try:
    # Parpadear el LED 5 veces
    for i in range(5):
        line.set_value(1)
        print("LED ON")
        time.sleep(1)
        line.set_value(0)
        print("LED OFF")
        time.sleep(1)
finally:
    # Liberamos la línea y cerramos el chip
    line.release()
    chip.close()

print("¡Fin del ejemplo con libgpiod 1.x!")
