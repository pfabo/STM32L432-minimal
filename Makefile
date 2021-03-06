########################################################################
# make        - compile and build firmware
# make clean  - clean directory  
# make flash  - write firmware to target MCU
#
# 200119  pf  - ver. 1.0  
#
# Note:
# Copy ./STM32Cube_FW_L4_V1.14.0/Drivers to local ./Drivers
########################################################################

# put your *.o targets here, make should handle the rest!

SRCS = system_stm32l4xx.c main.c 
OBJ = $(SRCS:.c=.o)

# all the files will be generated with this name (main.elf, main.bin, main.hex, etc)
PROJ_NAME=project

# Location of the Libraries folder
LL_LIB=Drivers

# Location of the linker scripts
LDSCRIPT_INC=Device/ldscripts

# MCU Type
MCU_TYPE=STM32L432xx

# Startup file for MCU from CMSIS library 
STARTUP=./Drivers/CMSIS/Device/ST/STM32L4xx/Source/Templates/gcc/startup_stm32l432xx.s

# that's it, no need to change anything below this line!
########################################################################

CC=arm-none-eabi-gcc
OBJCOPY=arm-none-eabi-objcopy
OBJDUMP=arm-none-eabi-objdump
SIZE=arm-none-eabi-size

CFLAGS  = -Wall -g -std=gnu99 -Os
CFLAGS += -D$(MCU_TYPE) -DUSE_FULL_LL_DRIVER 
CFLAGS += -mlittle-endian -mcpu=cortex-m3  -mthumb
CFLAGS += -ffunction-sections -fdata-sections
CFLAGS += -Wl,--gc-sections -Wl,-Map=$(PROJ_NAME).map
CFLAGS += -Werror -Wstrict-prototypes -Warray-bounds -fno-strict-aliasing -Wno-unused-const-variable
CFLAGS += -mfloat-abi=soft -specs=nano.specs -specs=nosys.specs
#-Wextra
########################################################################

vpath %.c src
vpath %.a .

ROOT=$(shell pwd)

CFLAGS += -I $(LL_LIB) -I $(LL_LIB)/CMSIS/Device/ST/STM32L4xx/Include
CFLAGS += -I $(LL_LIB)/CMSIS/Include -I $(LL_LIB)/STM32L4xx_HAL_Driver/Inc -I src
CFLAGS += -I./src

SRCS += $(STARTUP) # add startup file to build

OBJS = $(SRCS:.c=.o)

########################################################################

.PHONY: lib proj

all: proj

proj: 	$(PROJ_NAME).elf

%.o: %.c
	$(CC) $(CFLAGS) -c -o src/$@ $<

$(PROJ_NAME).elf: $(SRCS)
	$(CC) $(CFLAGS) $^ -o $@ -L$(LL_LIB) -lll -L$(LDSCRIPT_INC) -lm -Tstm32l4xx.ld
	$(OBJCOPY) -O ihex $(PROJ_NAME).elf $(PROJ_NAME).hex
	$(OBJCOPY) -O binary $(PROJ_NAME).elf $(PROJ_NAME).bin
	$(OBJDUMP) -St $(PROJ_NAME).elf >$(PROJ_NAME).lst
	$(SIZE) -A $(PROJ_NAME).elf
		
clean:
	find ./ -name '*~' | xargs rm -f	
	rm -f *.o
	rm -f src/*.o 
	rm -f $(PROJ_NAME).elf
	rm -f $(PROJ_NAME).hex
	rm -f $(PROJ_NAME).bin
	rm -f $(PROJ_NAME).map
	rm -f $(PROJ_NAME).lst

flash:
	st-flash write $(PROJ_NAME).bin 0x8000000
