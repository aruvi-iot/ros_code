#!/usr/bin/env bash
set -e

# ============================================================
# Step 8 - Create a simple Gazebo robot and world
# Project: Beginner ROS 2 + Gazebo
# ============================================================

PROJECT="$HOME/workspace/robot_projects"

echo "=============================================="
echo " Creating simple Gazebo robot"
echo "=============================================="

# Create directories
mkdir -p "$PROJECT/gazebo/models/simple_robot"
mkdir -p "$PROJECT/gazebo/worlds"

# ------------------------------------------------------------
# Create robot model
# ------------------------------------------------------------
cat > "$PROJECT/gazebo/models/simple_robot/model.sdf" <<'EOF'
<?xml version="1.0"?>

<sdf version="1.9">
  <model name="simple_robot">
    <pose>0 0 0.2 0 0 0</pose>

    <link name="base_link">

      <inertial>
        <mass>1.0</mass>
        <inertia>
          <ixx>0.1</ixx>
          <iyy>0.1</iyy>
          <izz>0.1</izz>
          <ixy>0</ixy>
          <ixz>0</ixz>
          <iyz>0</iyz>
        </inertia>
      </inertial>

      <collision name="collision">
        <geometry>
          <box>
            <size>1.0 0.6 0.3</size>
          </box>
        </geometry>
      </collision>

      <visual name="visual">
        <geometry>
          <box>
            <size>1.0 0.6 0.3</size>
          </box>
        </geometry>
      </visual>

    </link>
  </model>
</sdf>
EOF

# ------------------------------------------------------------
# Create Gazebo world
# ------------------------------------------------------------
cat > "$PROJECT/gazebo/worlds/robot_world.sdf" <<'EOF'
<?xml version="1.0"?>

<sdf version="1.9">
  <world name="robot_world">

    <physics name="default_physics" type="ode">
      <max_step_size>0.001</max_step_size>
      <real_time_factor>1</real_time_factor>
      <real_time_update_rate>1000</real_time_update_rate>
    </physics>

    <model name="ground">
      <static>true</static>

      <link name="ground_link">

        <collision name="collision">
          <geometry>
            <plane>
              <normal>0 0 1</normal>
              <size>100 100</size>
            </plane>
          </geometry>
        </collision>

        <visual name="visual">
          <geometry>
            <plane>
              <normal>0 0 1</normal>
              <size>100 100</size>
            </plane>
          </geometry>
        </visual>

      </link>
    </model>

    <include>
      <uri>model://simple_robot</uri>
      <pose>0 0 0.2 0 0 0</pose>
    </include>

  </world>
</sdf>
EOF

# ------------------------------------------------------------
# Create model.config so Gazebo can identify the model
# ------------------------------------------------------------
cat > "$PROJECT/gazebo/models/simple_robot/model.config" <<'EOF'
<?xml version="1.0"?>

<model>
  <name>simple_robot</name>
  <version>1.0</version>

  <sdf version="1.9">model.sdf</sdf>

  <author>
    <name>Beginner ROS 2 Project</name>
    <email>user@example.com</email>
  </author>

  <description>
    Simple beginner Gazebo robot.
  </description>
</model>
EOF

echo
echo "[PASS] Gazebo robot model created."
echo "[PASS] Gazebo world created."
echo
echo "=============================================="
echo " Launching Gazebo"
echo "=============================================="

# Tell Gazebo where our model is
export GZ_SIM_RESOURCE_PATH="$PROJECT/gazebo/models:${GZ_SIM_RESOURCE_PATH:-}"

# Load Gazebo Sim if available
if [ -f /opt/ros/jazzy/setup.bash ]; then
    source /opt/ros/jazzy/setup.bash
fi

# Check Gazebo
if ! command -v gz >/dev/null 2>&1; then
    echo "[ERROR] 'gz' command was not found."
    echo "Please check your Gazebo installation."
    exit 1
fi

echo
echo "Starting Gazebo..."
echo "Close Gazebo with Ctrl+C in this terminal."
echo

cd "$PROJECT"
gz sim -r gazebo/worlds/robot_world.sdf
