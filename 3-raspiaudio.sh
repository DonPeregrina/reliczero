#!/bin/bash

# Colores para mejor visualización
ROJO='\033[0;31m'
VERDE='\033[0;32m'
AMARILLO='\033[0;33m'
AZUL='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # Sin Color

# Función para mensajes informativos
info() {
    echo -e "${AZUL}[INFO]${NC} $1"
}

# Función para mensajes de éxito
exito() {
    echo -e "${VERDE}[ÉXITO]${NC} $1"
}

# Función para mensajes de advertencia
advertencia() {
    echo -e "${AMARILLO}[ADVERTENCIA]${NC} $1"
}

# Función para mensajes de error
error() {
    echo -e "${ROJO}[ERROR]${NC} $1"
    exit 1
}

# Función para pausas con mensaje
pausa() {
    echo -e "${MAGENTA}[PAUSA]${NC} $1"
    sleep 2
}

# Función para comprobar si un comando se ejecutó correctamente
comprobar_comando() {
    if [ $? -eq 0 ]; then
        exito "$1"
    else
        error "$2"
    fi
}

# Banner de inicio
echo -e "${CYAN}"
echo "======================================================"
echo "      INSTALACIÓN Y CONFIGURACIÓN DE RASPIAUDIO      "
echo "======================================================"
echo -e "${NC}"

# Comprobar si se está ejecutando como root
if [ "$(id -u)" -ne 0 ]; then
    error "Este script debe ejecutarse como root (usa sudo)."
fi

# Menú para elegir punto de inicio
echo -e "${CYAN}Selecciona el punto de inicio de la instalación:${NC}"
echo "1. Instalación completa (actualizar sistema, instalar WiringPi, etc.)"
echo "2. Solo instalar RaspiAudio MIC+ (si ya tienes WiringPi)"
echo "3. Solo configurar y probar audio (si ya instalaste RaspiAudio)"
read -p "Selecciona una opción (1/2/3): " punto_inicio

# Función de instalación completa
instalacion_completa() {
    # Actualizar repositorios
    info "Actualizando repositorios..."
    apt-get update -y
    comprobar_comando "Repositorios actualizados correctamente." "No se pudieron actualizar los repositorios."

    # Instalar dependencias necesarias
    info "Instalando dependencias necesarias..."
    apt-get install -y git build-essential wget ffmpeg
    comprobar_comando "Dependencias instaladas correctamente." "No se pudieron instalar las dependencias."

    # Instalar WiringPi (necesario para RaspiAudio)
    info "Verificando si WiringPi está instalado..."
    if command -v gpio >/dev/null 2>&1; then
        exito "WiringPi ya está instalado."
        gpio -v
    else
        info "Instalando WiringPi desde GitHub..."
        cd /tmp
        git clone https://github.com/WiringPi/WiringPi.git
        comprobar_comando "Repositorio WiringPi clonado correctamente." "No se pudo clonar el repositorio WiringPi."
        
        cd WiringPi
        ./build
        comprobar_comando "WiringPi compilado e instalado correctamente." "No se pudo compilar WiringPi."
        
        # Verificar la instalación
        gpio -v
        comprobar_comando "WiringPi instalado y funcionando correctamente." "No se pudo verificar la instalación de WiringPi."
    fi
    
    # Continuar con la instalación de RaspiAudio
    instalar_raspiaudio
}

