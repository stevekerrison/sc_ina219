/*
 * ina219.h
 *
 *  Created on: Oct 6, 2010
 *      Author: Steve Kerrison
 * Description: Interact with TI INA219 current/power sensor
 */

#ifndef INA219_H_
#define INA219_H_

#include <platform.h>
#include "iic.h"

//Register addresses
#define INA219_REG_CONFIG	0x0
#define INA219_REG_SHUNTV	0x1
#define INA219_REG_BUSV		0x2
#define INA219_REG_POWER	0x3
#define INA219_REG_CURRENT	0x4
#define INA219_REG_CALIB	0x5

//Macros for assigning config bits
#define INA219_CFGB_RESET(x)		((x & 0x1) << 15)
#define INA219_CFGB_BUSV_RANGE(x)	((x & 0x1) << 13)
#define INA219_CFGB_PGA_RANGE(x)	((x & 0x3) << 11)
#define INA219_CFGB_BADC_RES_AVG(x)	((x & 0xF) << 7)
#define INA219_CFGB_SADC_RES_AVG(x) ((x & 0xF) << 3)
#define INA219_CFGB_OPMODE(x)		(x & 0x7)

//Config bit values
#define INA219_CFG_RESET			1	//Power on reset equivalent
#define INA219_CFG_BUSV_RANGE_32	1
#define INA219_CFG_BUSV_RANGE_16	0
#define INA219_CFG_PGA_RANGE_40		0
#define INA219_CFG_PGA_RANGE_80		1
#define INA219_CFG_PGA_RANGE_160	2
#define INA219_CFG_PGA_RANGE_320	3
#define INA219_CFG_ADC_RES_9		0
#define INA219_CFG_ADC_RES_10		1
#define INA219_CFG_ADC_RES_11		2
#define INA219_CFG_ADC_RES_12		3
#define INA219_CFG_ADC_AVG_2		0x9
#define INA219_CFG_ADC_AVG_4		0xa
#define INA219_CFG_ADC_AVG_8		0xb
#define INA219_CFG_ADC_AVG_16		0xc
#define INA219_CFG_ADC_AVG_32		0xd
#define INA219_CFG_ADC_AVG_64		0xe
#define INA219_CFG_ADC_AVG_128		0xf
#define INA219_CFG_OPMODE_POWDN		0
#define INA219_CFG_OPMODE_SV_TG		1
#define INA219_CFG_OPMODE_BV_TG		2
#define INA219_CFG_OPMODE_SCBV_TG	3
#define INA219_CFG_OPMODE_OFF		4
#define INA219_CFG_OPMODE_SV_CT		5
#define INA219_CFG_OPMODE_BV_CT		6
#define INA219_CFG_OPMODE_SCBV_CT	7

//Timing constraints for reading power/current calculations for 100MHz timers
#define INA219_CVT_TIMES	{8400,	\
							14800,	\
							27600,	\
							53200,	\
							8400,	\
							14800,	\
							27600,	\
							53200,	\
							53200,	\
							106000,	\
							213000,	\
							426000,	\
							851000,	\
							1702000,\
							3405000,\
							6810000	}	//68.1mS

//Macro to verify an address is within the valid register range
#define INA219_VALID_REG(a)	(a >= INA219_REG_CONFIG && a <= INA219_REG_CALIB)

typedef struct INA219_t {
	int addr; //IIC slave address
	int cal; //Calibration value
	int cur_lsb; //Current_LSB
	int pow_lsb; //Power LSB
	char calibd; //Has been calibrated
	int config; //Cache of config bits.
	uint accesstime; //When we can next expect to be able to read from the power/current registers
} INA219_t;

/**
 * Initialise an INA219
 * @param INA219_t &ina219 Somewhere for us to store some data on the configured INA219
 * @param timer t The timer used to track when ADC conversions are ready.
 * @param port iic_scl IIC clock port
 * @param port iic_sda IIC data port
 * @param int iic_ina219_address Slave address of INA219
 * @return XMOS_RTN_t XMOS_SUCCESS or XMOS_FAIL
 */
XMOS_RTN_t ina219_init(INA219_t &ina219, timer t, port iic_scl, port iic_sda, int iic_ina219_address);

