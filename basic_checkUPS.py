#!/usr/bin/env python3
from smbus2 import SMBus
import time

# Dirección I2C típica para UPS X1203 (puede variar, verifica con i2cdetect)
UPS_ADDRESS = 0x36

# Registros comunes (estos pueden variar según el modelo exacto)
VOLTAGE_REG = 0x02
CAPACITY_REG = 0x04
STATUS_REG = 0x01

def read_voltage(bus):
    # Lee los bytes de voltaje y convierte a valor real
    data = bus.read_word_data(UPS_ADDRESS, VOLTAGE_REG)
    voltage = data * 1.25 / 1000.0  # Ajusta este factor según la documentación
    return voltage

def read_capacity(bus):
    # Lee el porcentaje de capacidad
    data = bus.read_word_data(UPS_ADDRESS, CAPACITY_REG)
    capacity = data / 256.0  # Ajusta este factor según la documentación
    return capacity

def read_status(bus):
    # Lee el registro de estado
    status = bus.read_byte_data(UPS_ADDRESS, STATUS_REG)
    return status

def main():
    with SMBus(1) as bus:  # 1 es el bus I2C en Pi 2 o superior, usa 0 para Pi 1
        try:
            voltage = read_voltage(bus)
            capacity = read_capacity(bus)
            status = read_status(bus)
            
            print(f"Voltage: {voltage:.2f}V")
            print(f"Capacity: {capacity:.1f}%")
            print(f"Status: {status:08b}")  # Muestra en formato binario
            
            # Interpreta el estado (ajusta según la documentación)
            if status & 0x01:
                print("Estado: Cargando")
            else:
                print("Estado: Descargando o inactivo")
                
        except Exception as e:
            print(f"Error al leer datos: {e}")

if __name__ == "__main__":
    main()
