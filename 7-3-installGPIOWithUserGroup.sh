#!/bin/bash
#
# Script para configurar permisos GPIO en Raspberry Pi 5
# Este script:
# 1. Verifica si el usuario actual está en el grupo GPIO
# 2. Añade el usuario al grupo si es necesario
# 3. Ejecuta una prueba para verificar el acceso GPIO
#

# Colores para mensajes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para imprimir mensajes informativos
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Función para imprimir mensajes de éxito
print_success() {
    echo -e "${GREEN}[ÉXITO]${NC} $1"
}

# Función para imprimir mensajes de advertencia
print_warning() {
    echo -e "${YELLOW}[ADVERTENCIA]${NC} $1"
}

# Función para imprimir mensajes de error
print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Función para crear archivo de prueba GPIO
create_gpio_test_file() {
    cat > gpio_test.py << 'EOF'
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
EOF

    chmod +x gpio_test.py
    print_info "Archivo de prueba GPIO creado: gpio_test.py"
}

echo "===== Configuración de Permisos GPIO para Raspberry Pi ====="
echo ""

# Paso 1: Verificar si el usuario está en el grupo GPIO
if groups | grep -q "\bgpio\b"; then
    print_success "El usuario $(whoami) ya pertenece al grupo GPIO."
    USER_IN_GPIO=true
else
    print_warning "El usuario $(whoami) NO pertenece al grupo GPIO."
    USER_IN_GPIO=false
fi

# Paso 2: Verificar si el dispositivo GPIO existe
if [ -e /dev/gpiochip0 ]; then
    print_success "Dispositivo GPIO detectado: /dev/gpiochip0"
else
    print_error "No se detectó el dispositivo GPIO. Verifica la instalación de tu Raspberry Pi."
    exit 1
fi

# Paso 3: Añadir usuario al grupo GPIO si es necesario
if [ "$USER_IN_GPIO" = false ]; then
    print_info "Añadiendo el usuario $(whoami) al grupo GPIO..."
    
    if sudo usermod -a -G gpio $USER; then
        print_success "Usuario añadido al grupo GPIO correctamente."
        print_warning "IMPORTANTE: Debes cerrar sesión y volver a iniciarla para que los cambios surtan efecto."
        print_warning "Por favor, cierra completamente la sesión (no solo la terminal) y vuelve a iniciar sesión."
        
        read -p "¿Has cerrado sesión y vuelto a iniciarla? (s/n): " answer
        if [[ $answer != "s" && $answer != "S" ]]; then
            print_warning "Por favor, cierra sesión y vuelve a iniciarla antes de continuar con la prueba."
            echo "Ejecuta este script nuevamente después de reiniciar sesión."
            exit 0
        fi
    else
        print_error "Error al añadir usuario al grupo GPIO. Asegúrate de tener permisos de administrador."
        exit 1
    fi
fi

# Paso 4: Verificar que Python y gpiod están instalados
print_info "Verificando instalación de Python y gpiod..."

if ! command -v python3 &> /dev/null; then
    print_error "Python 3 no está instalado. Por favor, instálalo primero."
    exit 1
fi

# Verificar si gpiod está instalado
if ! python3 -c "import gpiod" 2> /dev/null; then
    print_warning "Módulo Python gpiod no encontrado. Intentando instalar..."
    
    if sudo apt-get update && sudo apt-get install -y python3-libgpiod gpiod; then
        print_success "Instalación de gpiod completada."
    else
        print_error "Error al instalar gpiod. Intenta instalarlo manualmente."
        exit 1
    fi
fi

# Paso 5: Crear archivo de prueba
print_info "Creando archivo de prueba para libgpiod 2.x..."
create_gpio_test_file

# Paso 6: Ejecutar prueba
print_info "Ejecutando prueba de acceso a GPIO..."
echo "-------------------------------------------"
python3 ./gpio_test.py
result=$?
echo "-------------------------------------------"

if [ $result -eq 0 ]; then
    print_success "Prueba completada correctamente. El acceso a GPIO está configurado y funcionando."
    echo ""
    print_info "Puedes usar la API de libgpiod 2.x en tus proyectos ahora."
else
    print_error "La prueba falló. Revisa los errores anteriores."
    echo ""
    print_info "Asegúrate de que:"
    echo "  1. Tu usuario pertenece al grupo GPIO (verifica con el comando 'groups')"
    echo "  2. Has cerrado sesión y vuelto a iniciarla después de añadir el usuario al grupo"
    echo "  3. Los pines GPIO que intentas usar no están siendo utilizados por otro proceso"
    echo "  4. Tu hardware está correctamente conectado"
fi

echo ""
echo "===== Configuración finalizada ====="