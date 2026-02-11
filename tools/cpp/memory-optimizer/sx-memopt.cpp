/*
 * SentinelX Memory Optimizer
 * 
 * Copyright (C) 2026 WildanDev
 * License: GPL v3
 *
 * Advanced memory management and optimization tool
 * with cache management and memory compression.
 */

#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <map>
#include <algorithm>
#include <cstring>
#include <unistd.h>
#include <sys/sysinfo.h>
#include <sys/stat.h>

#define VERSION "1.0.0"

class MemoryOptimizer {
private:
    struct MemoryInfo {
        unsigned long total;
        unsigned long free;
        unsigned long available;
        unsigned long buffers;
        unsigned long cached;
        unsigned long swap_total;
        unsigned long swap_free;
        unsigned long swap_cached;
    };
    
    MemoryInfo mem_info;
    bool verbose;
    
    // Read /proc/meminfo
    bool read_meminfo() {
        std::ifstream meminfo("/proc/meminfo");
        if (!meminfo.is_open()) {
            std::cerr << "Error: Cannot open /proc/meminfo" << std::endl;
            return false;
        }
        
        std::string line;
        std::map<std::string, unsigned long*> fields = {
            {"MemTotal:", &mem_info.total},
            {"MemFree:", &mem_info.free},
            {"MemAvailable:", &mem_info.available},
            {"Buffers:", &mem_info.buffers},
            {"Cached:", &mem_info.cached},
            {"SwapTotal:", &mem_info.swap_total},
            {"SwapFree:", &mem_info.swap_free},
            {"SwapCached:", &mem_info.swap_cached}
        };
        
        while (std::getline(meminfo, line)) {
            for (auto& field : fields) {
                if (line.find(field.first) == 0) {
                    std::string value_str = line.substr(field.first.length());
                    // Remove "kB" suffix and whitespace
                    value_str.erase(
                        std::remove_if(value_str.begin(), value_str.end(),
                                     [](char c) { return !std::isdigit(c); }),
                        value_str.end()
                    );
                    *(field.second) = std::stoul(value_str);
                    break;
                }
            }
        }
        
        meminfo.close();
        return true;
    }
    
    // Format bytes to human-readable
    std::string format_bytes(unsigned long kb) {
        double mb = kb / 1024.0;
        double gb = mb / 1024.0;
        
        if (gb >= 1.0) {
            return std::to_string(static_cast<int>(gb)) + " GB";
        } else if (mb >= 1.0) {
            return std::to_string(static_cast<int>(mb)) + " MB";
        } else {
            return std::to_string(kb) + " KB";
        }
    }
    
    // Drop page cache
    bool drop_page_cache() {
        std::ofstream drop_caches("/proc/sys/vm/drop_caches");
        if (!drop_caches.is_open()) {
            std::cerr << "Error: Cannot write to /proc/sys/vm/drop_caches" << std::endl;
            std::cerr << "Try running with sudo" << std::endl;
            return false;
        }
        
        drop_caches << "3" << std::endl;
        drop_caches.close();
        sync(); // Ensure all data is written to disk
        
        return true;
    }
    
    // Compact memory
    bool compact_memory() {
        std::ofstream compact("/proc/sys/vm/compact_memory");
        if (!compact.is_open()) {
            if (verbose) {
                std::cerr << "Warning: Cannot access /proc/sys/vm/compact_memory" << std::endl;
            }
            return false;
        }
        
        compact << "1" << std::endl;
        compact.close();
        
        return true;
    }
    
    // Tune swappiness
    bool tune_swappiness(int value) {
        std::ofstream swappiness("/proc/sys/vm/swappiness");
        if (!swappiness.is_open()) {
            std::cerr << "Error: Cannot write to /proc/sys/vm/swappiness" << std::endl;
            return false;
        }
        
        swappiness << value << std::endl;
        swappiness.close();
        
        return true;
    }
    
    // Get current swappiness
    int get_swappiness() {
        std::ifstream swappiness("/proc/sys/vm/swappiness");
        if (!swappiness.is_open()) {
            return -1;
        }
        
        int value;
        swappiness >> value;
        swappiness.close();
        
        return value;
    }
    
    // Calculate memory pressure
    double calculate_memory_pressure() {
        unsigned long used = mem_info.total - mem_info.available;
        return (static_cast<double>(used) / mem_info.total) * 100.0;
    }
    
public:
    MemoryOptimizer(bool v = false) : verbose(v) {
        memset(&mem_info, 0, sizeof(MemoryInfo));
    }
    
