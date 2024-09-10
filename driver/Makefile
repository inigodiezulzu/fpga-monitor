obj-m += mmonitor.o
mmonitor-objs := monitor.o

module:
	make -C $(KDIR) M=$(PWD) modules

install: module
	cp mmonitor.ko $(PREFIX)

clean:
	make -C $(KDIR) M=$(PWD) clean
