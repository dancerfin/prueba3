#!/usr/bin/env python3
import re
import os
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

def parse_log_file(log_file):
    pattern = r"DDoS Detection Rate: (\d+\.\d+)% \| Detected: (\d+) \| Total: (\d+) \| Elapsed: (\d+\.\d+)s"
    data = []
    
    with open(log_file, 'r') as f:
        for line in f:
            match = re.search(pattern, line)
            if match:
                rate = float(match.group(1))
                detected = int(match.group(2))
                total = int(match.group(3))
                elapsed = float(match.group(4))
                
                data.append({
                    'rate': rate,
                    'detected': detected,
                    'total': total,
                    'elapsed': elapsed
                })
    
    # Normaliza el tiempo para que comience en 0
    if data:
        initial_time = data[0]['elapsed']
        for entry in data:
            entry['elapsed'] -= initial_time
    
    return data

def generate_report(data, output_dir="monitoring_results", log_file="ddos_detection_report.log"):
    if not data:
        print("No se encontraron datos de detección DDoS")
        return
    
    rates = [d['rate'] for d in data]
    times = [d['elapsed'] for d in data]
    
    avg_rate = sum(rates) / len(rates)
    min_rate = min(rates)
    max_rate = max(rates)
    total_duration = times[-1] if times else 0
    
    report_content = "\n=== Reporte de Detección DDoS ===\n"
    report_content += f"Tasa promedio de detección: {avg_rate:.2f}%\n"
    report_content += f"Tasa mínima de detección: {min_rate:.2f}%\n"
    report_content += f"Tasa máxima de detección: {max_rate:.2f}%\n"
    report_content += f"Duración total de la prueba: {total_duration:.1f} segundos\n"
    report_content += f"Ataques detectados: {data[-1]['detected']}\n"
    report_content += f"Ataques totales: {data[-1]['total']}\n"
    
    # Guardar en archivo log
    os.makedirs(output_dir, exist_ok=True)
    log_path = os.path.join(output_dir, log_file)
    
    with open(log_path, 'w') as f:
        f.write(report_content)
    
    print(report_content)
    print(f"Reporte guardado en '{log_path}'")
    
    # Generar gráfico
    plt.figure(figsize=(10, 5))
    plt.plot(times, rates, 'b-', label='Tasa de detección')
    plt.axhline(y=90, color='r', linestyle='--', label='Objetivo (90%)')
    plt.title('Tasa de Detección de Ataques DDoS')
    plt.xlabel('Tiempo desde inicio de prueba (segundos)')
    plt.ylabel('Porcentaje de ataques detectados (%)')
    plt.ylim(0, 101)
    plt.grid(True)
    plt.legend()
    
    output_path = os.path.join(output_dir, 'ddos_detection_rate.png')
    plt.savefig(output_path)
    print(f"\nGráfico guardado como '{output_path}'")

if __name__ == '__main__':
    import sys
    
    if len(sys.argv) < 2:
        log_file = input("Ingrese la ruta del archivo de log (ddos_detection.log): ").strip()
    else:
        log_file = sys.argv[1]
    
    output_dir = "monitoring_results"
    data = parse_log_file(log_file)
    generate_report(data, output_dir)