    void print_banner() {
        std::cout << "\033[1;36m"
                  << "╔═══════════════════════════════════════════════╗\n"
                  << "║   SentinelX Memory Optimizer v" << VERSION << "          ║\n"
                  << "║   Advanced Memory Management Tool            ║\n"
                  << "╚═══════════════════════════════════════════════╝\n"
                  << "\033[0m" << std::endl;
    }
    
    void display_memory_info() {
        if (!read_meminfo()) {
            return;
        }
        
        std::cout << "\033[1m━━━ Memory Information ━━━\033[0m\n" << std::endl;
        
        std::cout << "Total Memory:     " << format_bytes(mem_info.total) << std::endl;
        std::cout << "Available Memory: " << format_bytes(mem_info.available) << std::endl;
        std::cout << "Free Memory:      " << format_bytes(mem_info.free) << std::endl;
        std::cout << "Buffers:          " << format_bytes(mem_info.buffers) << std::endl;
        std::cout << "Cached:           " << format_bytes(mem_info.cached) << std::endl;
        
        unsigned long used = mem_info.total - mem_info.available;
        double usage_percent = (static_cast<double>(used) / mem_info.total) * 100.0;
        
        std::cout << "\nMemory Usage:     " << format_bytes(used) 
                  << " (" << static_cast<int>(usage_percent) << "%)" << std::endl;
        
        if (mem_info.swap_total > 0) {
            std::cout << "\n\033[1m━━━ Swap Information ━━━\033[0m\n" << std::endl;
            std::cout << "Total Swap:       " << format_bytes(mem_info.swap_total) << std::endl;
            std::cout << "Free Swap:        " << format_bytes(mem_info.swap_free) << std::endl;
            std::cout << "Swap Cached:      " << format_bytes(mem_info.swap_cached) << std::endl;
            
            unsigned long swap_used = mem_info.swap_total - mem_info.swap_free;
            double swap_percent = (static_cast<double>(swap_used) / mem_info.swap_total) * 100.0;
            std::cout << "Swap Usage:       " << format_bytes(swap_used) 
                      << " (" << static_cast<int>(swap_percent) << "%)" << std::endl;
        }
        
        std::cout << "\n\033[1m━━━ System Tuning ━━━\033[0m\n" << std::endl;
        int swappiness = get_swappiness();
        if (swappiness >= 0) {
            std::cout << "Current Swappiness: " << swappiness << std::endl;
        }
        
        std::cout << std::endl;
    }
    
    bool optimize(bool aggressive = false) {
        std::cout << "\033[1;33m⚡ Starting memory optimization...\033[0m\n" << std::endl;
        
        // Read initial state
        if (!read_meminfo()) {
            return false;
        }
        
        unsigned long initial_available = mem_info.available;
        
        std::cout << "Step 1: Syncing filesystem..." << std::endl;
        sync();
        
        std::cout << "Step 2: Dropping page cache..." << std::endl;
        if (!drop_page_cache()) {
            return false;
        }
        
        sleep(1); // Wait for cache to be dropped
        
        if (aggressive) {
            std::cout << "Step 3: Compacting memory..." << std::endl;
            compact_memory();
            sleep(1);
        }
        
        // Read final state
        read_meminfo();
        unsigned long final_available = mem_info.available;
        
        long freed = final_available - initial_available;
        
        std::cout << "\n\033[1;32m✓ Optimization complete!\033[0m" << std::endl;
        std::cout << "Memory freed: " << format_bytes(std::abs(freed)) << std::endl;
        std::cout << "Available now: " << format_bytes(final_available) << std::endl;
        
        return true;
    }
    
    bool tune_for_gaming() {
        std::cout << "\033[1;33m🎮 Tuning for gaming performance...\033[0m\n" << std::endl;
        
        // Lower swappiness for gaming (less swapping, more responsiveness)
        std::cout << "Setting swappiness to 10..." << std::endl;
        if (!tune_swappiness(10)) {
            return false;
        }
        
        // Drop caches for more available RAM
        std::cout << "Freeing cached memory..." << std::endl;
        if (!drop_page_cache()) {
            return false;
        }
        
        std::cout << "\n\033[1;32m✓ Gaming mode activated!\033[0m" << std::endl;
        std::cout << "System optimized for low latency and high responsiveness" << std::endl;
        
        return true;
    }
    
