#!/bin/bash

# Colores para los mensajes
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Funciones de utilidad
print_status() { echo -e "${BLUE}➜ $1${NC}"; }
print_error() { echo -e "${RED}❌ ERROR: $1${NC}"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }

# Función para preguntar sí/no
ask_yes_no() {
    while true; do
        read -p "$1 (s/n): " yn
        case $yn in
            [Ss]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo "Por favor responde sí (s) o no (n).";;
        esac
    done
}

# Verificar si se ejecuta como root
if [[ $EUID -ne 0 ]]; then
   print_error "Este script debe ejecutarse como root (usar sudo)"
   exit 1
fi

# Detectar el usuario actual
SUDO_USER=$(logname || echo $SUDO_USER)
if [ -z "$SUDO_USER" ]; then
    print_warning "No se pudo detectar el usuario automáticamente"
    read -p "Por favor, ingresa el nombre de usuario: " SUDO_USER
    if [ -z "$SUDO_USER" ]; then
        print_error "Se requiere un nombre de usuario válido"
        exit 1
    fi
fi

print_status "Usuario detectado: $SUDO_USER"

# Instalar dependencias necesarias
print_status "Instalando dependencias necesarias..."
apt update || print_error "Fallo al actualizar paquetes"
apt install -y pulseaudio pulseaudio-module-bluetooth bluez bluez-tools || print_error "Fallo al instalar dependencias"
print_success "Dependencias instaladas correctamente"

# Añadir usuario al grupo bluetooth
print_status "Añadiendo usuario $SUDO_USER al grupo bluetooth..."
usermod -a -G bluetooth $SUDO_USER || print_error "Fallo al añadir usuario al grupo bluetooth"
print_success "Usuario añadido al grupo bluetooth"

# Reiniciar servicios de bluetooth
restart_bluetooth_service() {
    print_status "Reiniciando servicios de bluetooth..."
    systemctl stop bluetooth
    sleep 2
    systemctl start bluetooth
    sleep 2
    
    # Matar procesos existentes de bluetoothctl
    pkill bluetoothctl
    
    # Reiniciar bluetooth daemon
    killall bluetoothd
    sleep 2
    bluetoothd &
    sleep 2
    
    print_success "Servicios bluetooth reiniciados"
}

