#!/usr/bin/env bash
set -e

PROJECT="$HOME/workspace/robot_projects"
MODEL="$PROJECT/gazebo/models/simple_wheeled_robot"
WORLD="$PROJECT/gazebo/worlds"

echo "=============================================="
echo " Fixing simple wheeled robot Gazebo files"
echo "=============================================="

mkdir -p "$MODEL" "$WORLD"

cat > "$MODEL/model.sdf" <<'EOF'
<?xml version="1.0"?>
<sdf version="1.9">
  <model name="simple_wheeled_robot">
    <pose>0 0 0.25 0 0 0</pose>

    <link name="base_link">
      <inertial>
        <mass>5.0</mass>
        <inertia>
          <ixx>0.15</ixx>
          <iyy>0.45</iyy>
          <izz>0.55</izz>
          <ixy>0</ixy>
          <ixz>0</ixz>
          <iyz>0</iyz>
        </inertia>
      </inertial>

      <collision name="base_collision">
        <geometry>
          <box>
            <size>1.0 0.6 0.3</size>
          </box>
        </geometry>
      </collision>

      <visual name="base_visual">
        <geometry>
          <box>
            <size>1.0 0.6 0.3</size>
          </box>
        </geometry>
      </visual>
    </link>

    <link name="left_wheel">
      <pose>0 0.38 0 1.570796 0 0</pose>
      <inertial>
        <mass>0.5</mass>
        <inertia>
          <ixx>0.01</ixx>
          <iyy>0.01</iyy>
          <izz>0.01</izz>
          <ixy>0</ixy>
          <ixz>0</ixz>
          <iyz>0</iyz>
        </inertia>
      </inertial>
      <collision name="collision">
        <geometry>
          <cylinder>
            <radius>0.2</radius>
            <length>0.12</length>
          </cylinder>
        </geometry>
      </collision>
      <visual name="visual">
        <geometry>
          <cylinder>
            <radius>0.2</radius>
            <length>0.12</length>
          </cylinder>
        </geometry>
      </visual>
    </link>

    <link name="right_wheel">
      <pose>0 -0.38 0 1.570796 0 0</pose>
      <inertial>
        <mass>0.5</mass>
        <inertia>
          <ixx>0.01</ixx>
          <iyy>0.01</iyy>
          <izz>0.01</izz>
          <ixy>0</ixy>
          <ixz>0</ixz>
          <iyz>0</iyz>
        </inertia>
      </inertial>
      <collision name="collision">
        <geometry>
          <cylinder>
            <radius>0.2</radius>
            <length>0.12</length>
          </cylinder>
        </geometry>
      </collision>
      <visual name="visual">
        <geometry>
          <cylinder>
            <radius>0.2</radius>
            <length>0.12</length>
          </cylinder>
        </geometry>
      </visual>
    </link>

    <link name="caster">
      <pose>0.35 0 -0.13 0 0 0</pose>
      <inertial>
        <mass>0.1</mass>
        <inertia>
          <ixx>0.001</ixx>
          <iyy>0.001</iyy>
          <izz>0.001</izz>
          <ixy>0</ixy>
          <ixz>0</ixz>
          <iyz>0</iyz>
        </inertia>
      </inertial>
      <collision name="collision">
        <geometry>
          <sphere>
            <radius>0.1</radius>
          </sphere>
        </geometry>
      </collision>
      <visual name="visual">
        <geometry>
          <sphere>
            <radius>0.1</radius>
          </sphere>
        </geometry>
      </visual>
    </link>

    <joint name="left_wheel_joint" type="revolute">
      <parent>base_link</parent>
      <child>left_wheel</child>
      <axis>
        <xyz>0 1 0</xyz>
      </axis>
    </joint>

    <joint name="right_wheel_joint" type="revolute">
      <parent>base_link</parent>
      <child>right_wheel</child>
      <axis>
        <xyz>0 1 0</xyz>
      </axis>
    </joint>

    <joint name="caster_joint" type="fixed">
      <parent>base_link</parent>
      <child>caster</child>
    </joint>

    <plugin
      filename="gz-sim-diff-drive-system"
      name="gz::sim::systems::DiffDrive">
      <left_joint>left_wheel_joint</left_joint>
      <right_joint>right_wheel_joint</right_joint>
      <wheel_separation>0.76</wheel_separation>
      <wheel_radius>0.2</wheel_radius>
      <topic>/cmd_vel</topic>
      <odom_topic>/odom</odom_topic>
      <frame_id>odom</frame_id>
      <child_frame_id>base_link</child_frame_id>
    </plugin>
  </model>
</sdf>
EOF

cat > "$MODEL/model.config" <<'EOF'
<?xml version="1.0"?>
<model>
  <name>simple_wheeled_robot</name>
  <version>1.0</version>
  <sdf version="1.9">model.sdf</sdf>
  <author>
    <name>Beginner ROS 2 Project</name>
  </author>
  <description>Simple two-wheel differential drive robot.</description>
</model>
EOF

cat > "$WORLD/robot_world.sdf" <<'EOF'
<?xml version="1.0"?>
<sdf version="1.9">
  <world name="robot_world">

    <gravity>0 0 -9.81</gravity>

    <physics name="default_physics" type="ode">
      <max_step_size>0.001</max_step_size>
      <real_time_factor>1</real_time_factor>
      <real_time_update_rate>1000</real_time_update_rate>
    </physics>

    <model name="ground">
      <static>true</static>
      <link name="ground_link">
        <collision name="ground_collision">
          <geometry>
            <plane>
              <normal>0 0 1</normal>
              <size>100 100</size>
            </plane>
          </geometry>
        </collision>
        <visual name="ground_visual">
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
      <uri>model://simple_wheeled_robot</uri>
      <pose>0 0 0.25 0 0 0</pose>
    </include>

  </world>
</sdf>
EOF

# Validate XML before starting Gazebo
python3 - <<PY
import xml.etree.ElementTree as ET

files = [
    "$MODEL/model.sdf",
    "$MODEL/model.config",
    "$WORLD/robot_world.sdf",
]

for f in files:
    ET.parse(f)
    print("[PASS] XML valid:", f)
PY

source /opt/ros/jazzy/setup.bash

export GZ_SIM_RESOURCE_PATH="$PROJECT/gazebo/models${GZ_SIM_RESOURCE_PATH:+:$GZ_SIM_RESOURCE_PATH}"

echo
echo "[PASS] Files repaired."
echo "[INFO] Starting Gazebo..."
echo

gz sim -r "$WORLD/robot_world.sdf"
