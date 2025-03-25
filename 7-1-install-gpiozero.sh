#!/bin/bash
# Script para instalar y probar gpiozero sin sudo

echo "==== Instalación y prueba de gpiozero ===="
echo "Este script instalará gpiozero y probará el botón y LED sin sudo."

# Instalar gpiozero si no está presente
if ! python3 -c "import gpiozero" 2>/dev/null; then
    echo "Instalando gpiozero..."
    pip3 install gpiozero
else
    echo "gpiozero ya está instalado."
fi

# Instalar RPi.GPIO como backend (necesario para gpiozero)
if ! python3 -c "import RPi.GPIO" 2>/dev/null; then
    echo "Instalando RPi.GPIO..."
    pip3 install RPi.GPIO
else
    echo "RPi.GPIO ya está instalado."
fi

# Intentar dar permisos al dispositivo GPIO sin necesidad de sudo
echo "Configurando permisos para acceder a GPIO sin sudo..."
if [ -e /dev/gpiomem ]; then
    echo "Dando permisos de acceso a /dev/gpiomem..."
    sudo chmod a+rw /dev/gpiomem
else
    echo "¡Advertencia! No se encontró /dev/gpiomem. Es posible que este no sea un sistema Raspberry Pi."
fi

# Crear un script Python para probar gpiozero
echo "Creando script de prueba con gpiozero..."
cat > test_gpiozero.py << 'EOF'
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
EOF

chmod +x test_gpiozero.py

echo "Intentando ejecutar la prueba SIN sudo..."
echo "Si ves errores de permiso, es posible que necesites cerrar sesión y volver a iniciarla,"
echo "o reiniciar la Raspberry Pi para que los cambios de permisos surtan efecto."

python3 test_gpiozero.py
