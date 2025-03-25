#!/usr/bin/env bash

echo "==== Verificando entorno para RPi.GPIO sin sudo ===="
echo "Fecha: $(date)"
echo

echo "== 1) Versión de Python global y en tu venv (si la tienes activada) =="
which python3 || echo "No se encontró python3 en PATH."
python3 --version || echo "No se pudo obtener versión de python3."

echo
echo "== 2) Versión de RPi.GPIO en el sistema (paquete apt) =="
dpkg -l | grep python3-rpi.gpio && echo "Se encontró python3-rpi.gpio instalado por apt." || echo "No está instalado por apt."
echo

echo "== 3) Versión de RPi.GPIO en pip a nivel sistema (fuera del venv) =="
pip3 show RPi.GPIO 2>/dev/null || echo "No se encontró RPi.GPIO a nivel de pip3 sistema."
echo

# Si tu ambiente virtual se llama 'realTTTS', asumiremos que lo puedes activar y revisarlo
# (Si no es exactamente así, ajusta la ruta o la forma de activación del venv)
echo "== 4) Versión de RPi.GPIO en tu ambiente virtual (realTTTS), si existe =="
if [ -f ~/Documents/git/RAGGEMNI/bin/activate ]; then
    source ~/Documents/git/RAGGEMNI/bin/activate
    echo "Ambiente virtual activado: $VIRTUAL_ENV"
    pip show RPi.GPIO 2>/dev/null || echo "No se encontró RPi.GPIO en el venv."
    deactivate
else
    echo "No se encontró el ambiente virtual en ~/Documents/git/RAGGEMNI/bin/activate"
fi
echo

echo "== 5) Comprobando si existe /dev/gpiomem =="
if [ -e /dev/gpiomem ]; then
    echo "/dev/gpiomem existe."
    ls -l /dev/gpiomem
else
    echo "/dev/gpiomem no existe."
fi
echo

echo "== 6) Revisando grupos de tu usuario y existencia del grupo gpio =="
CURRENT_USER=$(id -nu)
echo "Usuario actual: $CURRENT_USER"
echo "Grupos a los que pertenece:"
groups $CURRENT_USER
echo
echo "Contenido de /etc/group (solo líneas con 'gpio'):"
grep gpio /etc/group || echo "No se encontró línea para 'gpio' en /etc/group"
echo

echo "== 7) Intentando importar RPi.GPIO como usuario normal (sin sudo) =="
TEMP_PY=$(mktemp /tmp/tmp_test_gpio_import.XXXX.py)
cat << EOF > $TEMP_PY
import RPi.GPIO
print("RPi.GPIO importado con éxito. Versión:", RPi.GPIO.VERSION)
EOF
python3 $TEMP_PY || echo "Error al importar RPi.GPIO"
rm -f $TEMP_PY

echo
echo "== 8) Consejos para la instalación/actualización de RPi.GPIO =="
echo "- Si necesitas instalar o actualizar la librería a nivel sistema (con apt):"
echo "    sudo apt-get update && sudo apt-get install python3-rpi.gpio"
echo
echo "- Si quieres actualizar vía pip, por ejemplo a la última versión disponible en PyPI:"
echo "    sudo pip3 install --upgrade RPi.GPIO"
echo "  (Aunque usar 'sudo' con pip no siempre es la práctica recomendada, a veces se hace en entornos sin apt-get o con un Python custom.)"
echo
echo "- Si prefieres mantenerlo en tu virtualenv (por ejemplo 'realTTTS'), lo activas y luego:"
echo "    pip install --upgrade RPi.GPIO"
echo
echo "== Fin del script de verificación =="
