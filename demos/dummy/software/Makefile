#
# Monitor Linux Application
#
# Author   : Juan Encinas <juan.encinas@upm.es>
# Date     : November 2024
#

CFLAGS_IN = -O3 
LDFLAGS_IN = -static 

CC = $(CROSS_COMPILE)gcc
MAKE = make

CFLAGS_MONITOR = $(CFLAGS_IN)-Wall -Wextra -fpic -I ../../../linux
LDFLAGS_MONITOR = -Wl,-R,. -shared
LDLIBS_MONITOR = -lm

CFLAGS_APP = $(CFLAGS_IN)-Wall -Wextra -I monitor -O3
LDFLAGS_APP = $(LDFLAGS_IN)-L . -Wl,-R,.
LDLIBS_APP = -lmonitor

# Monitor related parameters
OBJS1 = monitor/monitor_hw.o monitor/monitor.o
MONITOR_OBJS = $(OBJS1:%=_build/%)

OBJS2 = application/main.o
APP_OBJS = $(OBJS2:%=_build/%)

MKDIRP = mkdir -p
CPF = cp -f

.PHONY: app
app: monitor $(APP_OBJS)
	$(CC) $(LDFLAGS_APP) $(APP_OBJS) $(LDLIBS_APP) -o main

# Generate monitor lib
.PHONY: monitor
monitor: $(MONITOR_OBJS)
	$(CC) $(LDFLAGS_MONITOR) $^ $(LDLIBS_MONITOR) -o libmonitor.so
	$(AR) rcs libmonitor.a $^

.PHONY: clean
clean:
	rm -rf _build libmonitor.so libmonitor.a main

_build/monitor/%.o: monitor/%.c
	$(MKDIRP) $(@D)
	$(CC) $(CFLAGS_MONITOR) -c $< -o $@

_build/application/%.o: application/%.c
	$(MKDIRP) $(@D)
	$(CC) $(CFLAGS_APP) -x c -c $< -o $@

_build/application/%.o: application/%.cpp
	$(MKDIRP) $(@D)
	$(CC) $(CFLAGS_APP) -x c -c $< -o $@