    bool tune_for_desktop() {
        std::cout << "\033[1;33m🖥️  Tuning for desktop usage...\033[0m\n" << std::endl;
        
        // Moderate swappiness for desktop
        std::cout << "Setting swappiness to 60..." << std::endl;
        if (!tune_swappiness(60)) {
            return false;
        }
        
        std::cout << "\n\033[1;32m✓ Desktop mode activated!\033[0m" << std::endl;
        std::cout << "System balanced for general use" << std::endl;
        
        return true;
    }
    
    void monitor(int interval = 5) {
        std::cout << "\033[1;36m📊 Starting memory monitor (Ctrl+C to stop)...\033[0m\n" << std::endl;
        
        while (true) {
            system("clear");
            print_banner();
            display_memory_info();
            
            double pressure = calculate_memory_pressure();
            std::cout << "\033[1mMemory Pressure: ";
            
            if (pressure > 90) {
                std::cout << "\033[1;31mCRITICAL (" << static_cast<int>(pressure) << "%)";
            } else if (pressure > 75) {
                std::cout << "\033[1;33mHIGH (" << static_cast<int>(pressure) << "%)";
            } else if (pressure > 50) {
                std::cout << "\033[1;33mMODERATE (" << static_cast<int>(pressure) << "%)";
            } else {
                std::cout << "\033[1;32mNORMAL (" << static_cast<int>(pressure) << "%)";
            }
            std::cout << "\033[0m\n" << std::endl;
            
            std::cout << "Next update in " << interval << " seconds..." << std::endl;
            sleep(interval);
        }
    }
};

void print_usage(const char* program) {
    std::cout << "Usage: " << program << " [OPTIONS]\n\n"
              << "Options:\n"
              << "  -h, --help        Show this help message\n"
              << "  -v, --version     Show version information\n"
              << "  -i, --info        Display memory information\n"
              << "  -o, --optimize    Optimize memory (drop caches)\n"
              << "  -a, --aggressive  Aggressive optimization (drop caches + compact)\n"
              << "  -g, --gaming      Tune for gaming performance\n"
              << "  -d, --desktop     Tune for desktop usage\n"
              << "  -m, --monitor     Monitor memory in real-time\n"
              << "  --verbose         Verbose output\n"
              << "\nExamples:\n"
              << "  sudo " << program << " --optimize\n"
              << "  sudo " << program << " --gaming\n"
              << "  " << program << " --info\n"
              << std::endl;
}

int main(int argc, char* argv[]) {
    bool verbose = false;
    
    // Check for root privileges for optimization operations
    if (getuid() != 0 && argc > 1) {
        std::string arg = argv[1];
        if (arg != "-h" && arg != "--help" && 
            arg != "-i" && arg != "--info" &&
            arg != "-m" && arg != "--monitor" &&
            arg != "-v" && arg != "--version") {
            std::cerr << "\033[1;31mError: This operation requires root privileges\033[0m" << std::endl;
            std::cerr << "Try: sudo " << argv[0] << " " << argv[1] << std::endl;
            return 1;
        }
    }
    
    MemoryOptimizer optimizer(verbose);
    
    if (argc < 2) {
        optimizer.print_banner();
        print_usage(argv[0]);
        return 1;
    }
    
    std::string arg = argv[1];
    
    if (arg == "-h" || arg == "--help") {
        optimizer.print_banner();
        print_usage(argv[0]);
        return 0;
    }
    else if (arg == "-v" || arg == "--version") {
        std::cout << "sx-memopt version " << VERSION << std::endl;
        return 0;
    }
    else if (arg == "-i" || arg == "--info") {
        optimizer.print_banner();
        optimizer.display_memory_info();
        return 0;
    }
    else if (arg == "-o" || arg == "--optimize") {
        optimizer.print_banner();
        return optimizer.optimize(false) ? 0 : 1;
    }
    else if (arg == "-a" || arg == "--aggressive") {
        optimizer.print_banner();
        return optimizer.optimize(true) ? 0 : 1;
    }
    else if (arg == "-g" || arg == "--gaming") {
        optimizer.print_banner();
        return optimizer.tune_for_gaming() ? 0 : 1;
    }
    else if (arg == "-d" || arg == "--desktop") {
        optimizer.print_banner();
        return optimizer.tune_for_desktop() ? 0 : 1;
    }
    else if (arg == "-m" || arg == "--monitor") {
        optimizer.monitor(5);
        return 0;
    }
    else if (arg == "--verbose") {
        verbose = true;
        optimizer = MemoryOptimizer(true);
    }
    else {
        std::cerr << "Unknown option: " << arg << std::endl;
        print_usage(argv[0]);
        return 1;
    }
    
    return 0;
}
