"""
move_arm_to_slider.py
Description:
    Trying to build a basic simulation where we move the gripper of the Kinova Gen3 6DoF
    to the target location and grip an object.
"""

import importlib
import sys
from urllib.request import urlretrieve

# Start a single meshcat server instance to use for the remainder of this notebook.
server_args = []
from meshcat.servers.zmqserver import start_zmq_server_as_subprocess
proc, zmq_url, web_url = start_zmq_server_as_subprocess(server_args=server_args)

# from manipulation import running_as_notebook

# Imports
import numpy as np
import pydot
from ipywidgets import Dropdown, Layout
from IPython.display import display, HTML, SVG

from pydrake.all import (
    AddMultibodyPlantSceneGraph, ConnectMeshcatVisualizer, DiagramBuilder, 
    FindResourceOrThrow, GenerateHtml, InverseDynamicsController, 
    MultibodyPlant, Parser, Simulator, RigidTransform , RotationMatrix,
    ConstantValueSource, ConstantVectorSource, AbstractValue, 
    RollPitchYaw, LogVectorOutput )
from pydrake.multibody.jupyter_widgets import MakeJointSlidersThatPublishOnCallback
  
# setting path
sys.path.append('/root/kinova_drake/')

from kinova_station import KinovaStationHardwareInterface, EndEffectorTarget, GripperTarget, KinovaStation
from controllers import Command, CommandSequence, CommandSequenceController
from observers.camera_viewer import CameraViewer

###############
## Functions ##
###############

def add_loggers_to_system(builder,station):
    # Loggers force certain outputs to be computed
    wrench_logger = LogVectorOutput(station.GetOutputPort("measured_ee_wrench"),builder)
    wrench_logger.set_name("wrench_logger")

    pose_logger = LogVectorOutput(station.GetOutputPort("measured_ee_pose"), builder)
    pose_logger.set_name("pose_logger")

    twist_logger = LogVectorOutput(station.GetOutputPort("measured_ee_twist"), builder)
    twist_logger.set_name("twist_logger")

    gripper_logger = LogVectorOutput(station.GetOutputPort("measured_gripper_velocity"), builder)
    gripper_logger.set_name("gripper_logger")

def create_pusher_slider_scenario():
    """
    Description:
        Creates the 6 degree of freedom Kinova system in simulation. Anchors it to a "ground plane" and gives it the
        RobotiQ 2f_85 gripper.
        This should also initialize the meshcat visualizer so that we can easily view the robot.
    Usage:
        builder, controller, station, diagram, diagram_context = create_pusher_slider_scenario()
    """

    builder = DiagramBuilder()

    # Constants
    gripper_type = '2f_85'
    dt = 0.001

    pusher_position = [0.8,0.5,0.25]
    # pusher_rotation=[0,np.pi/2,0]
    pusher_rotation=[0,0,0]

    # Start with the Kinova Station object
    station = KinovaStation(time_step=dt,n_dof=6)

    plant = station.plant
    scene_graph = station.scene_graph

    station.AddArmWith2f85Gripper() # Adds arm with the 2f85 gripper

    station.AddGround()
    station.AddCamera()

    X_pusher = RigidTransform()
    X_pusher.set_translation(pusher_position)
    X_pusher.set_rotation(RotationMatrix(RollPitchYaw(pusher_rotation)))
    station.AddManipulandFromFile("pusher/pusher1_urdf.urdf",X_pusher)


    # station.SetupSinglePegScenario(gripper_type=gripper_type, arm_damping=False)
    station.ConnectToMeshcatVisualizer(zmq_url="tcp://127.0.0.1:6000")

    station.Finalize() # finalize station (a diagram in and of itself)

    # Start assembling the overall system diagram
    builder = DiagramBuilder()
    station = builder.AddSystem(station)

    # Setup Gripper and End Effector Command Systems
    #create_end_effector_target(EndEffectorTarget.kPose,builder,station)
    #setup_gripper_command_systems(GripperTarget.kPosition,builder,station)

    # Setup loggers
    add_loggers_to_system(builder,station)

    # Setup Controller
    cs = setup_infinity_command_sequence()
    controller = setup_controller_and_connect_to_station(cs,builder,station)

    # Build the system diagram
    diagram = builder.Build()
    diagram.set_name("system_diagram")
    diagram_context = diagram.CreateDefaultContext()

    # context = diagram.CreateDefaultContext()
    station.meshcat.load()
    diagram.Publish(diagram_context)

    ## Set up initial positions ##

    # Set default arm positions
    station.go_home(diagram, diagram_context, name="Home")

    # Set starting position for any objects in the scene
    station.SetManipulandStartPositions(diagram, diagram_context)

    # Return station
    return builder, controller, station, diagram, diagram_context

