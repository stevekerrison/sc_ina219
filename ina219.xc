/*
 * ina219.xc
 *
 *  Created on: Oct 6, 2010
 *      Author: Steve Kerrison
 * Description: Interact with TI INA219 current/power sensor
 */

#include "ina219.h"
#include <stdlib.h>
#include <stdio.h>

//Work out the next time a conversion /should/ be ready (private)
void ina219_accesstime(INA219_t &ina219, timer t);

XMOS_RTN_t ina219_init(INA219_t &ina219, timer t, port iic_scl, port iic_sda,
		int iic_ina219_address) {
	ina219.addr = iic_ina219_address;
	ina219.cal = 0;
	ina219.calibd = 0;
	ina219.config = 0x399F;	//This happens to be the default config
	ina219_accesstime(ina219,t);
	return iic_initialise(iic_scl, iic_sda);
}

XMOS_RTN_t ina219_config(INA219_t &ina219, timer t, port iic_scl, port iic_sda, int config)
{
	char cd[3];
	int opchange = 0;
	int ret = XMOS_FAIL;
	cd[0] = INA219_REG_CONFIG;
	cd[1] = (config >> 8) & 0xFF;
	cd[2] = config & 0xFF;
	opchange = (ina219.config & 7) != (config & 7);
	ina219.config = config & 0xFFFF;
	ret = iic_write(iic_scl,iic_sda,ina219.addr,cd,3);
	return ret;
}



XMOS_RTN_t ina219_calibrate(INA219_t &ina219, timer t, port iic_scl, port iic_sda,
		int calibration_value, int cur_lsb, int pow_lsb) {
	char cd[3];
	int ret = XMOS_FAIL;
	cd[0] = INA219_REG_CALIB;
	cd[1] = (calibration_value >> 8) & 0xFF;
	cd[2] = calibration_value & 0xFF;
	ina219.cal = calibration_value & 0xFFFF;
	ina219.cur_lsb = cur_lsb;
	ina219.pow_lsb = pow_lsb;
	ina219.calibd = iic_write(iic_scl, iic_sda, ina219.addr, cd, 3);
	ina219_accesstime(ina219,t);
	return ret;
}

int ina219_auto_calibrate(INA219_t &ina219, timer t, port iic_scl, port iic_sda,
		int iMax_uA, int rShunt_mR, int program) {
	//Adaptation of the calibration formulae as per INA219 datasheet.
	int min_lsb = iMax_uA / 32767;
	int max_lsb = iMax_uA / 4096;
	int current_lsb = (min_lsb & 1) ? min_lsb + 1 : min_lsb + 2;
	int cal = 0;
	/*int max_current = current_lsb * 32767;
	int max_current_bo = max_current >= iMax_uA ? iMax_uA : max_current;
	int max_shunt = max_current_bo / 10; //0.1R shunt
	int max_shunt_bo = max_shunt >= 3000000; //300mV*/
	if (current_lsb > min_lsb && current_lsb < max_lsb) {
		cal = 40960000 / (current_lsb * rShunt_mR);
		//printf("Calibration value: %u, current_lsb: %u*10^-6, power_lsb: %u*10^-6\n",cal, current_lsb, 20*current_lsb);
		if (program) {
			ina219_calibrate(ina219, t, iic_scl, iic_sda, cal, current_lsb, 20*current_lsb);
		}
	}
	return cal;
}

XMOS_RTN_t ina219_read_reg(INA219_t &ina219, port iic_scl, port iic_sda,
		int reg, int &data) {
	char regptr[1];
	char d[2];
	XMOS_RTN_t ret = XMOS_FAIL;
	if (INA219_VALID_REG(reg))
	{
		regptr[0] = reg;
		if (iic_write(iic_scl, iic_sda, ina219.addr, regptr, 1))
		{
			ret = iic_read(iic_scl, iic_sda, ina219.addr, d, 2);
			data = (d[0] << 8) | d[1];
		}
	}
	if (!ret)
	{
		printf("INA219: Error reading reg %u\n",reg);
	}
	return ret;
}

unsigned int ina219_bus_mV(INA219_t &ina219, port iic_scl, port iic_sda)
{
	int data = 0;
	while ((data & 2) != 2)
	{
		if (!ina219_read_reg(ina219,iic_scl,iic_sda,INA219_REG_BUSV,data))
		{
			return 0;
		}
	}
	return (data >> 1) & ~3;
}

int ina219_shunt_uV(INA219_t &ina219, port iic_scl, port iic_sda)
{
	int data = 0;
	if (ina219_read_reg(ina219,iic_scl,iic_sda,INA219_REG_SHUNTV,data))
	{
		if (data & 0x8000)
		{
			data |= 0xFFFF0000; //32-bit sign extend
		}
		return data*10;
	}
	return 0;
}

int ina219_current_uA(INA219_t &ina219, timer t, port iic_scl, port iic_sda)
{
	int data = 0;
	t when timerafter(ina219.accesstime) :> ina219.accesstime;
	while ((data & 2) != 2)
	{
		if (!ina219_read_reg(ina219,iic_scl,iic_sda,INA219_REG_BUSV,data))
		{
			return 0;
		}
	}
	if (ina219_read_reg(ina219,iic_scl,iic_sda,INA219_REG_CURRENT,data))
	{
		if (data & 0x8000)
		{
			data |= 0xFFFF0000; //32-bit sign extend
		}
		return data*ina219.cur_lsb;
	}
	return 0;
}

unsigned int ina219_power_uW(INA219_t &ina219, timer t, port iic_scl, port iic_sda)
{
	int data = 0;
	//t when timerafter(ina219.accesstime) :> void;// :> ina219.accesstime;
	while (0 && (data & 2) != 2)
	{
		if (!ina219_read_reg(ina219,iic_scl,iic_sda,INA219_REG_BUSV,data))
		{
			return 0;
		}
	}
	if (ina219_read_reg(ina219,iic_scl,iic_sda,INA219_REG_POWER,data))
	{
		ina219_accesstime(ina219,t);
		return data * ina219.pow_lsb;
	}
	return 0;
}

void ina219_accesstime(INA219_t &ina219, timer t)
{
	int badc = (ina219.config >> 7) & 0xF, sadc = (ina219.config >> 3) & 0xF;
	static int times[16] = INA219_CVT_TIMES;
	t :> ina219.accesstime;
	ina219.accesstime += (badc > sadc) ? times[badc] : times[sadc];
}
