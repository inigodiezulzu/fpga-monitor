#
# Monitor Runtime Library
#
# Author   : Juan Encinas Anchústegui <juan.encinas@upm.es>
# Date     : February 2021
#
# Notes:
#     - This Makefile requires the following environment variables to
#       be previously set (by the user, or the ARTICo3 toolchain):
#       CROSS_COMPILE
#
#       CROSS_COMPILE = /opt/Xilinx/SDK/<version>/gnu/aarch32/lin/gcc-arm-linux-gnueabi/bin/arm-linux-gnueabihf-
#       CROSS_COMPILE = /opt/Xilinx/SDK/<version>/gnu/aarch64/lin/aarch64-linux/bin/aarch64-linux-gnu-
#

CC = $(CROSS_COMPILE)gcc
AR = $(CROSS_COMPILE)ar

CFLAGS = -Wall -Wextra -O3 -fpic -I ../../linux
LDFLAGS = -Wl,-R,. -shared -lpthread

OBJS = monitor_hw.o monitor.o

ZYNQ_OBJS = $(OBJS:%=aarch32/_build/%)
ZYNQMP_OBJS = $(OBJS:%=aarch64/_build/%)
AU250_OBJS = $(OBJS_AU250:%=x86/_build/%)

MKDIRP = mkdir -p
CPF = cp -f

.PHONY: zynq
zynq: $(ZYNQ_OBJS)
	$(CC) $(LDFLAGS) $^  -o aarch32/monitor.so
	$(AR) rcs aarch32/libmonitor.a $^
	$(MKDIRP) aarch32/include
	$(CPF) monitor.h aarch32/include

.PHONY: zynqmp
zynqmp: $(ZYNQMP_OBJS)
	$(CC) $(LDFLAGS) $^ $(LDLIBS) -o aarch64/monitor.so
	$(AR) rcs aarch64/libmonitor.a $^
	$(MKDIRP) aarch64/include
	$(CPF) monitor.h aarch64/include

.PHONY: xcu250
xcu250: $(ZYNQMP_OBJS)
	$(CC) $(LDFLAGS) $^ $(LDLIBS) -o x86/monitor.so
	$(AR) rcs x86/libmonitor.a $^
	$(MKDIRP) x86/include
	$(CPF) monitor.h x86/include

.PHONY: clean
clean:
	rm -rf aarch32 aarch64 x86

aarch32/_build/%.o: %.c
	$(MKDIRP) $(@D)
	$(CC) $(CFLAGS) -c $< -o $@

aarch64/_build/%.o: %.c
	$(MKDIRP) $(@D)
	$(CC) -DZYNQMP $(CFLAGS) -c $< -o $@

x86/_build/%.o: %.c
	$(MKDIRP) $(@D)
	$(CC) -DAU250 $(CFLAGS) -c $< -o $@