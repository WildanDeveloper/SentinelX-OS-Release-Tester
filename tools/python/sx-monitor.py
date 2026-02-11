#!/usr/bin/env python3
"""
SentinelX System Health Monitor

Copyright (C) 2026 WildanDev
License: GPL v3

Real-time system monitoring with alerts and logging.
"""

import os
import sys
import time
import psutil
import json
import argparse
from datetime import datetime
from collections import deque
from pathlib import Path

# Constants
VERSION = "1.0.0"
CONFIG_DIR = Path.home() / ".config" / "sx-monitor"
LOG_FILE = CONFIG_DIR / "health.log"
CONFIG_FILE = CONFIG_DIR / "config.json"

# Default thresholds
DEFAULT_CONFIG = {
    "cpu_threshold": 80.0,
    "memory_threshold": 85.0,
    "disk_threshold": 90.0,
    "temperature_threshold": 75.0,
    "check_interval": 5,
    "alert_enabled": True,
    "log_enabled": True
}

class Colors:
    """ANSI color codes"""
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    CYAN = '\033[96m'
    BOLD = '\033[1m'
    END = '\033[0m'

class SystemMonitor:
    """Main system monitoring class"""
    
    def __init__(self, config=None):
        self.config = config or DEFAULT_CONFIG
        self.history = {
            'cpu': deque(maxlen=60),
            'memory': deque(maxlen=60),
            'disk': deque(maxlen=60),
            'temp': deque(maxlen=60)
        }
        self.alerts_triggered = 0
        self.start_time = time.time()
        
        # Create config directory
        CONFIG_DIR.mkdir(parents=True, exist_ok=True)
    
    def get_cpu_info(self):
        """Get CPU usage and frequency"""
        cpu_percent = psutil.cpu_percent(interval=1, percpu=False)
        cpu_freq = psutil.cpu_freq()
        cpu_count = psutil.cpu_count()
        
        return {
            'percent': cpu_percent,
            'freq_current': cpu_freq.current if cpu_freq else 0,
            'freq_max': cpu_freq.max if cpu_freq else 0,
            'count': cpu_count,
            'per_cpu': psutil.cpu_percent(percpu=True)
        }
    
    def get_memory_info(self):
        """Get memory usage"""
        mem = psutil.virtual_memory()
        swap = psutil.swap_memory()
        
        return {
            'total': mem.total,
            'available': mem.available,
            'used': mem.used,
            'percent': mem.percent,
            'swap_total': swap.total,
            'swap_used': swap.used,
            'swap_percent': swap.percent
        }
    
    def get_disk_info(self):
        """Get disk usage"""
        disks = {}
        for partition in psutil.disk_partitions():
            try:
                usage = psutil.disk_usage(partition.mountpoint)
                disks[partition.mountpoint] = {
                    'total': usage.total,
                    'used': usage.used,
                    'free': usage.free,
                    'percent': usage.percent,
                    'device': partition.device,
                    'fstype': partition.fstype
                }
            except PermissionError:
                continue
        
        return disks
    
    def get_temperature(self):
        """Get CPU temperature (if available)"""
        try:
            temps = psutil.sensors_temperatures()
            if temps:
                # Try common temperature sensor names
                for name in ['coretemp', 'k10temp', 'cpu_thermal']:
                    if name in temps:
                        return {
                            'current': temps[name][0].current,
                            'high': temps[name][0].high,
                            'critical': temps[name][0].critical
                        }
            return {'current': 0, 'high': 0, 'critical': 0}
        except:
            return {'current': 0, 'high': 0, 'critical': 0}
    
    def get_network_info(self):
        """Get network statistics"""
        net_io = psutil.net_io_counters()
        connections = len(psutil.net_connections())
        
        return {
            'bytes_sent': net_io.bytes_sent,
            'bytes_recv': net_io.bytes_recv,
            'packets_sent': net_io.packets_sent,
            'packets_recv': net_io.packets_recv,
            'connections': connections
        }
    
    def get_process_info(self):
        """Get top processes by CPU and memory"""
        processes = []
        for proc in psutil.process_iter(['pid', 'name', 'cpu_percent', 'memory_percent']):
            try:
                processes.append(proc.info)
            except (psutil.NoSuchProcess, psutil.AccessDenied):
                pass
        
        # Sort by CPU usage
        top_cpu = sorted(processes, key=lambda x: x['cpu_percent'], reverse=True)[:5]
        # Sort by memory usage
        top_mem = sorted(processes, key=lambda x: x['memory_percent'], reverse=True)[:5]
        
        return {
            'total': len(processes),
            'top_cpu': top_cpu,
            'top_memory': top_mem
        }
    
    def check_thresholds(self, stats):
        """Check if any thresholds are exceeded"""
        alerts = []
        
        if stats['cpu']['percent'] > self.config['cpu_threshold']:
            alerts.append(f"CPU usage high: {stats['cpu']['percent']:.1f}%")
        
        if stats['memory']['percent'] > self.config['memory_threshold']:
            alerts.append(f"Memory usage high: {stats['memory']['percent']:.1f}%")
        
        for mount, disk in stats['disk'].items():
            if disk['percent'] > self.config['disk_threshold']:
                alerts.append(f"Disk {mount} usage high: {disk['percent']:.1f}%")
        
        temp = stats['temperature']['current']
        if temp > 0 and temp > self.config['temperature_threshold']:
            alerts.append(f"CPU temperature high: {temp:.1f}°C")
        
        return alerts
    
    def log_event(self, message, level="INFO"):
        """Log events to file"""
        if not self.config['log_enabled']:
            return
        
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        log_entry = f"[{timestamp}] [{level}] {message}\n"
        
        with open(LOG_FILE, 'a') as f:
            f.write(log_entry)
    
    def display_dashboard(self, stats):
        """Display real-time dashboard"""
        os.system('clear' if os.name != 'nt' else 'cls')
        
        print(f"{Colors.CYAN}{Colors.BOLD}╔═══════════════════════════════════════════════════╗{Colors.END}")
        print(f"{Colors.CYAN}{Colors.BOLD}║     SentinelX System Health Monitor v{VERSION}      ║{Colors.END}")
        print(f"{Colors.CYAN}{Colors.BOLD}╚═══════════════════════════════════════════════════╝{Colors.END}")
        print()
        
        # CPU
        cpu_color = self._get_color(stats['cpu']['percent'], self.config['cpu_threshold'])
        print(f"{Colors.BOLD}CPU:{Colors.END}")
        print(f"  Usage: {cpu_color}{stats['cpu']['percent']:.1f}%{Colors.END} "
              f"({stats['cpu']['count']} cores @ {stats['cpu']['freq_current']:.0f} MHz)")
        
        # Per-CPU usage bar
        print("  Cores: ", end="")
        for i, usage in enumerate(stats['cpu']['per_cpu']):
            bar = self._create_bar(usage, 10)
            print(f"[{bar}] ", end="")
            if (i + 1) % 4 == 0:
                print("\n         ", end="")
        print()
        
        # Memory
        mem_color = self._get_color(stats['memory']['percent'], self.config['memory_threshold'])
        mem_used_gb = stats['memory']['used'] / (1024**3)
        mem_total_gb = stats['memory']['total'] / (1024**3)
        print(f"\n{Colors.BOLD}Memory:{Colors.END}")
        print(f"  RAM:  {mem_color}{stats['memory']['percent']:.1f}%{Colors.END} "
              f"({mem_used_gb:.1f} GB / {mem_total_gb:.1f} GB)")
        if stats['memory']['swap_total'] > 0:
            swap_used_gb = stats['memory']['swap_used'] / (1024**3)
            swap_total_gb = stats['memory']['swap_total'] / (1024**3)
            print(f"  Swap: {stats['memory']['swap_percent']:.1f}% "
                  f"({swap_used_gb:.1f} GB / {swap_total_gb:.1f} GB)")
        
        # Disk
        print(f"\n{Colors.BOLD}Disk:{Colors.END}")
        for mount, disk in stats['disk'].items():
            disk_color = self._get_color(disk['percent'], self.config['disk_threshold'])
            disk_used_gb = disk['used'] / (1024**3)
            disk_total_gb = disk['total'] / (1024**3)
            print(f"  {mount}: {disk_color}{disk['percent']:.1f}%{Colors.END} "
                  f"({disk_used_gb:.1f} GB / {disk_total_gb:.1f} GB)")
        
        # Temperature
        if stats['temperature']['current'] > 0:
            temp_color = self._get_color(stats['temperature']['current'], 
                                         self.config['temperature_threshold'])
            print(f"\n{Colors.BOLD}Temperature:{Colors.END}")
            print(f"  CPU: {temp_color}{stats['temperature']['current']:.1f}°C{Colors.END}")
        
        # Network
        print(f"\n{Colors.BOLD}Network:{Colors.END}")
        sent_mb = stats['network']['bytes_sent'] / (1024**2)
        recv_mb = stats['network']['bytes_recv'] / (1024**2)
        print(f"  Sent:     {sent_mb:.1f} MB")
        print(f"  Received: {recv_mb:.1f} MB")
        print(f"  Active Connections: {stats['network']['connections']}")
        
        # Top processes
        print(f"\n{Colors.BOLD}Top CPU Processes:{Colors.END}")
        for proc in stats['processes']['top_cpu'][:3]:
            print(f"  {proc['name']:<20} {proc['cpu_percent']:>6.1f}% CPU")
        
        print(f"\n{Colors.BOLD}Top Memory Processes:{Colors.END}")
        for proc in stats['processes']['top_memory'][:3]:
            print(f"  {proc['name']:<20} {proc['memory_percent']:>6.1f}% MEM")
        
        # Alerts
        alerts = self.check_thresholds(stats)
        if alerts:
            print(f"\n{Colors.RED}{Colors.BOLD}⚠ ALERTS:{Colors.END}")
            for alert in alerts:
                print(f"  {Colors.RED}• {alert}{Colors.END}")
            self.alerts_triggered += len(alerts)
        
        # Stats
        uptime = time.time() - self.start_time
        print(f"\n{Colors.BOLD}Monitor Stats:{Colors.END}")
        print(f"  Uptime: {int(uptime)}s | Alerts: {self.alerts_triggered} | "
              f"Interval: {self.config['check_interval']}s")
        
        print(f"\n{Colors.CYAN}Press Ctrl+C to exit{Colors.END}")
    
    def _get_color(self, value, threshold):
        """Get color based on value and threshold"""
        if value >= threshold:
            return Colors.RED
        elif value >= threshold * 0.8:
            return Colors.YELLOW
        else:
            return Colors.GREEN
    
    def _create_bar(self, percent, length=10):
        """Create visual progress bar"""
        filled = int(percent / 100 * length)
        return '█' * filled + '░' * (length - filled)
    
    def collect_stats(self):
        """Collect all system statistics"""
        stats = {
            'timestamp': datetime.now().isoformat(),
            'cpu': self.get_cpu_info(),
            'memory': self.get_memory_info(),
            'disk': self.get_disk_info(),
            'temperature': self.get_temperature(),
            'network': self.get_network_info(),
            'processes': self.get_process_info()
        }
        
        # Update history
        self.history['cpu'].append(stats['cpu']['percent'])
        self.history['memory'].append(stats['memory']['percent'])
        self.history['temp'].append(stats['temperature']['current'])
        
        return stats
    
    def run(self):
        """Main monitoring loop"""
        print(f"{Colors.GREEN}Starting SentinelX System Monitor...{Colors.END}")
        self.log_event("Monitor started", "INFO")
        
        try:
            while True:
                stats = self.collect_stats()
                
                # Check for alerts
                alerts = self.check_thresholds(stats)
                for alert in alerts:
                    self.log_event(alert, "WARNING")
                
                # Display dashboard
                self.display_dashboard(stats)
                
                # Wait for next check
                time.sleep(self.config['check_interval'])
        
        except KeyboardInterrupt:
            print(f"\n{Colors.YELLOW}Monitor stopped by user{Colors.END}")
            self.log_event("Monitor stopped", "INFO")
        
        except Exception as e:
            print(f"\n{Colors.RED}Error: {e}{Colors.END}")
            self.log_event(f"Error: {e}", "ERROR")

