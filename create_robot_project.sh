#!/usr/bin/env bash
set -e

# ============================================================
# Beginner ROS 2 + Gazebo Project Creator
# Project: Simple Robot Controller
# ROS 2: Jazzy
# ============================================================

PROJECT="$HOME/workspace/robot_projects"
PACKAGE="$PROJECT/src/robot_controller"

echo "=============================================="
echo " Creating Beginner ROS 2 Robot Project"
echo "=============================================="

# 1. Load ROS 2 Jazzy
if [ -f /opt/ros/jazzy/setup.bash ]; then
    source /opt/ros/jazzy/setup.bash
else
    echo "[ERROR] ROS 2 Jazzy was not found at /opt/ros/jazzy"
    exit 1
fi

# 2. Create workspace
mkdir -p "$PROJECT/src"

# 3. Create ROS 2 Python package if it does not already exist
if [ ! -f "$PACKAGE/package.xml" ]; then
    echo "[INFO] Creating robot_controller package..."
    cd "$PROJECT/src"
    ros2 pkg create --build-type ament_python robot_controller
else
    echo "[INFO] robot_controller package already exists."
fi

# 4. Create the ROS 2 node
cat > "$PACKAGE/robot_controller_node.py" <<'PYTHON'
import rclpy
from rclpy.node import Node
from geometry_msgs.msg import Twist


class RobotController(Node):

    def __init__(self):
        super().__init__('robot_controller')

        self.publisher = self.create_publisher(
            Twist,
            '/cmd_vel',
            10
        )

        self.timer = self.create_timer(1.0, self.move_robot)

    def move_robot(self):
        msg = Twist()

        # Move forward
        msg.linear.x = 1.0
        msg.angular.z = 0.0

        self.publisher.publish(msg)

        self.get_logger().info('Robot moving forward')


def main(args=None):
    rclpy.init(args=args)

    node = RobotController()

    rclpy.spin(node)

    node.destroy_node()
    rclpy.shutdown()


if __name__ == '__main__':
    main()
PYTHON

# 5. Update setup.py so ros2 run can find the node
cat > "$PACKAGE/setup.py" <<'PYTHON'
from setuptools import find_packages, setup

package_name = 'robot_controller'

setup(
    name=package_name,
    version='0.0.0',
    packages=find_packages(exclude=['test']),
    data_files=[
        ('share/ament_index/resource_index/packages',
         ['resource/' + package_name]),
        ('share/' + package_name, ['package.xml']),
    ],
    install_requires=['setuptools'],
    zip_safe=True,
    maintainer='user',
    maintainer_email='user@example.com',
    description='Beginner ROS 2 robot controller',
    license='Apache-2.0',
    tests_require=['pytest'],
    entry_points={
        'console_scripts': [
            'robot_controller_node = robot_controller.robot_controller_node:main',
        ],
    },
)
PYTHON

# 6. Make sure the package Python directory exists
mkdir -p "$PACKAGE/robot_controller"

# 7. Move/copy the node into the Python package directory
cp "$PACKAGE/robot_controller_node.py" \
   "$PACKAGE/robot_controller/robot_controller_node.py"

# 8. Make sure resource file exists
touch "$PACKAGE/resource/robot_controller"

# 9. Build the workspace
echo
echo "[INFO] Building workspace..."
cd "$PROJECT"
colcon build --symlink-install

# 10. Source the new workspace
source "$PROJECT/install/setup.bash"

# 11. Verify package
echo
echo "=============================================="
echo " Verification"
echo "=============================================="

if ros2 pkg list | grep -qx "robot_controller"; then
    echo "[PASS] robot_controller package is available."
else
    echo "[FAIL] robot_controller package was not found."
    exit 1
fi

echo
echo "Project created successfully!"
echo
echo "Project location:"
echo "  $PROJECT"
echo
echo "Run the node with:"
echo "  source /opt/ros/jazzy/setup.bash"
echo "  source $PROJECT/install/setup.bash"
echo "  ros2 run robot_controller robot_controller_node"
echo
echo "Check the topic with:"
echo "  ros2 topic echo /cmd_vel"
echo
echo "=============================================="
