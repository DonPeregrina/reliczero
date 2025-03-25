#!/bin/bash
# Script para probar la detección del botón en Raspberry Pi
# Este script verifica la correcta configuración y detección del botón GPIO

echo "==== Prueba de detección de botón GPIO ===="
echo "Este script verificará si el botón conectado al pin BCM 23 está funcionando correctamente."

# Comprobar si estamos en una Raspberry Pi
if [ ! -f /proc/device-tree/model ] || ! grep -q "Raspberry Pi" /proc/device-tree/model; then
    echo "ERROR: Este script debe ejecutarse en una Raspberry Pi."
    exit 1
fi

# Verificar si el usuario tiene permisos para acceder a GPIO
if [ "$(id -u)" != "0" ]; then
    echo "ADVERTENCIA: Este script podría requerir privilegios de superusuario para acceder a GPIO."
    echo "Intentando continuar, pero si hay errores, ejecuta con 'sudo'."
fi

# Instalar dependencias si es necesario
echo -e "\nVerificando e instalando dependencias necesarias..."
if ! python3 -c "import RPi.GPIO" 2>/dev/null; then
    echo "Instalando RPi.GPIO..."
    pip3 install RPi.GPIO
fi

# Crear script Python temporal para la prueba
echo -e "\nCreando script de prueba..."
cat > /tmp/test_button.py << 'EOF'
#!/usr/bin/env python3
import RPi.GPIO as GPIO
import time
import signal
import sys

# Pin del botón (BCM 23 - pin 16)
BUTTON_PIN = 23
LED_PIN = 25  # BCM 25 (pin 22) - Opcional, si tienes un LED conectado

def signal_handler(sig, frame):
    GPIO.cleanup()
    print("\nPrueba finalizada.")
    sys.exit(0)

signal.signal(signal.SIGINT, signal_handler)

def setup():
    # Configurar GPIO
    GPIO.setmode(GPIO.BCM)
    GPIO.setup(BUTTON_PIN, GPIO.IN, pull_up_down=GPIO.PUD_UP)
    
    # Configurar LED si está conectado (opcional)
    try:
        GPIO.setup(LED_PIN, GPIO.OUT)
        GPIO.output(LED_PIN, GPIO.LOW)
        led_available = True
    except:
        led_available = False
    
    return led_available

def main():
    led_available = setup()
    
    print("\nPrueba de botón iniciada. Presiona el botón (pin BCM 23) para ver la detección.")
    print("Presiona Ctrl+C para finalizar la prueba.")
    
    # Contador de pulsaciones detectadas
    count = 0
    
    try:
        # Estado anterior del botón
        previous_state = GPIO.input(BUTTON_PIN)
        
        while True:
            # Leer estado actual
            current_state = GPIO.input(BUTTON_PIN)
            
            # Detectar cambio de HIGH a LOW (botón presionado)
            if previous_state == GPIO.HIGH and current_state == GPIO.LOW:
                count += 1
                print(f"¡Botón presionado! Pulsación #{count} detectada")
                
                # Encender LED si está disponible
                if led_available:
                    GPIO.output(LED_PIN, GPIO.HIGH)
            
            # Detectar cambio de LOW a HIGH (botón liberado)
            elif previous_state == GPIO.LOW and current_state == GPIO.HIGH:
                print("Botón liberado")
                
                # Apagar LED si está disponible
                if led_available:
                    GPIO.output(LED_PIN, GPIO.LOW)
            
            # Actualizar estado anterior
            previous_state = current_state
            
            # Pequeña pausa para evitar uso excesivo de CPU
            time.sleep(0.01)
            
    except KeyboardInterrupt:
        pass
    finally:
        GPIO.cleanup()
        print("\nPrueba finalizada.")

if __name__ == "__main__":
    main()
EOF

# Hacer ejecutable el script temporal
chmod +x /tmp/test_button.py

# Ejecutar la prueba
echo -e "\nEjecutando prueba de botón..."
python3 /tmp/test_button.py

# Limpiar después de la prueba
rm /tmp/test_button.py

echo "Prueba finalizada"
echo "Si el botón funciona correctamente, deberías haber visto mensajes de detección al presionarlo."
echo "Si no se detectó ninguna pulsación, verifica las conexiones y los números de pin."