/**
 * Configure the INA219 voltage ranges and resolutions, as per the datasheet
 * @param INA219_t &ina219 The INA219 to configure
 * @param timer t The timer used to track when ADC conversions are ready.
 * @param port iic_scl IIC clock port
 * @param port iic_sda IIC data port
 * @param int Data to poke into the configuration register
 * @return XMOS_RTN_t XMOS_SUCCESS or XMOS_FAIL
 */
XMOS_RTN_t ina219_config(INA219_t &ina219, timer t, port iic_scl, port iic_sda, int config);

/**
 * Set the calibration ragister of an INA219
 * @param INA219_t &ina219 The INA219 to calibrate
 * @param timer t The timer used to track when ADC conversions are ready.
 * @param port iic_scl IIC clock port
 * @param port iic_sda IIC data port
 * @param int calibration_value The 16-bit calibration value
 * @param int cur_lsb The magnitude of the LSB in the current register
 * @param int pow_usb The magnitude of the LSB in the power register
 * @return XMOS_RTN_t XMOS_SUCCESS or XMOS_FAIL
 */
XMOS_RTN_t ina219_calibrate(INA219_t &ina219, timer t, port iic_scl, port iic_sda, int calibration_value, int cur_lsb, int pow_lsb);

/**
 * Automatically calculate the required calibration value.
 *
 * Limited by lack of FP calculations, works for the usage scenario I needed
 * but it may or may not produce ideal values for other configurations.
 *
 * @param INA219_t &ina219 The INA219 to calibrate
 * @param timer t The timer used to track when ADC conversions are ready.
 * @param port iic_scl IIC clock port
 * @param port iic_sda IIC data port
 * @param int iMax_uA The maximum expected current of the load in micro-Amps.
 * @param int rShunt_mR The value of the shunt resistor in milli-Ohms.
 * @param int program If != 0 then the calibration value will be written to the IN219
 * @return int The calculated calibration value, 0 on constraint failure.
 */
int ina219_auto_calibrate(INA219_t &ina219, timer t, port iic_scl, port iic_sda, int iMax_uA, int rShunt_mR, int program);

/**
 * Read a register of an INA219
 * @param INA219_t &ina219 The INA219 to read.
 * @param port iic_scl IIC clock port
 * @param port iic_sda IIC data port
 * @param int reg The register address to read.
 * @param int data Reference into which we will put data (16-bit, zerofilled).
 * @return XMOS_RTN_t XMOS_SUCCESS or XMOS_FAIL
 */
XMOS_RTN_t ina219_read_reg(INA219_t &ina219, port iic_scl, port iic_sda, int reg, int &data);

/**
 * Get the bus voltage in milliVolts
 * @param INA219_t &ina219 The INA219 to read.
 * @param port iic_scl IIC clock port
 * @param port iic_sda IIC data port
 * @return uint The bus voltage (mV)
 */
uint ina219_bus_mV(INA219_t &ina219, port iic_scl, port iic_sda);

/**
 * Get the shunt voltage in microVolts
 *
 * Note that this is MICRO not milli as used with ina219_bus_mV()
 *
 * @param INA219_t &ina219 The INA219 to read.
 * @param port iic_scl IIC clock port
 * @param port iic_sda IIC data port
 * @return int The shunt voltage (uV)
 */
int ina219_shunt_uV(INA219_t &ina219, port iic_scl, port iic_sda);

/**
 * Get the power in microWatts
 *
 * Note that this is MICRO not milli as used with ina219_bus_mV()
 *
 * @param INA219_t &ina219 The INA219 to read.
 * @param port iic_scl IIC clock port
 * @param port iic_sda IIC data port
 * @return uint The power (uW)
 */
uint ina219_power_uW(INA219_t &ina219, timer t, port iic_scl, port iic_sda);

/**
 * Get the current in microAmps
 *
 * Note that this is MICRO not milli as used with ina219_bus_mV()
 *
 * @param INA219_t &ina219 The INA219 to read.
 * @param port iic_scl IIC clock port
 * @param port iic_sda IIC data port
 * @return int The shunt current (uA)
 */
int ina219_current_uA(INA219_t &ina219, timer t, port iic_scl, port iic_sda);


#endif /* INA219_H_ */
