#!/bin/bash

# Colores para una mejor visualización
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Función para mostrar mensajes con estilo
print_message() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[ÉXITO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[AVISO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Función para actualizar la Raspberry Pi
update_raspberry() {
    print_message "Actualizando la Raspberry Pi..."
    sudo apt update
    if [ $? -eq 0 ]; then
        print_success "Repositorios actualizados correctamente."
    else
        print_error "Error al actualizar repositorios."
    fi
    
    read -p "Presiona Enter para continuar..."
}

# Función para instalar virtualenv y paquetes necesarios
install_virtualenv() {
    print_message "Instalando virtualenv..."
    sudo apt install -y virtualenv
    if [ $? -eq 0 ]; then
        print_success "virtualenv instalado correctamente."
    else
        print_error "Error al instalar virtualenv."
    fi
    
    print_message "Instalando python3-pip..."
    sudo apt install -y python3-pip
    if [ $? -eq 0 ]; then
        print_success "python3-pip instalado correctamente."
    else
        print_error "Error al instalar python3-pip."
    fi
    
    read -p "Presiona Enter para continuar..."
}

# Función para instalar virtualenvwrapper y dependencias
install_virtualenvwrapper() {
    print_message "Instalando python3-virtualenvwrapper..."
    sudo apt install -y python3-virtualenvwrapper
    if [ $? -eq 0 ]; then
        print_success "python3-virtualenvwrapper instalado correctamente."
    else
        print_error "Error al instalar python3-virtualenvwrapper."
    fi
    
    print_message "Instalando python3-setuptools..."
    sudo apt-get install -y python3-setuptools
    if [ $? -eq 0 ]; then
        print_success "python3-setuptools instalado correctamente."
    else
        print_error "Error al instalar python3-setuptools."
    fi
    
    read -p "Presiona Enter para continuar..."
}

# Función para encontrar la ubicación del archivo virtualenvwrapper.sh
find_virtualenvwrapper() {
    print_message "Buscando la ubicación del archivo virtualenvwrapper.sh..."
    
    WRAPPER_PATH=$(find / -name virtualenvwrapper.sh 2>/dev/null | head -n 1)
    
    if [ -n "$WRAPPER_PATH" ]; then
        print_success "Archivo virtualenvwrapper.sh encontrado en: $WRAPPER_PATH"
    else
        print_error "No se pudo encontrar el archivo virtualenvwrapper.sh"
        WRAPPER_PATH="/usr/share/virtualenvwrapper/virtualenvwrapper.sh"
        print_warning "Se usará la ruta predeterminada: $WRAPPER_PATH"
    fi
    
    echo "Ruta del virtualenvwrapper.sh: $WRAPPER_PATH"
    
    read -p "Presiona Enter para continuar..."
    
    return 0
}

# Función para modificar el archivo .bashrc
modify_bashrc() {
    # Primero buscamos la ubicación del virtualenvwrapper.sh
    print_message "Buscando la ubicación del archivo virtualenvwrapper.sh..."
    WRAPPER_PATH=$(find / -name virtualenvwrapper.sh 2>/dev/null | head -n 1)
    
    if [ -n "$WRAPPER_PATH" ]; then
        print_success "Archivo virtualenvwrapper.sh encontrado en: $WRAPPER_PATH"
    else
        print_error "No se pudo encontrar el archivo virtualenvwrapper.sh"
        WRAPPER_PATH="/usr/share/virtualenvwrapper/virtualenvwrapper.sh"
        print_warning "Se usará la ruta predeterminada: $WRAPPER_PATH"
    fi
    
    print_message "Modificando ~/.bashrc para configurar virtualenvwrapper..."
    
    # Verificar si las líneas ya existen para evitar duplicados
    if grep -q "export WORKON_HOME=\$HOME/.virtualenvs" ~/.bashrc && \
       grep -q "export VIRTUALENVWRAPPER_PYTHON=/usr/bin/python3" ~/.bashrc && \
       grep -q "source $WRAPPER_PATH" ~/.bashrc; then
        print_warning "La configuración ya existe en ~/.bashrc"
    else
        # Añadir las líneas al final del archivo .bashrc
        echo -e "\n# Configuración de virtualenvwrapper" >> ~/.bashrc
        echo "export WORKON_HOME=\$HOME/.virtualenvs" >> ~/.bashrc
        echo "export VIRTUALENVWRAPPER_PYTHON=/usr/bin/python3" >> ~/.bashrc
        echo "source $WRAPPER_PATH" >> ~/.bashrc
        
        print_success "Archivo ~/.bashrc modificado correctamente."
    fi
    
    print_message "Cargando los cambios..."
    source ~/.bashrc
    
    print_success "Cambios cargados. La configuración está activa."
    
    echo "Contenido añadido a ~/.bashrc:"
    echo "export WORKON_HOME=\$HOME/.virtualenvs"
    echo "export VIRTUALENVWRAPPER_PYTHON=/usr/bin/python3"
    echo "source $WRAPPER_PATH"
    
    read -p "Presiona Enter para continuar..."
}

# Función para verificar si virtualenvwrapper funciona
check_workon() {
    print_message "Verificando si virtualenvwrapper funciona correctamente..."
    
    # Intentar ejecutar el comando workon
    if type workon &>/dev/null; then
        print_success "El comando 'workon' está disponible. virtualenvwrapper está funcionando correctamente."
        echo "Entornos virtuales disponibles:"
        workon
    else
        print_error "El comando 'workon' no está disponible. Puede que necesites cerrar y volver a abrir la terminal."
        print_message "Intentando cargar virtualenvwrapper manualmente..."
        
        # Buscar la ubicación del virtualenvwrapper.sh
        WRAPPER_PATH=$(find / -name virtualenvwrapper.sh 2>/dev/null | head -n 1)
        
        if [ -n "$WRAPPER_PATH" ]; then
            print_message "Cargando virtualenvwrapper desde $WRAPPER_PATH"
            source "$WRAPPER_PATH"
            
            # Verificar nuevamente
            if type workon &>/dev/null; then
                print_success "¡Ahora funciona! El comando 'workon' está disponible."
                echo "Entornos virtuales disponibles:"
                workon
            else
                print_error "Sigue sin funcionar. Recomendación: Cierra y vuelve a abrir la terminal."
            fi
        else
            print_error "No se pudo encontrar virtualenvwrapper.sh"
        fi
    fi
    
    read -p "Presiona Enter para continuar..."
}

# Función del menú principal
show_menu() {
    clear
    echo "======================================"
    echo "   CONFIGURACIÓN DE RASPBERRY PI      "
    echo "======================================"
    echo "1. Actualizar Raspberry Pi"
    echo "2. Instalar virtualenv"
    echo "3. Instalar virtualenvwrapper"
    echo "4. Modificar ~/.bashrc y cargar cambios"
    echo "5. Verificar funcionamiento de workon"
    echo "0. Salir"
    echo "======================================"
    echo -n "Selecciona una opción [0-5]: "
}

# Función del menú principal
show_menu() {
    clear
    echo "======================================"
    echo "   CONFIGURACIÓN DE RASPBERRY PI      "
    echo "======================================"
    echo "1. Actualizar Raspberry Pi (sudo apt update)"
    echo "2. Instalar virtualenv y python3-pip"
    echo "3. Instalar python3-virtualenvwrapper y dependencias"
    echo "4. Buscar ubicación de virtualenvwrapper.sh"
    echo "5. Modificar ~/.bashrc y cargar cambios"
    echo "6. Verificar funcionamiento de workon"
    echo "0. Salir"
    echo "======================================"
    echo -n "Selecciona una opción [0-6]: "
}

# Bucle principal
while true; do
    show_menu
    read option
    
    case $option in
        1)
            update_raspberry
            ;;
        2)
            install_virtualenv
            ;;
        3)
            install_virtualenvwrapper
            ;;
        4)
            find_virtualenvwrapper
            ;;
        5)
            modify_bashrc
            ;;
        6)
            check_workon
            ;;
        0)
            print_message "Saliendo del script de configuración..."
            exit 0
            ;;
        *)
            print_error "Opción inválida. Por favor, selecciona una opción entre 0 y 6."
            read -p "Presiona Enter para continuar..."
            ;;
    esac
done