# Función para instalar solo RaspiAudio
instalar_raspiaudio() {
    # Instalar RaspiAudio manualmente
    info "Instalando RaspiAudio MIC+ manualmente..."

    # Asegurarse de que ALSA está instalado
    info "Verificando si ALSA está instalado..."
    apt-get install -y alsa-utils
    comprobar_comando "ALSA instalado correctamente." "No se pudo instalar ALSA."

    # Modificar los archivos de configuración para RaspiAudio MIC+
    info "Configurando archivos para RaspiAudio MIC+..."

    # Agregar dtoverlay a config.txt si no existe
    if grep -q "dtoverlay=googlevoicehat-soundcard" /boot/config.txt; then
        exito "dtoverlay ya está configurado en config.txt"
    else
        echo "dtoverlay=googlevoicehat-soundcard" >> /boot/config.txt
        comprobar_comando "dtoverlay agregado a config.txt" "No se pudo agregar dtoverlay a config.txt"
    fi

    # Configurar archivo asound.conf
    cat > /etc/asound.conf << EOL
pcm.!default {
  type asym
  capture.pcm "mic"
  playback.pcm "speaker"
}
pcm.mic {
  type plug
  slave {
    pcm "hw:1,0"
  }
}
pcm.speaker {
  type plug
  slave {
    pcm "hw:1,0"
  }
}
EOL
    comprobar_comando "Archivo asound.conf configurado correctamente." "No se pudo configurar asound.conf"

    # Instalar pydub si se está usando Python
    if [ -n "$VIRTUAL_ENV" ]; then
        info "Ambiente virtual de Python detectado: $VIRTUAL_ENV"
        info "Instalando pydub dentro del ambiente virtual..."
        pip install pydub
        comprobar_comando "pydub instalado correctamente en el ambiente virtual." "No se pudo instalar pydub."
    else
        info "Instalando pydub..."
        # Intentar instalar con apt primero (método recomendado)
        info "Intentando instalar pydub con apt..."
        apt-get install -y python3-pydub || true
        
        # Si el usuario está en un entorno virtual, intentamos eso
        if [ -d "$HOME/.virtualenvs" ] || [ -d "$HOME/venv" ] || [ -d "$HOME/.venv" ]; then
            info "Se detectaron entornos virtuales. Por favor, activa tu entorno virtual e instala pydub manualmente:"
            echo "  source /ruta/a/tu/venv/bin/activate"
            echo "  pip install pydub"
            advertencia "No se instaló pydub automáticamente. Deberás instalarlo manualmente en tu entorno virtual."
        else
            info "Para instalar pydub, se recomienda crear un entorno virtual:"
            echo "  sudo apt-get install -y python3-venv"
            echo "  python3 -m venv ~/venv"
            echo "  source ~/venv/bin/activate"
            echo "  pip install pydub"
            advertencia "No se instaló pydub automáticamente. Deberás instalarlo en un entorno virtual."
        fi
        
        # Preguntar si quiere continuar sin pydub
        read -p "¿Quieres continuar con la instalación sin pydub? (si/no): " continuar_sin_pydub
        if [[ "$continuar_sin_pydub" =~ ^[Ss][Ii]?$ ]]; then
            advertencia "Continuando sin pydub. Algunas funcionalidades pueden no estar disponibles."
        else
            error "Instalación cancelada. Instala pydub manualmente e intenta nuevamente."
        fi
    fi

    info "Es necesario reiniciar para que los cambios surtan efecto."
    pausa "¿Quieres continuar con las pruebas o prefieres reiniciar ahora?"
    read -p "Escribe 'continuar' para seguir con las pruebas o cualquier otra cosa para terminar: " continuar_reiniciar

    if [[ "$continuar_reiniciar" != "continuar" ]]; then
        info "Se recomienda reiniciar antes de probar el micrófono."
        read -p "¿Quieres reiniciar ahora? (si/no): " reiniciar_ahora
        if [[ "$reiniciar_ahora" =~ ^[Ss][Ii]?$ ]]; then
            info "Reiniciando sistema..."
            reboot
        else
            info "No se reiniciará. Puedes reiniciar manualmente más tarde con el comando 'sudo reboot'."
        fi
        exit 0
    else
        # Continuar con las pruebas de audio
        probar_audio
    fi
}

