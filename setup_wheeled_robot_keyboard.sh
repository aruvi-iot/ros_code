#!/usr/bin/env bash
set -e

# ============================================================
# Beginner ROS 2 + Gazebo - Wheeled Robot + Arrow Key Control
# ROS 2 Jazzy / Gazebo Sim
# ============================================================

PROJECT="$HOME/workspace/robot_projects"
GAZEBO_DIR="$PROJECT/gazebo"

echo "=============================================="
echo " Simple Wheeled Robot Setup"
echo "=============================================="

# Load ROS 2 Jazzy
if [ -f /opt/ros/jazzy/setup.bash ]; then
    source /opt/ros/jazzy/setup.bash
else
    echo "[ERROR] ROS 2 Jazzy not found."
    exit 1
fi

# Check required commands
command -v gz >/dev/null 2>&1 || {
    echo "[ERROR] Gazebo 'gz' command not found."
    exit 1
}

command -v ros2 >/dev/null 2>&1 || {
    echo "[ERROR] ROS 2 command not found."
    exit 1
}

# Create folders
mkdir -p "$GAZEBO_DIR/models/simple_wheeled_robot"
mkdir -p "$GAZEBO_DIR/worlds"

# ------------------------------------------------------------
# Robot model
# ------------------------------------------------------------
cat > "$GAZEBO_DIR/models/simple_wheeled_robot/model.sdf" <<'EOF'
<?xml version="1.0"?>
<sdf version="1.9">
  <model name="simple_wheeled_robot">
    <pose>0 0 0.25 0 0 0</pose>

    <!-- Main body -->
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

    <!-- Left wheel -->
    <link name="left_wheel">
      <pose>0 0.38 -0.02 1.5708 0 0</pose>
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

    <!-- Right wheel -->
    <link name="right_wheel">
      <pose>0 -0.38 -0.02 1.5708 0 0</pose>
      <inertial>
        <mass>0.5</mass>
        <inertia>
          <ixx>0.01</ixx>
          <iyy>0.01</iyy>
          <izz>0.01</izz>
          <ixy>0</ixy>
          <ixz>0</ixz>
          <iyz>0
          </iyz>
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

    <!-- Front caster -->
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
        </inertial>
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

    <!-- Differential drive -->
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

# ------------------------------------------------------------
# Model configuration
# ------------------------------------------------------------
cat > "$GAZEBO_DIR/models/simple_wheeled_robot/model.config" <<'EOF'
<?xml version="1.0"?>
<model>
  <name>simple_wheeled_robot</name>
  <version>1.0</version>
  <sdf version="1.9">model.sdf</sdf>
  <author>
    <name>Beginner ROS 2 Project</name>
  </author>
  <description>Simple two-wheel differential-drive robot.</description>
</model>
EOF

# ------------------------------------------------------------
# Gazebo world
# ------------------------------------------------------------
cat > "$GAZEBO_DIR/worlds/robot_world.sdf" <<'EOF'
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
      <uri>model://simple_wheeled_robot</uri>
      <pose>0 0 0.25 0 0 0</pose>
    </include>

  </world>
</sdf>
EOF

echo
echo "[PASS] Wheeled robot model created."
echo "[PASS] Gazebo world created."

# ------------------------------------------------------------
# Create keyboard teleop Python node
# ------------------------------------------------------------
mkdir -p "$PROJECT/keyboard_teleop"

cat > "$PROJECT/keyboard_teleop/keyboard_teleop.py" <<'PYTHON'
#!/usr/bin/env python3

import sys
import select
import termios
import tty

import rclpy
from rclpy.node import Node
from geometry_msgs.msg import Twist


class KeyboardTeleop(Node):

    def __init__(self):
        super().__init__('keyboard_teleop')

        self.publisher = self.create_publisher(
            Twist,
            '/cmd_vel',
            10
        )

        self.get_logger().info('Keyboard teleop started')
        self.get_logger().info('Use W/S/A/D or arrow keys. SPACE = stop, Q = quit.')

        self.settings = termios.tcgetattr(sys.stdin)

    def run(self):
        while rclpy.ok():
            key = self.get_key()

            msg = Twist()

            if key in ('w', 'W', '\x1b[A'):
                msg.linear.x = 1.0
            elif key in ('s', 'S', '\x1b[B'):
                msg.linear.x = -1.0
            elif key in ('a', 'A', '\x1b[D'):
                msg.angular.z = 1.5
            elif key in ('d', 'D', '\x1b[C'):
                msg.angular.z = -1.5
            elif key == ' ':
                msg.linear.x = 0.0
                msg.angular.z = 0.0
            elif key in ('q', 'Q'):
                break
            else:
                continue

            self.publisher.publish(msg)

    def get_key(self):
        tty.setraw(sys.stdin.fileno())

        key = sys.stdin.read(1)

        if key == '\x1b':
            key += sys.stdin.read(2)

        termios.tcsetattr(
            sys.stdin,
            termios.TCSADRAIN,
            self.settings
        )

        return key

    def stop(self):
        termios.tcsetattr(
            sys.stdin,
            termios.TCSADRAIN,
            self.settings
        )

        msg = Twist()
        self.publisher.publish(msg)


def main(args=None):
    rclpy.init(args=args)

    node = KeyboardTeleop()

    try:
        node.run()
    finally:
        node.stop()
        node.destroy_node()
        rclpy.shutdown()


if __name__ == '__main__':
    main()
PYTHON

chmod +x "$PROJECT/keyboard_teleop/keyboard_teleop.py"

echo
echo "=============================================="
echo " Setup complete!"
echo "=============================================="
echo
echo "Terminal 1 - Gazebo:"
echo
echo "  source /opt/ros/jazzy/setup.bash"
echo "  export GZ_SIM_RESOURCE_PATH=$GAZEBO_DIR/models"
echo "  gz sim -r $GAZEBO_DIR/worlds/robot_world.sdf"
echo
echo "Terminal 2 - Keyboard control:"
echo
echo "  source /opt/ros/jazzy/setup.bash"
echo "  python3 $PROJECT/keyboard_teleop/keyboard_teleop.py"
echo
echo "Controls:"
echo "  UP / W    = Forward"
echo "  DOWN / S  = Backward"
echo "  LEFT / A  = Turn left"
echo "  RIGHT / D = Turn right"
echo "  SPACE     = Stop"
echo "  Q         = Quit"
echo
echo "=============================================="
