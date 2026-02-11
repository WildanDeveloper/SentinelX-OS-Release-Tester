#!/usr/bin/env python3
"""
SentinelX OS - System Health Monitor
Real-time monitoring dashboard for SentinelX OS
"""

import os
import sys
import time
import psutil
import json
from datetime import datetime
from pathlib import Path

class SentinelXMonitor:
    def __init__(self):
        self.log_dir = Path("/var/log/sentinelx")
        self.config_dir = Path("/etc/sentinelx")
        self.log_dir.mkdir(parents=True, exist_ok=True)
        
    def get_system_info(self):
        """Gather comprehensive system information"""
        info = {
            'timestamp': datetime.now().isoformat(),
            'cpu': self.get_cpu_info(),
            'memory': self.get_memory_info(),
            'disk': self.get_disk_info(),
            'network': self.get_network_info(),
            'processes': self.get_process_info(),
            'boot_time': datetime.fromtimestamp(psutil.boot_time()).isoformat()
        }
        return info
    
    def get_cpu_info(self):
        """Get CPU usage and statistics"""
        cpu_percent = psutil.cpu_percent(interval=1, percpu=True)
        cpu_freq = psutil.cpu_freq()
        
        return {
            'usage_per_core': cpu_percent,
            'usage_total': psutil.cpu_percent(interval=1),
            'cores_physical': psutil.cpu_count(logical=False),
            'cores_logical': psutil.cpu_count(logical=True),
            'frequency': {
                'current': cpu_freq.current if cpu_freq else 0,
                'min': cpu_freq.min if cpu_freq else 0,
                'max': cpu_freq.max if cpu_freq else 0
            },
            'load_average': os.getloadavg()
        }
    
    def get_memory_info(self):
        """Get memory usage statistics"""
        mem = psutil.virtual_memory()
        swap = psutil.swap_memory()
        
        return {
            'total': mem.total,
            'available': mem.available,
            'used': mem.used,
            'free': mem.free,
            'percent': mem.percent,
            'swap': {
                'total': swap.total,
                'used': swap.used,
                'free': swap.free,
                'percent': swap.percent
            }
        }
    
    def get_disk_info(self):
        """Get disk usage for all partitions"""
        disks = []
        for partition in psutil.disk_partitions():
            try:
                usage = psutil.disk_usage(partition.mountpoint)
                disks.append({
                    'device': partition.device,
                    'mountpoint': partition.mountpoint,
                    'fstype': partition.fstype,
                    'total': usage.total,
                    'used': usage.used,
                    'free': usage.free,
                    'percent': usage.percent
                })
            except PermissionError:
                continue
        
        io_counters = psutil.disk_io_counters()
        return {
            'partitions': disks,
            'io': {
                'read_bytes': io_counters.read_bytes,
                'write_bytes': io_counters.write_bytes,
                'read_count': io_counters.read_count,
                'write_count': io_counters.write_count
            } if io_counters else {}
        }
    
    def get_network_info(self):
        """Get network statistics"""
        net_io = psutil.net_io_counters()
        connections = len(psutil.net_connections())
        
        interfaces = {}
        for iface, addrs in psutil.net_if_addrs().items():
            interfaces[iface] = [
                {
                    'family': str(addr.family),
                    'address': addr.address,
                    'netmask': addr.netmask
                } for addr in addrs
            ]
        
        return {
            'bytes_sent': net_io.bytes_sent,
            'bytes_recv': net_io.bytes_recv,
            'packets_sent': net_io.packets_sent,
            'packets_recv': net_io.packets_recv,
            'active_connections': connections,
            'interfaces': interfaces
        }
    
    def get_process_info(self):
        """Get process statistics"""
        processes = []
        for proc in psutil.process_iter(['pid', 'name', 'cpu_percent', 'memory_percent']):
            try:
                processes.append({
                    'pid': proc.info['pid'],
                    'name': proc.info['name'],
                    'cpu_percent': proc.info['cpu_percent'],
                    'memory_percent': proc.info['memory_percent']
                })
            except (psutil.NoSuchProcess, psutil.AccessDenied):
                pass
        
        # Sort by CPU usage and get top 10
        processes.sort(key=lambda x: x['cpu_percent'] or 0, reverse=True)
        
        return {
            'total': len(processes),
            'top_cpu': processes[:10]
        }
    
    def check_security_status(self):
        """Check security layer status"""
        status = {
            'apparmor': self.check_apparmor(),
            'selinux': self.check_selinux(),
            'firewall': self.check_firewall()
        }
        return status
    
    def check_apparmor(self):
        """Check AppArmor status"""
        try:
            result = os.popen('aa-status 2>/dev/null').read()
            return 'enabled' if result else 'disabled'
        except:
            return 'unknown'
    
    def check_selinux(self):
        """Check SELinux status"""
        try:
            result = os.popen('getenforce 2>/dev/null').read().strip()
            return result.lower() if result else 'disabled'
        except:
            return 'unknown'
    
    def check_firewall(self):
        """Check firewall status"""
        try:
            result = os.popen('systemctl is-active firewalld 2>/dev/null').read().strip()
            return result if result else 'inactive'
        except:
            return 'unknown'
    
    def format_bytes(self, bytes_value):
        """Format bytes to human readable format"""
        for unit in ['B', 'KB', 'MB', 'GB', 'TB']:
            if bytes_value < 1024.0:
                return f"{bytes_value:.2f} {unit}"
            bytes_value /= 1024.0
        return f"{bytes_value:.2f} PB"
    
    def display_dashboard(self):
        """Display interactive dashboard"""
        while True:
            os.system('clear')
            
            print("=" * 80)
            print("  ██████ ▓█████  ███▄    █ ▓█████▓ ██▓ ███▄    █ ▓█████  ██▓    ▒██   ██▒")
            print("                    SentinelX OS - System Monitor")
            print("=" * 80)
            print()
            
            info = self.get_system_info()
            
            # CPU Information
            print(f"🔥 CPU Usage: {info['cpu']['usage_total']:.1f}%")
            print(f"   Cores: {info['cpu']['cores_physical']} physical / {info['cpu']['cores_logical']} logical")
            print(f"   Load Average: {info['cpu']['load_average'][0]:.2f}, {info['cpu']['load_average'][1]:.2f}, {info['cpu']['load_average'][2]:.2f}")
            print()
            
            # Memory Information
            mem = info['memory']
            print(f"💾 Memory: {mem['percent']:.1f}% used")
            print(f"   Total: {self.format_bytes(mem['total'])} | Used: {self.format_bytes(mem['used'])} | Free: {self.format_bytes(mem['free'])}")
            if mem['swap']['total'] > 0:
                print(f"   Swap: {mem['swap']['percent']:.1f}% ({self.format_bytes(mem['swap']['used'])} / {self.format_bytes(mem['swap']['total'])})")
            print()
            
            # Disk Information
            print("💿 Disk Usage:")
            for disk in info['disk']['partitions'][:3]:
                print(f"   {disk['mountpoint']}: {disk['percent']:.1f}% ({self.format_bytes(disk['used'])} / {self.format_bytes(disk['total'])})")
            print()
            
            # Network Information
            net = info['network']
            print(f"🌐 Network:")
            print(f"   Sent: {self.format_bytes(net['bytes_sent'])} | Received: {self.format_bytes(net['bytes_recv'])}")
            print(f"   Active Connections: {net['active_connections']}")
            print()
            
            # Security Status
            security = self.check_security_status()
            print(f"🛡️  Security:")
            print(f"   AppArmor: {security['apparmor']} | SELinux: {security['selinux']} | Firewall: {security['firewall']}")
            print()
            
            # Top Processes
            print("📊 Top Processes by CPU:")
            for proc in info['processes']['top_cpu'][:5]:
                print(f"   {proc['name'][:20]:20} PID:{proc['pid']:6} CPU:{proc['cpu_percent']:5.1f}% MEM:{proc['memory_percent']:5.1f}%")
            
            print()
            print("=" * 80)
            print(f"Last updated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')} | Press Ctrl+C to exit")
            
            time.sleep(2)
    
    def export_report(self, filename=None):
        """Export system report to JSON file"""
        if filename is None:
            filename = self.log_dir / f"system-report-{datetime.now().strftime('%Y%m%d-%H%M%S')}.json"
        
        info = self.get_system_info()
        info['security'] = self.check_security_status()
        
        with open(filename, 'w') as f:
            json.dump(info, f, indent=2)
        
        print(f"Report exported to: {filename}")
        return filename

def main():
    monitor = SentinelXMonitor()
    
    if len(sys.argv) > 1 and sys.argv[1] == '--export':
        monitor.export_report()
    else:
        try:
            monitor.display_dashboard()
        except KeyboardInterrupt:
            print("\n\nMonitoring stopped.")
            sys.exit(0)

if __name__ == '__main__':
    main()
