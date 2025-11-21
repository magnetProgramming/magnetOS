NASM    = nasm
QEMU    = qemu-system-i386

SRC_BOOT   = src/boot/boot.asm
SRC_KERNEL = src/kernel/kernel.asm

BIN_DIR    = bin
BOOT_BIN   = $(BIN_DIR)/boot.bin
KERNEL_BIN = $(BIN_DIR)/kernel.bin
DISK_IMG   = $(BIN_DIR)/disk.img

all: $(DISK_IMG)

$(BOOT_BIN): $(SRC_BOOT)
	@mkdir -p $(BIN_DIR)
	$(NASM) -f bin $(SRC_BOOT) -o $(BOOT_BIN)

$(KERNEL_BIN): $(SRC_KERNEL)
	@mkdir -p $(BIN_DIR)
	$(NASM) -f bin $(SRC_KERNEL) -o $(KERNEL_BIN)
	# pad or shrink kernel to exactly 32 sectors (16384 bytes)
	truncate -s 16384 $(KERNEL_BIN)

$(DISK_IMG): $(BOOT_BIN) $(KERNEL_BIN)
	# create disk by concatenating boot + kernel
	cat $(BOOT_BIN) $(KERNEL_BIN) > $(DISK_IMG)

run: $(DISK_IMG)
	$(QEMU) -drive file=$(DISK_IMG),format=raw -no-reboot -no-shutdown

clean:
	rm -f $(BIN_DIR)/*.bin
	rm -f $(DISK_IMG)

.PHONY: all run clean
