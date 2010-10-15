################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
XC_SRCS += \
../ina219.xc 

XN_SRCS += \
../XK-1.xn 

OBJS += \
./ina219.o 


# Each subdirectory must supply rules for building sources it contributes
libXK-1.a: ../XK-1.xn $(USER_OBJS)
	@echo 'Building file: $<'
	@echo 'Invoking: Archiver'
	xmosar -r lib"$@" "$<" $(USER_OBJS) $(LIBS) "../XK-1.xn"
	@echo 'Finished building: $<'
	@echo ' '

%.o: ../%.xc
	@echo 'Building file: $<'
	@echo 'Invoking: XC Compiler'
	xcc -I"/Users/admin/phys_steve/workspace/iic-steve" -O2 -g -Wall -c -o "$@" "$<" "../XK-1.xn"
	@echo 'Finished building: $<'
	@echo ' '

libina219.a: ./ina219.o $(USER_OBJS)
	@echo 'Building file: $<'
	@echo 'Invoking: Archiver'
	xmosar -r lib"$@" "$<" $(USER_OBJS) $(LIBS) "../XK-1.xn"
	@echo 'Finished building: $<'
	@echo ' '