# Función para detectar y configurar la tarjeta de sonido
detectar_tarjeta_sonido() {
    info "Detectando tarjeta de sonido RaspiAudio MIC+..."
    
    # Mostrar todas las tarjetas de sonido disponibles
    echo "Tarjetas de sonido disponibles:"
    aplay -l
    
    # Verificar si se ha cargado el módulo de la tarjeta
    if lsmod | grep -q "googlevoicehat"; then
        exito "Módulo googlevoicehat cargado correctamente."
    else
        advertencia "El módulo googlevoicehat no está cargado."
        info "Intentando cargar el módulo..."
        modprobe googlevoicehat-soundcard || true
        
        # Verificar de nuevo
        if lsmod | grep -q "googlevoicehat"; then
            exito "Módulo googlevoicehat cargado correctamente."
        else
            advertencia "No se pudo cargar el módulo. Es posible que necesites reiniciar."
            info "Verificando configuración en /boot/config.txt..."
            if grep -q "dtoverlay=googlevoicehat-soundcard" /boot/config.txt; then
                info "La configuración en /boot/config.txt parece correcta."
                advertencia "Se requiere un reinicio para aplicar los cambios."
                read -p "¿Quieres reiniciar ahora? (si/no): " reiniciar_ahora
                if [[ "$reiniciar_ahora" =~ ^[Ss][Ii]?$ ]]; then
                    info "Reiniciando sistema..."
                    reboot
                else
                    advertencia "El sistema no se reiniciará. Las pruebas de audio pueden fallar."
                fi
            else
                info "Agregando dtoverlay=googlevoicehat-soundcard a /boot/config.txt..."
                echo "dtoverlay=googlevoicehat-soundcard" >> /boot/config.txt
                advertencia "Se requiere un reinicio para aplicar los cambios."
                read -p "¿Quieres reiniciar ahora? (si/no): " reiniciar_ahora
                if [[ "$reiniciar_ahora" =~ ^[Ss][Ii]?$ ]]; then
                    info "Reiniciando sistema..."
                    reboot
                else
                    advertencia "El sistema no se reiniciará. Las pruebas de audio pueden fallar."
                fi
            fi
        fi
    fi
    
    # Identificar el número de la tarjeta y dispositivo
    info "Identificando tarjeta RaspiAudio..."
    tarjeta_id=$(aplay -l | grep -i "googlevoicehat\|voicehat" | head -n 1 | awk -F': ' '{print $1}' | awk '{print $2}')
    dispositivo_id="0"  # Generalmente es 0 para RaspiAudio MIC+
    
    if [ -n "$tarjeta_id" ]; then
        exito "Tarjeta RaspiAudio MIC+ identificada como: tarjeta $tarjeta_id, dispositivo $dispositivo_id"
        # Actualizar asound.conf con los valores correctos
        cat > /etc/asound.conf << EOL
pcm.!default {
  type asym
  capture.pcm "mic"
  playback.pcm "speaker"
}
pcm.mic {
  type plug
  slave {
    pcm "hw:$tarjeta_id,$dispositivo_id"
  }
}
pcm.speaker {
  type plug
  slave {
    pcm "hw:$tarjeta_id,$dispositivo_id"
  }
}
EOL
        exito "Archivo asound.conf actualizado con la configuración correcta."
    else
        advertencia "No se pudo identificar la tarjeta RaspiAudio MIC+."
        info "Intentando con configuración predeterminada..."
    fi
}

