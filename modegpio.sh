#!/usr/bin/env bash

echo "=== Chequeando módulo gpiomem ==="
lsmod | grep gpiomem &>/dev/null
if [ $? -eq 0 ]; then
  echo "El módulo gpiomem ya está cargado."
else
  echo "No se encontró el módulo gpiomem, intentando cargarlo..."
  # Para RPi 3/4 normalmente es 'bcm2835-gpiomem':
  sudo modprobe bcm2835-gpiomem 2>/dev/null

  if [ -e /dev/gpiomem ]; then
    echo "¡Se creó /dev/gpiomem!"
  else
    echo "No se pudo crear /dev/gpiomem. Tal vez en Pi 5 el módulo se llame diferente o no esté disponible."
  fi
fi
