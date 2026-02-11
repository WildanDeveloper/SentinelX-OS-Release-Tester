# Simple Makefile for sx-memopt

CXX = g++
CXXFLAGS = -std=c++17 -Wall -Wextra -O3 -march=native
TARGET = sx-memopt
SOURCE = sx-memopt.cpp

all: $(TARGET)

$(TARGET): $(SOURCE)
	$(CXX) $(CXXFLAGS) -o $(TARGET) $(SOURCE)

clean:
	rm -f $(TARGET)

install: $(TARGET)
	install -m 755 $(TARGET) /usr/local/bin/

uninstall:
	rm -f /usr/local/bin/$(TARGET)

.PHONY: all clean install uninstall