def load_config():
    """Load configuration from file"""
    if CONFIG_FILE.exists():
        with open(CONFIG_FILE, 'r') as f:
            return json.load(f)
    return DEFAULT_CONFIG

def save_config(config):
    """Save configuration to file"""
    with open(CONFIG_FILE, 'w') as f:
        json.dump(config, f, indent=2)

def main():
    """Main entry point"""
    parser = argparse.ArgumentParser(
        description="SentinelX System Health Monitor",
        formatter_class=argparse.RawDescriptionHelpFormatter
    )
    
    parser.add_argument('-v', '--version', action='version', version=f'sx-monitor v{VERSION}')
    parser.add_argument('-i', '--interval', type=int, help='Check interval in seconds')
    parser.add_argument('--cpu-threshold', type=float, help='CPU usage threshold (%)')
    parser.add_argument('--mem-threshold', type=float, help='Memory usage threshold (%)')
    parser.add_argument('--disk-threshold', type=float, help='Disk usage threshold (%)')
    parser.add_argument('--no-alerts', action='store_true', help='Disable alerts')
    parser.add_argument('--no-log', action='store_true', help='Disable logging')
    
    args = parser.parse_args()
    
    # Load config
    config = load_config()
    
    # Override with command line arguments
    if args.interval:
        config['check_interval'] = args.interval
    if args.cpu_threshold:
        config['cpu_threshold'] = args.cpu_threshold
    if args.mem_threshold:
        config['memory_threshold'] = args.mem_threshold
    if args.disk_threshold:
        config['disk_threshold'] = args.disk_threshold
    if args.no_alerts:
        config['alert_enabled'] = False
    if args.no_log:
        config['log_enabled'] = False
    
    # Save updated config
    save_config(config)
    
    # Run monitor
    monitor = SystemMonitor(config)
    monitor.run()

if __name__ == "__main__":
    main()
