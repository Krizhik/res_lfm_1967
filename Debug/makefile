################################################################################
# Automatically-generated file. Do not edit!
################################################################################

-include ../makefile.init

RM := "C:\Milandr\CM-LYNX.2.02.00\toolchain\Bin\rm" -rf

# All of the sources participating in the build are defined here
-include sources.mk
-include subdir.mk
-include objects.mk

-include ../makefile.defs

# Add inputs and outputs from these tool invocations to the build variables 

# All Target
all: $(TARGETS)

# Tool target
$(TARGETS): target-build

# Tool invocations
target-build: $(OBJS) $(USER_OBJS)
	@echo 'Building target: $@'
	@echo 'Invoking: Linker'
	"C:\Milandr\CM-LYNX.2.02.00\toolchain\\Bin\\mclink-tsh" -Map "res_lfm.map" -xref "res_lfm.xref" --double-size-64 --char-size-32 clib.dlb libcxx.dlb libcxxabi.dlb libunwind.dlb -L "C:\Milandr\CM-LYNX.2.02.00\toolchain\LibLLVM" -MD __1967VN028R2__ -MM -Mo link.deps -od . -T ../project.ldf -i "C:\Milandr\CM-LYNX.2.02.00\toolchain\Inc" -o  "res_lfm.dxe" $(OBJS__)
	@echo 'Finished building target: $@'
	@echo ' '

# Other Targets
clean:
	-$(RM) $(ASM_OBJS__)$(ASM_OBJS)$(OBJS)$(OBJS__) $(TARGETS__) *.dxe *.is *.dmp *.xml *.dep *.deps *.map *.lst *.src *.i
	-@echo ' '

.PHONY: all clean dependents
.SECONDARY:

-include ../makefile.targets
