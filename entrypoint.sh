#!/bin/bash

# sensing-rigs-ros2 repository setup script, clone this repo on your home to use it
# https://github.com/nautilus-unipd/sensing-rigs-ros2
WORKSPACE_DIR="/home/ubuntu/sensing-rigs-ros2/ros2_ws"
if [ -d "$WORKSPACE_DIR" ] && [ ! -f "$WORKSPACE_DIR/install/setup.bash" ]; then
  echo "Building ROS2 workspace for the first time..."
  source /opt/ros/jazzy/setup.bash
  cd "$WORKSPACE_DIR"
  colcon build --symlink-install --continue-on-error
fi

# nautilus-ros2 repository setup script, clone this repo on your home to use it 
# TODO
WORKSPACE_DIR="/home/ubuntu/nautilus-ros2/ros2_ws"
if [ -d "$WORKSPACE_DIR" ] && [ ! -f "$WORKSPACE_DIR/install/setup.bash" ]; then
  echo "Building Nautilus ROS2 workspace for the first time..."
  source /opt/ros/jazzy/setup.bash
  cd "$WORKSPACE_DIR"
  colcon build --continue-on-error
fi

exec "$@"
