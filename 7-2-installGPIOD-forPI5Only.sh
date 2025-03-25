#!/usr/bin/env bash

echo "=== 1) Instalando gpiod y Python-libgpiod con apt-get ==="
sudo apt-get update
sudo apt-get install -y gpiod python3-libgpiod

echo
echo "=== 2) Verificando instalación de gpiod ==="
which gpiodetect >/dev/null 2>&1 && echo "gpiodetect se instaló correctamente." || echo "No se encontró gpiodetect."
which gpioset >/dev/null 2>&1 && echo "gpioset se instaló correctamente." || echo "No se encontró gpioset."

echo
echo "=== 3) Ejemplo rápido con herramientas de línea de comando gpiod ==="
echo "Puedes listar los chips GPIO con:"
echo "    gpiodetect"
echo
echo "Puedes leer el estado de un pin (por ejemplo, el pin 4 del chip0) con:"
echo "    gpioinfo gpiochip0 4"
echo "o"
echo "    gpioget gpiochip0 4"
echo
echo "Para escribir (poner a nivel alto) un pin (por ejemplo, pin 4 del chip0):"
echo "    gpioset gpiochip0 4=1"
echo "Nota: puede que necesites permisos si tu usuario no tiene acceso a /dev/gpiochip*"

echo
echo "=== 4) Ejemplo de script Python usando la librería 'gpiod' ==="
cat << 'EOF'
