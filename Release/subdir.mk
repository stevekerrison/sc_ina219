################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
XC_SRCS += \
../ina219.xc 

OBJS += \
./ina219.o 

XC_DEPS += \
./ina219.d 


# Each subdirectory must supply rules for building sources it contributes
%.o: ../%.xc
	@echo 'Building file: $<'
	@echo 'Invoking: XC Compiler'
	xcc -I"/home/steve/xmos-workspace/iic-steve" -O2 -g -Wall -c -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@:%.o=%.d) $@ " -o $@ "$<"
	@echo 'Finished building: $<'
	@echo ' '

libina219.a: ./ina219.o $(USER_OBJS)
	@echo 'Building file: $<'
	@echo 'Invoking: Archiver'
	xmosar -r lib$@ "$<" $(USER_OBJS) $(LIBS)
	@echo 'Finished building: $<'
	@echo ' '