# Función para probar el audio
probar_audio() {
    # Primero detectar y configurar la tarjeta de sonido
    detectar_tarjeta_sonido
    
    # Ajustar volumen al 50%
    info "Ajustando volumen al 50%..."
    
    # Intentar diferentes controles de volumen hasta encontrar uno que funcione
    if amixer set Master 50% 2>/dev/null; then
        exito "Volumen Master ajustado al 50%."
    elif amixer set PCM 50% 2>/dev/null; then
        exito "Volumen PCM ajustado al 50%."
    elif amixer set Speaker 50% 2>/dev/null; then
        exito "Volumen Speaker ajustado al 50%."
    else
        # Buscar controles disponibles
        info "Buscando controles de volumen disponibles..."
        controles=$(amixer scontrols | grep -i "playback\|capture\|pcm\|spk\|mic\|vol")
        
        if [ -n "$controles" ]; then
            echo "Controles disponibles:"
            echo "$controles"
            
            # Intentar con el primer control de playback
            primer_control=$(echo "$controles" | grep -i "playback" | head -n 1 | cut -d"'" -f2)
            if [ -n "$primer_control" ]; then
                info "Intentando con control: $primer_control"
                amixer set "$primer_control" 50%
                exito "Volumen ajustado al 50% usando $primer_control."
            else
                advertencia "No se pudo ajustar el volumen automáticamente."
                info "Puedes ajustar el volumen manualmente ejecutando 'alsamixer'."
            fi
        else
            advertencia "No se encontraron controles de volumen."
            info "Puedes ajustar el volumen manualmente ejecutando 'alsamixer'."
        fi
    fi

    # Prueba de reproducción de audio
    info "Ahora vamos a probar la reproducción de audio..."
    pausa "Se reproducirá un tono de prueba. Por favor, escucha atentamente."

    # Mostrar los dispositivos de audio disponibles
    info "Dispositivos de audio disponibles:"
    aplay -l
    
    # Obtener el ID de la tarjeta
    tarjeta_id=$(aplay -l | grep -i "googlevoicehat\|voicehat" | head -n 1 | awk -F': ' '{print $1}' | awk '{print $2}')
    
    # Generar un tono de prueba
    if [ -n "$tarjeta_id" ]; then
        info "Usando tarjeta $tarjeta_id para reproducir tono de prueba..."
        speaker-test -D hw:$tarjeta_id,0 -t sine -f 440 -c 2 -s 2
    else
        # Intentar con el dispositivo predeterminado
        info "Intentando con dispositivo predeterminado..."
        speaker-test -t sine -f 440 -c 2 -s 2
    fi
    
    if [ $? -eq 0 ]; then
        exito "Tono de prueba reproducido correctamente."
    else
        advertencia "No se pudo reproducir el tono de prueba con speaker-test."
        info "Intentando con aplay y un archivo de audio generado..."
        
        # Crear un archivo de audio simple (un segundo de silencio)
        dd if=/dev/zero of=/tmp/silencio.raw bs=88200 count=1
        
        # Convertir a wav si ffmpeg está disponible
        if command -v ffmpeg >/dev/null 2>&1; then
            ffmpeg -f s16le -ar 44100 -ac 2 -i /tmp/silencio.raw /tmp/silencio.wav -y
            if [ -n "$tarjeta_id" ]; then
                aplay -D hw:$tarjeta_id,0 /tmp/silencio.wav
            else
                aplay /tmp/silencio.wav
            fi
        else
            # Usar directamente el archivo raw
            if [ -n "$tarjeta_id" ]; then
                aplay -D hw:$tarjeta_id,0 -f S16_LE -r 44100 -c 2 /tmp/silencio.raw
            else
                aplay -f S16_LE -r 44100 -c 2 /tmp/silencio.raw
            fi
        fi
        
        if [ $? -eq 0 ]; then
            exito "Prueba de audio alternativa completada correctamente."
        else
            error "No se pudo reproducir audio. Verifica la configuración de tu dispositivo."
        fi
    fi

    # Preguntar al usuario si pudo escuchar el sonido
    echo -e "${CYAN}"
    echo "======================================================"
    echo "        ¿Pudiste escuchar el tono de prueba?         "
    echo "======================================================"
    echo -e "${NC}"
    read -p "Responde 'si' o 'no': " respuesta

    if [[ "$respuesta" =~ ^[Ss][Ii]?$ ]]; then
        exito "¡Excelente! La reproducción de audio funciona correctamente."
    else
        advertencia "No se pudo escuchar el audio. Verificaremos la configuración..."
        # Mostrar información de dispositivos de audio
        aplay -l
        pausa "Estos son tus dispositivos de audio. Revisa la configuración si es necesario."
    fi

    # Prueba de grabación de audio
    info "Ahora vamos a probar la grabación de audio..."
    pausa "Se grabará durante 5 segundos. Por favor, habla cerca del micrófono."

    # Obtener el ID de la tarjeta para grabación
    tarjeta_id=$(arecord -l | grep -i "googlevoicehat\|voicehat" | head -n 1 | awk -F': ' '{print $1}' | awk '{print $2}')
    
    # Grabar audio de prueba
    info "Grabando audio de prueba..."
    if [ -n "$tarjeta_id" ]; then
        info "Usando tarjeta $tarjeta_id para grabar..."
        arecord -D hw:$tarjeta_id,0 -d 5 --format=S16_LE --rate=44100 -c1 /tmp/test_grabacion.wav
    else
        # Intentar con el dispositivo predeterminado
        info "Intentando grabar con dispositivo predeterminado..."
        arecord -d 5 --format=S16_LE --rate=44100 -c1 /tmp/test_grabacion.wav
    fi
    
    if [ $? -eq 0 ]; then
        exito "Audio grabado correctamente."
        
        # Reproducir la grabación
        info "Reproduciendo la grabación..."
        pausa "A continuación escucharás lo que se grabó:"
        
        if [ -n "$tarjeta_id" ]; then
            aplay -D hw:$tarjeta_id,0 /tmp/test_grabacion.wav
        else
            aplay /tmp/test_grabacion.wav
        fi
        
        if [ $? -eq 0 ]; then
            exito "Grabación reproducida correctamente."
        else
            advertencia "No se pudo reproducir la grabación."
            info "Puedes intentar reproducirla manualmente con: aplay /tmp/test_grabacion.wav"
        fi
    else
        advertencia "No se pudo grabar audio con arecord."
        info "Verificando configuración del micrófono..."
        amixer contents | grep -i "mic\|capture"
        
        # Intentar ajustar ganancia del micrófono si es posible
        if amixer set Mic 80% 2>/dev/null || amixer set Capture 80% 2>/dev/null; then
            info "Ganancia del micrófono ajustada. Intentando grabar nuevamente..."
            
            if [ -n "$tarjeta_id" ]; then
                arecord -D hw:$tarjeta_id,0 -d 5 --format=S16_LE --rate=44100 -c1 /tmp/test_grabacion.wav
            else
                arecord -d 5 --format=S16_LE --rate=44100 -c1 /tmp/test_grabacion.wav
            fi
            
            if [ $? -eq 0 ]; then
                exito "Audio grabado correctamente en el segundo intento."
                
                # Reproducir la grabación
                info "Reproduciendo la grabación..."
                pausa "A continuación escucharás lo que se grabó:"
                
                if [ -n "$tarjeta_id" ]; then
                    aplay -D hw:$tarjeta_id,0 /tmp/test_grabacion.wav
                else
                    aplay /tmp/test_grabacion.wav
                fi
            else
                error "No se pudo grabar audio. Verifica la configuración de tu dispositivo."
            fi
        else
            error "No se pudo grabar audio. Verifica la configuración de tu dispositivo."
        fi
    fi
    comprobar_comando "Audio reproducido correctamente." "No se pudo reproducir el audio grabado."

    # Preguntar al usuario si pudo escuchar la grabación
    echo -e "${CYAN}"
    echo "======================================================"
    echo "       ¿Pudiste escuchar tu voz en la grabación?     "
    echo "======================================================"
    echo -e "${NC}"
    read -p "Responde 'si' o 'no': " respuesta_grabacion

    if [[ "$respuesta_grabacion" =~ ^[Ss][Ii]?$ ]]; then
        exito "¡Perfecto! La grabación de audio funciona correctamente."
    else
        advertencia "No se pudo escuchar la grabación. Verificaremos la configuración del micrófono..."
        # Mostrar configuración del micrófono
        amixer get Mic
        pausa "Esta es la configuración de tu micrófono. Puede que necesites ajustar los niveles."
    fi

    mostrar_resumen
}

