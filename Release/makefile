################################################################################
# Automatically-generated file. Do not edit!
################################################################################

-include ../makefile.init

RM = rm -rf $(1)

# All of the sources participating in the build are defined here
-include sources.mk
-include subdir.mk
-include objects.mk

ifneq ($(MAKECMDGOALS),clean)
ifneq ($(strip $(C++_DEPS)),)
-include $(C++_DEPS)
endif
ifneq ($(strip $(C_DEPS)),)
-include $(C_DEPS)
endif
ifneq ($(strip $(CC_DEPS)),)
-include $(CC_DEPS)
endif
ifneq ($(strip $(CPP_DEPS)),)
-include $(CPP_DEPS)
endif
ifneq ($(strip $(CXX_DEPS)),)
-include $(CXX_DEPS)
endif
ifneq ($(strip $(C_UPPER_DEPS)),)
-include $(C_UPPER_DEPS)
endif
endif

-include ../makefile.defs

# Add inputs and outputs from these tool invocations to the build variables 

# All Target
all: libina219.a

# Tool invocations
libina219.a: $(OBJS) $(XN_SRCS) $(USER_OBJS)
	@echo 'Building target: $@'
	@echo 'Invoking: Archiver'
	xmosar -r "libina219.a" $(OBJS) $(USER_OBJS) $(LIBS) $(XN_SRCS)
	@echo 'Finished building target: $@'
	@echo ' '

# Other Targets
clean:
	-$(call RM, $(C++_DEPS)$(OBJS)$(C_DEPS)$(CC_DEPS)$(ARCHIVES)$(CPP_DEPS)$(CXX_DEPS)$(C_UPPER_DEPS) libina219.a)
	-@echo ' '

.PHONY: all clean dependents
.SECONDARY:

-include ../makefile.targets
