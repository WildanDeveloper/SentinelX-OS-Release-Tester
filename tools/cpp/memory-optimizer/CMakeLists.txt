cmake_minimum_required(VERSION 3.10)
project(sx-memopt VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Compiler flags
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -Wextra -O3")
set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} -g -O0")
set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} -O3 -march=native")

# Source files
set(SOURCES
    sx-memopt.cpp
)

# Executable
add_executable(sx-memopt ${SOURCES})

# Installation
install(TARGETS sx-memopt
        RUNTIME DESTINATION /usr/local/bin
        PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE
                    GROUP_READ GROUP_EXECUTE
                    WORLD_READ WORLD_EXECUTE)

# Manual page (optional)
install(FILES sx-memopt.1
        DESTINATION /usr/local/share/man/man1
        OPTIONAL)

# Build instructions
message(STATUS "SentinelX Memory Optimizer")
message(STATUS "Build type: ${CMAKE_BUILD_TYPE}")
message(STATUS "CXX Flags: ${CMAKE_CXX_FLAGS}")