# Función para mostrar el resumen final
mostrar_resumen() {
    # Resumen final
    echo -e "${CYAN}"
    echo "======================================================"
    echo "      INSTALACIÓN DE RASPIAUDIO MIC+ COMPLETADA      "
    echo "======================================================"
    echo -e "${NC}"

    info "Comandos útiles para recordar:"
    echo "  - Para grabar audio: arecord -d [segundos] --format=S16_LE --rate=44100 -c1 [archivo.wav]"
    echo "  - Para reproducir audio: aplay [archivo.wav]"
    echo "  - Para ajustar volumen: amixer set Master [porcentaje]%"
    echo "  - Para configurar dispositivos de audio: alsamixer"

    exito "¡La instalación y configuración de RaspiAudio MIC+ se ha completado!"
}

# Ejecutar función según la opción seleccionada
case $punto_inicio in
    1)
        info "Iniciando instalación completa..."
        instalacion_completa
        ;;
    2)
        info "Iniciando instalación de RaspiAudio MIC+..."
        instalar_raspiaudio
        ;;
    3)
        info "Saltando directamente a las pruebas de audio..."
        probar_audio
        ;;
    *)
        error "Opción no válida. Por favor, selecciona 1, 2 o 3."
        ;;
esac

echo ""
echo -e "${VERDE}Para hacer ejecutable este script, usa: chmod +x 3-raspiaudio.sh${NC}"
echo -e "${VERDE}Para ejecutarlo, usa: sudo ./3-raspiaudio.sh${NC}"
