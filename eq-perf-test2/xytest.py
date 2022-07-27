import sys
sys.path.append('/home/laptopuser/.local/lib/python3.8/site-packages')

import classes.consistentbeliefcontroller as con
import numpy as np
import logging
import time
import math
import cflib.crtp
from cflib.crazyflie import Crazyflie
from cflib.crazyflie.syncCrazyflie import SyncCrazyflie
from cflib.crazyflie.syncLogger import SyncLogger
#from cflib.positioning.motion_commander import MotionCommander
from cflib.crazyflie.commander import Commander
from cflib.crazyflie.log import LogConfig


import matplotlib.pyplot as plt
from matplotlib.animation import FuncAnimation

from datetime import datetime, timedelta

import keyboard

URI='radio://0/100/2M/E7E7E7E703'
dt = 0.1
alpha = 0 # alpha = {0, pi/4}
logging.basicConfig(level=logging.ERROR)

x_list = list()
y_list = list()
vx_list = list()
vy_list = list()


mat_file_name = "xytest.mat"
cbc = con.matfile_data_to_cbc(mat_file_name)
x_0_t = np.array([]).reshape((2,0))

def controller(cbc, x_0_t):
    cbc.x_histtory = x_0_t
    u = cbc.compute_control()
    return u

def reset_estimator(scf):
    cf = scf.cf
    cf.param.set_value('kalman.resetEstimation', '1')
    time.sleep(0.1)
    cf.param.set_value('kalman.resetEstimation', '0')

if __name__ =='__main__':
    cflib.crtp.init_drivers()
    log_est = LogConfig(name='Kalman estimate',period_in_ms=10)
    log_est.add_variable('stateEstimate.x','float')
    log_est.add_variable('stateEstimate.y','float')
    log_est.add_variable('stateEstimate.vx','float')
    log_est.add_variable('stateEstimate.vy', 'float')
    with SyncCrazyflie(URI, cf=Crazyflie(rw_cache='./cache')) as scf:
        reset_estimator(scf)
        cf = scf.cf
        
        time.sleep(1)
        
        with SyncLogger(scf, log_est) as logger:
            t = time.time()
            while time.time() < t+3:
                cf.commander.send_position_setpoint(0,0,0.4,0)
                if keyboard.is_pressed('q'):
                    scf.cf.commander.send_stop_setpoint()
                    break
            x0 = np.array([[0],[0]])
            x_0_t = np.hstack((x_0_t, x0))
            cbc.x_history = x_0_t
            u = cbc.compute_control()
            t = time.time()
            i = 0
            ovx = u[0]; ovy = u[1]
            vx = ovx*math.cos(alpha) - ovy*math.sin(alpha)
            vy = ovx*math.sin(alpha) + ovy*math.cos(alpha)
            while i < 10:
                
                for log_entry in logger:
                    if(keyboard.is_pressed('q')):
                        scf.cf.commander.send_stop_setpoint()
                        print("Stopped command sent!")
                        break

                    data = log_entry[1]
                    x = data['stateEstimate.x']
                    y = data['stateEstimate.y']
                    vxr = data['stateEstimate.vx']
                    vyr = data['stateEstimate.vy']
                    x_list.append(x)
                    y_list.append(y)
                    vx_list.append(vxr)
                    vy_list.append(vyr)
                    cf.commander.send_velocity_world_setpoint(vx, vy, 0, 0)
                    if time.time() >= t+dt:
                        x = data['stateEstimate.x']
                        y = data['stateEstimate.y']
                        break
                x_t = np.array([[x],[y]])
                x_0_t = np.hstack((x_0_t,x_t))
                cbc.x_history = x_0_t
                try:
                    u = cbc.compute_control()
                except IndexError or ValueError:
                    print('wrong')
                    cf.commander.send_stop_setpoint()
                    print(f'x is {x}')
                    print(f'y is {y}')
                    break
                else:
                    ovx = u[0]; ovy = u[1]
                    vx = ovx*math.cos(alpha) - ovy*math.sin(alpha)
                    vy = ovx*math.sin(alpha) + ovy*math.cos(alpha)
                    i += 1
                    print(f'i is {i}')
                    t = time.time()
                
            

    

np.savetxt('result.txt',(x_list,y_list,vx_list,vy_list))