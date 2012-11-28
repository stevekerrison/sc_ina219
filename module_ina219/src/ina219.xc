/*
 * ina219.xc
 *
 *  Created on: Oct 6, 2010
 *      Author: Steve Kerrison <steve.kerrison@bristol.ac.uk>
 * Description: Interact with TI INA219 current/power sensor
 *
 * Copyright (C) 2012 Steve Kerrison <github@stevekerrison.com>
 *
 * This software is freely distributable under a derivative of the
 * University of Illinois/NCSA Open Source License posted in
 * LICENSE.txt and at <http://github.xcore.com/>
 */

#include "ina219.h"
#include <platform.h>
#include <xs1.h>
#include <stdlib.h>
#include <stdio.h>

//Work out the next time a conversion /should/ be ready (private)
void ina219_accesstime(INA219_t &ina219, timer t);

XMOS_RTN_t ina219_init(INA219_t &ina219, timer t, struct r_i2c &ports,
		int iic_ina219_address) {
	ina219.addr = iic_ina219_address;
	ina219.cal = 0;
	ina219.calibd = 0;
	ina219.config = 0x399F;	//This happens to be the default config
	t :> ina219.accesstime;
	ina219_accesstime(ina219,t);

    i2c_master_init(ports);
	return XMOS_SUCCESS;
}

XMOS_RTN_t ina219_write_reg(INA219_t &ina219, int reg, unsigned short data, struct r_i2c &ports)
{
	unsigned char d[2];

	d[0] = (data>>8)&0xFF;
	d[1] = data&0xFF;

    return i2c_master_write_reg(ina219.addr, reg, d, 2, ports);
}

XMOS_RTN_t ina219_config(INA219_t &ina219, timer t, struct r_i2c &ports, int config)
{
	ina219.config = config & 0xFFFF;
    return ina219_write_reg(ina219, INA219_REG_CONFIG, ina219.config, ports);
}



XMOS_RTN_t ina219_calibrate(INA219_t &ina219, timer t, struct r_i2c &ports,
		int calibration_value, int cur_lsb, int pow_lsb) 
{
	int ret;
	ina219.cal = calibration_value & 0xFFFF;
	ina219.cur_lsb = cur_lsb;
	ina219.pow_lsb = pow_lsb;
    ret = ina219_write_reg(ina219, INA219_REG_CALIB, ina219.cal, ports);
    ina219.calibd = ret;

	t :> ina219.accesstime;
	ina219_accesstime(ina219,t);

	return ina219.calibd;
}

int ina219_auto_calibrate(INA219_t &ina219, timer t, struct r_i2c &ports,
		int iMax_uA, int rShunt_mR, int program) 
{
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
			if(!ina219_calibrate(ina219, t, ports, cal, current_lsb, 20*current_lsb))
				printf("Calibration Error\n");
		}
	}
	return cal;
}

XMOS_RTN_t ina219_read_reg(INA219_t &ina219, struct r_i2c &ports,
		int reg, int &data) 
{
    char d[2] = {0,0};
	XMOS_RTN_t ret = XMOS_FAIL;

	if (INA219_VALID_REG(reg))
	{
        ret = i2c_master_read_reg(ina219.addr, reg, d, 2, ports);
		data = (d[0] << 8) | d[1];
	}
	if (!ret)
	{
		printf("INA219: Error reading reg %u\n",reg);
	}
	return ret;
}

unsigned int ina219_bus_mV(INA219_t &ina219, struct r_i2c &ports)
{
	int data = 0;
	while ((data & 2) != 2)
	{
		if (!ina219_read_reg(ina219,ports,INA219_REG_BUSV,data))
		{
			return 0;
		}
	}
	return (data >> 1) & ~3;
}

int ina219_shunt_uV(INA219_t &ina219, struct r_i2c &ports)
{
	int data = 0;
	if (ina219_read_reg(ina219,ports,INA219_REG_SHUNTV,data))
	{
		if (data & 0x8000)
		{
			data |= 0xFFFF0000; //32-bit sign extend
		}
		return data*10;
	}
	return 0;
}

int ina219_current_uA(INA219_t &ina219, timer t, struct r_i2c &ports)
{
	int data = 0;
	while ((data & 2) != 2)
	{
		if (!ina219_read_reg(ina219,ports,INA219_REG_BUSV,data))
		{
			return 0;
		}
	}
	if (ina219_read_reg(ina219,ports,INA219_REG_CURRENT,data))
	{
		if (data & 0x8000)
		{
			data |= 0xFFFF0000; //32-bit sign extend
		}
		return data*ina219.cur_lsb;
	}
	return 0;
}

unsigned int ina219_power_uW(INA219_t &ina219, timer t, struct r_i2c &ports)
{
	int data = 0;
	//t when timerafter(ina219.accesstime) :> void;// :> ina219.accesstime;
	/*while (!(data & 2))
	{
		if (!ina219_read_reg(ina219,ports,INA219_REG_BUSV,data))
		{
			return 0;
		}
		if (data & 1) //test overflow bit (system is usually calibrated not to overflow)
		{
			printf("INA219: WARNING - An overflow has occurred in power reading!\n");
		}
	}*/
	ina219_accesstime(ina219,t);
	if (ina219_read_reg(ina219,ports,INA219_REG_POWER,data))
	{
		return data * ina219.pow_lsb;
	}
	return 0;
}

void ina219_accesstime(INA219_t &ina219, timer t)
{
	static unsigned int times[16] = INA219_CVT_TIMES;
	int badc = (ina219.config >> 7) & 0xF, sadc = (ina219.config >> 3) & 0xF;
	t when timerafter(ina219.accesstime) :> void;
	ina219.accesstime += (badc > sadc) ? times[badc] : times[sadc];
}