# Función para escanear dispositivos
scan_devices() {
    local scan_duration=10
    local temp_file="/tmp/bluetooth_scan.txt"
    declare -A devices
    
    # Reiniciar servicios antes del escaneo
    restart_bluetooth_service
    
    print_status "Iniciando escaneo de dispositivos Bluetooth..."
    print_warning "Por favor, pon tus dispositivos en modo de emparejamiento ahora"
    print_status "Escaneando durante $scan_duration segundos..."
    
    # Iniciar escaneo en segundo plano
    bluetoothctl -- scan on > "$temp_file" &
    scan_pid=$!
    
    # Mostrar contador regresivo
    for ((i=scan_duration; i>0; i--)); do
        echo -ne "Tiempo restante: $i segundos\r"
        sleep 1
    done
    echo
    
    # Detener escaneo
    kill $scan_pid 2>/dev/null
    bluetoothctl -- scan off >/dev/null 2>&1
    
    # Procesar resultados
    print_status "Dispositivos encontrados:"
    echo "----------------------------------------------------------------"
    echo "ID  |  Nombre del Dispositivo                |  Dirección MAC"
    echo "----------------------------------------------------------------"
    
    # Obtener lista de dispositivos
    local id=1
    while IFS= read -r line; do
        if [[ $line =~ "Device" ]]; then
            local mac=$(echo "$line" | grep -oE "([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}")
            local name=$(bluetoothctl -- info "$mac" | grep "Name" | cut -d ":" -f2- | xargs)
            if [ -z "$name" ]; then
                name="<Sin Nombre>"
            fi
            devices[$id]="$mac"
            printf "%-4s|  %-35s |  %s\n" "$id" "$name" "$mac"
            ((id++))
        fi
    done < <(bluetoothctl -- devices)
    echo "----------------------------------------------------------------"
    
    # Si no se encontraron dispositivos
    if [ ${#devices[@]} -eq 0 ]; then
        print_error "No se encontraron dispositivos. Intenta de nuevo."
        return 1
    fi
    
    # Seleccionar dispositivo
    while true; do
        read -p "Selecciona el ID del dispositivo a emparejar (o 'r' para re-escanear): " selection
        if [[ $selection == "r" ]]; then
            scan_devices
            return
        elif [[ $selection =~ ^[0-9]+$ ]] && [ -n "${devices[$selection]}" ]; then
            selected_mac="${devices[$selection]}"
            return 0
        else
            print_error "Selección inválida. Intenta de nuevo."
        fi
    done
}

# Función para emparejar y conectar dispositivo
pair_and_connect() {
    local mac=$1
    print_status "Emparejando con dispositivo: $mac"
    
    # Asegurarse que el agente está detenido
    bluetoothctl -- agent off >/dev/null 2>&1
    
    # Limpiar emparejamientos anteriores
    bluetoothctl -- remove $mac >/dev/null 2>&1
    
    print_status "Iniciando proceso de emparejamiento..."
    echo "----------------------------------------------------------------"
    
    # Registrar agente y emparejar
    expect -c "
    set timeout 20
    spawn bluetoothctl
    expect \"\[bluetooth\]\"
    send \"agent on\r\"
    expect \"\[bluetooth\]\"
    send \"default-agent\r\"
    expect \"\[bluetooth\]\"
    send \"scan on\r\"
    sleep 2
    send \"pair $mac\r\"
    expect {
        \"Request confirmation\" {
            send \"yes\r\"
            exp_continue
        }
        \"Enter PIN code\" {
            send \"0000\r\"
            exp_continue
        }
        timeout {
            exit 1
        }
        \"Failed to pair\" {
            exit 1
        }
        \"Pairing successful\" {
            send \"connect $mac\r\"
            sleep 5
            send \"trust $mac\r\"
            sleep 2
            send \"quit\r\"
            exit 0
        }
    }
    "
    
    local pair_result=$?
    echo "----------------------------------------------------------------"
    
    # Verificar la conexión
    if [ $pair_result -eq 0 ] && bluetoothctl info "$mac" | grep -q "Connected: yes"; then
        print_success "Dispositivo conectado exitosamente"
        
        # Guardar información para reconexión
        local device_name=$(bluetoothctl info "$mac" | grep "Name" | cut -d ":" -f2- | xargs)
        create_reconnect_script "$mac" "$device_name"
        return 0
    else
        print_error "Fallo al conectar el dispositivo"
        print_warning "Intenta poner el dispositivo en modo de emparejamiento nuevamente"
        return 1
    fi
}

# Función para crear script de reconexión
create_reconnect_script() {
    local mac=$1
    local name=$2
    local script_path="/home/$SUDO_USER/reconnect_bluetooth.sh"
    
    cat > "$script_path" << EOF
#!/bin/bash
echo "Reconectando a $name..."
bluetoothctl -- connect $mac
EOF

    chmod +x "$script_path"
    chown $SUDO_USER:$SUDO_USER "$script_path"
    
    print_status "Se ha creado un script de reconexión en $script_path"
    print_status "Puedes usarlo para reconectar rápidamente tu dispositivo"
}

# Configurar audio
setup_audio() {
    print_status "Configurando audio..."
    
    # Reiniciar pulseaudio
    print_status "Reiniciando pulseaudio..."
    su - $SUDO_USER -c "pulseaudio -k"
    sleep 2
    su - $SUDO_USER -c "pulseaudio --start"
    
    # Esperar a que el dispositivo esté disponible
    sleep 5
    
    # Verificar si el dispositivo está listado
    if pactl list sinks | grep -q "bluetooth"; then
        print_success "Dispositivo de audio Bluetooth detectado"
    else
        print_warning "No se detectó el dispositivo de audio Bluetooth. Puede ser necesario reiniciar el sistema"
    fi
}

# Ejecutar el proceso principal
clear
print_status "Iniciando configuración de Bluetooth..."

# Asegurarse que expect está instalado
if ! command -v expect &> /dev/null; then
    print_status "Instalando expect..."
    apt install -y expect || print_error "No se pudo instalar expect"
fi

# Escanear y seleccionar dispositivo
if scan_devices; then
    if pair_and_connect "$selected_mac"; then
        setup_audio
        print_success "¡Configuración completada!"
    fi
fi

if ask_yes_no "¿Deseas reiniciar el sistema ahora?"; then
    print_status "Reiniciando sistema..."
    reboot
fi