#!/usr/bin/env bash

echo "=== Añadiendo overlay 'gpio-mem' a /boot/config.txt (si no existe) ==="
OVERLAY="dtoverlay=gpio-mem"

if grep -q "$OVERLAY" /boot/config.txt; then
  echo "Ya existe la línea '$OVERLAY' en /boot/config.txt"
else
  echo "Agregando '$OVERLAY' en /boot/config.txt ..."
  echo "$OVERLAY" | sudo tee -a /boot/config.txt
  echo "Overlay agregado. Reinicia la Raspberry Pi para que surta efecto."
fi
