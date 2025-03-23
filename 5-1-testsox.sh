#!/bin/bash
# Script de prueba con Sox corregido

# Primero instalamos los paquetes necesarios para MP3
sudo apt-get install -y libsox-fmt-mp3

echo "=== 1. Grabación básica (10 segundos) ==="
rec grabacion_basica.wav trim 0 10

echo "=== 2. Verificar que el archivo se creó correctamente ==="
ls -lh grabacion_basica.wav

echo "=== 3. Reproducir la grabación ==="
play grabacion_basica.wav

echo "=== 4. Grabación con estadísticas ==="
rec grabacion_stats.wav trim 0 10 stats

echo "=== 5. Amplificar el volumen ==="
sox grabacion_basica.wav grabacion_amplificada.wav gain 6

echo "=== 6. Crear un perfil de ruido (grabar 3 segundos de silencio) ==="
echo "*** Por favor guarde silencio por 3 segundos ***"
rec -n ruido.wav trim 0 3

echo "=== 7. Grabar y aplicar reducción de ruido ==="
rec grabacion_con_ruido.wav trim 0 10
sox grabacion_con_ruido.wav grabacion_sin_ruido.wav noisered ruido.wav 0.21

echo "=== 8. Convertir a MP3 (con el paquete instalado) ==="
sox grabacion_basica.wav grabacion_basica.mp3

echo "=== 9. Verificar todos los archivos creados ==="
ls -lh grabacion_*.wav grabacion_*.mp3
