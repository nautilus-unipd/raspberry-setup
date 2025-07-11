#!/bin/bash
WORKSPACE_DIR="/home/ubuntu/sensing-rigs-ros2/ros2_ws"
if [ ! -f "$WORKSPACE_DIR/install/setup.bash" ]; then
  echo "Building ROS2 workspace for the first time..."
  source /opt/ros/jazzy/setup.bash
  cd "$WORKSPACE_DIR"
  colcon build --symlink-install --continue-on-error
fi

exec "$@"