def setup_infinity_command_sequence():
    """
    Description:
        Creates the command sequence that we need to achieve the infinity sequence.
    """
    # Constants
    num_points_in_discretized_curve = 7
    infinity_center = np.array([0.6, 0.0, 0.5])
    infinity_center_pose = np.zeros((6,))
    infinity_center_pose[:3] = np.array([np.pi/2,0.0,0.5*np.pi])
    infinity_center_pose[3:] = infinity_center

    curve_radius = 0.2
    curve_duration = 6.0

    infinity_left_lobe_center = infinity_center - np.array([0.0,0.25,0.0])
    infinity_left_lobe_center_pose = np.zeros((6,))
    infinity_left_lobe_center_pose[:3] = np.array([np.pi/2,0.0,0.5*np.pi])
    infinity_left_lobe_center_pose[3:] = infinity_left_lobe_center 

    infinity_right_lobe_center = infinity_center + np.array([0.0,0.25,0.0])
    infinity_right_lobe_center_pose = np.zeros((6,))
    infinity_right_lobe_center_pose[:3] = np.array([np.pi/2,0.0,0.5*np.pi])
    infinity_right_lobe_center_pose[3:] = infinity_right_lobe_center

    # Create the command sequence object
    cs = CommandSequence([])

    # 1. Initial Command
    cs.append(Command(
        name="centering",
        target_pose=infinity_center_pose,
        duration=6,
        gripper_closed=False))    

    # 2. Lower Left Part of Infinity
    cs.append(Command(
        name="lower_left",
        target_pose=infinity_left_lobe_center_pose - np.array([0,0,0,0,0,curve_radius]),
        duration=4,
        gripper_closed=False
    ))
    # 3. Execute curve for left lobe
    theta_list = np.linspace(np.pi/2,np.pi*1.5,num=num_points_in_discretized_curve)
    flipped_theta_list = np.flipud(theta_list)
    for theta_index in range(1,len(flipped_theta_list)):
        theta = flipped_theta_list[theta_index]
        cs.append(Command(
            name="left_curve"+str(theta_index),
            target_pose=infinity_left_lobe_center_pose + np.array([0.0,0.0,0.0,0,curve_radius*np.cos(theta),curve_radius*np.sin(theta)]),
            duration= curve_duration/(num_points_in_discretized_curve),
            gripper_closed = False
        ))

    # 4. Go to lower right Part of infinity (through center)
    cs.append(Command(
        name="left_curve_to_right",
        target_pose = infinity_right_lobe_center_pose - np.array([0,0,0,0,0,curve_radius]),
        duration=8,
        gripper_closed=False
    ))
    # 5. Execute curve for right lobe
    theta_list = np.linspace(np.pi*1.5,np.pi*2.5,num=num_points_in_discretized_curve)
    for theta_index in range(1,len(theta_list)):
        theta = theta_list[theta_index]
        cs.append(Command(
            name="right_curve"+str(theta_index),
            target_pose=infinity_right_lobe_center_pose + np.array([0.0,0.0,0.0,0,curve_radius*np.cos(theta),curve_radius*np.sin(theta)]),
            duration= curve_duration/(num_points_in_discretized_curve),
            gripper_closed = False
        ))

    #6. Get Back to Center
    cs.append(Command(
        name="right_curve_to_home",
        target_pose = infinity_center_pose,
        duration=4,
        gripper_closed=False
    ))

    return cs

def setup_controller_and_connect_to_station(cs,builder,station):
    """
    Description:
        Defines the controller (PID) which is a CommandSequenceController as defined in
        kinova_drake.
    Inputs:
        cs = A CommandSequence object which helps define the CommandSequenceController.
    """

    # Create the controller and connect inputs and outputs appropriately
    #Kp = 10*np.eye(6)
    Kp = np.diag([10,10,10,2,2,2])
    Kd = 2*np.sqrt(Kp)

    controller = builder.AddSystem(CommandSequenceController(
        cs,
        command_type=EndEffectorTarget.kTwist,  # Twist commands seem most reliable in simulation
        Kp=Kp,
        Kd=Kd))
    controller.set_name("controller")
    controller.ConnectToStation(builder, station)

    return controller

###############################################
# Important Flags

run = True

###############################################

# Building Diagram
builder, controller, station, diagram, diagram_context = create_pusher_slider_scenario()

if run:
    # # First thing: send to home position
    # station.go_home(diagram,diagram_context)

    # We use a simulator instance to run the example, but no actual simulation 
    # is being done: it's all on the hardware. 
    simulator = Simulator(diagram, diagram_context)
    simulator.set_target_realtime_rate(1.0)
    simulator.set_publish_every_time_step(False)  # not sure if this is correct

    # We'll use a super simple integration scheme (since we only update a dummy state)
    # and set the maximum timestep to correspond to roughly 40Hz 
    integration_scheme = "explicit_euler"
    time_step = 0.025
    #ResetIntegratorFromFlags(simulator, integration_scheme, time_step)

    # Run simulation
    simulator.Initialize()
    simulator.AdvanceTo(10.0)

#Wait at end
while True:
    1