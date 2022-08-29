"""
pos_mod_xytest(self):
This function is used to test how well the exploration-exploitation controller from
Rutledge and Ozay's submission to HSCC works.
"""

import sys
sys.path.append('/home/laptopuser/.local/lib/python3.8/site-packages')

import classes.consistentbeliefcontroller as con
from classes.affinedynamics import sample_from_polytope 
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

# Address of the drone
URI='radio://0/110/2M/E7E7E7E704' # We are currently working with drone 4
dt = 5.0
alpha = 0 # alpha = {0, pi/4}
logging.basicConfig(level=logging.ERROR)

x_list = list()
y_list = list()
vx_list = list()
vy_list = list()


mat_file_name = "data/controllers/turning_controller2_data_29Jul2022-1223.mat"
cbc = con.matfile_data_to_cbc(mat_file_name)
x_0_t = np.array([]).reshape((2,0))
u_0_t = np.array([]).reshape((2,0))

# Extract Time Horizon from controller
TimeHorizon = cbc.time_horizon()

print("Time Horizon = ", TimeHorizon)

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
    # Select Mode That System Is In
    hidden_mode = 1 # np.random.randint(0,1)

    print(str(hidden_mode) + '.txt')

    # print(cbc.system)
    # print(cbc.system.L)

    hm_dynamics = cbc.system.Dynamics[hidden_mode]

    print(hm_dynamics)
    print(hm_dynamics.W)

    # Select the height at which system operates
    desired_height = 0.4

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
                cf.commander.send_position_setpoint(0,0,desired_height,0)
                if keyboard.is_pressed('q'):
                    scf.cf.commander.send_stop_setpoint()
                    break
            x0 = np.array([[0],[0]])
            #print('x0 = ', x0, ' with shape = ', x0.shape)
            x_0_t = np.hstack((x_0_t, x0))
            cbc.x_history = x_0_t
            u = cbc.compute_control()
            u0 = np.reshape(u, (2,1))
            u_0_t = np.hstack((u_0_t, u0))
            #print('u = ', u, ' with shape = ', u.shape)
            t = time.time()
            w = np.reshape(sample_from_polytope(hm_dynamics.W),newshape=(hm_dynamics.dim_w(),1))
            x_next = hm_dynamics.f(x0,np.reshape(u,(2,1)),w*0.7)
            print("x_next = ", x_next)
            
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
                    cf.commander.send_position_setpoint(x_next[0,0], x_next[1,0], desired_height, 0)
                    if time.time() >= t+dt:
                        x = data['stateEstimate.x']
                        y = data['stateEstimate.y']
                        break

            #Initialize some loop variables
            i = 1
            while i < TimeHorizon:
                
                
                x_t = np.array([[x],[y]])
                x_0_t = np.hstack((x_0_t,x_t))
                cbc.x_history = x_0_t
                try:
                    u = cbc.compute_control()
                    u_0_t = np.hstack((u_0_t, np.reshape(u, (2,1))))
                    #print("u = ", u,"with shape = ", u.shape)
                except IndexError as e:
                    print('There was an IndexError: ',e)
                    cf.commander.send_stop_setpoint()
                    print(f'Stopped at x = {x}')
                    print(f'Stopped at y = {y}')
                    break
                except ValueError:
                    print('There was a ValueError: ',e)
                    cf.commander.send_stop_setpoint()
                    print(f'Stopped at x = {x}')
                    print(f'Stopped at y = {y}')
                else:
                    w = np.reshape(sample_from_polytope(hm_dynamics.W),newshape=(hm_dynamics.dim_w(),1))
                    x_next = hm_dynamics.f(x_t,np.reshape(u,(2,1)),w*0.7)
                    print("x_next = ",x_next)
                    i += 1
                    print(f'i is {i}')
                    t = time.time()

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
                    cf.commander.send_position_setpoint(x_next[0,0], x_next[1,0], desired_height, 0)
                    if time.time() >= t+dt:
                        x = data['stateEstimate.x']
                        y = data['stateEstimate.y']
                        break
                
            

    # Save data file for this run
    now = datetime.now() # current date and time
    meas_filename = 'data/results-mod_pos-measurements-' + now.strftime("%m%d%Y_%H_%M_%S") + '-mode' + str(hidden_mode) + '.txt'
    history_filename = 'data/results-mod_pos-history-' + now.strftime("%m%d%Y_%H_%M_%S") + '-mode' + str(hidden_mode) + '.txt'
    np.savetxt(meas_filename,(x_list,y_list,vx_list,vy_list))
    np.savetxt(history_filename, (x_0_t.flatten(),u_0_t.flatten()) )