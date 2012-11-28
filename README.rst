INA219 - A library for using INA219 power sense chips
.......

:Version:  0.0.1

:Status:  Stable

:Maintainer:  https://github.com/stevekerrison

:Description:  A library for calibrating and sampling from INA219 power sense chips using XMOS hardware


Key Features
============

* Minimises device polling by calculating sample periods.
* All device settings are configurable
* Auto-calibration feature included to provide appropriate LSB scaling

To Do
=====

* High-speed I2C mode

Required Repositories
================

* xcommon
* sc_i2c (module_i2c_master)
  - https://github.com/xcore/sc_i2c

Support
=======

Fork, fix and pull-request! Feel free to contact maintainer with any questions.
