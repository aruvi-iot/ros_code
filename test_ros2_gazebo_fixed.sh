#!/usr/bin/env bash
set -u

# ============================================================
# ROS 2 Jazzy + Gazebo Integration Validation
#
# Goal: verify the machine is ready for ROS 2 + Gazebo work.
#
# Tests:
#   1. ROS 2 environment
#   2. ROS 2 publisher/subscriber communication
#   3. Gazebo installation
#   4. Gazebo simulation/headless server
#   5. ros_gz_bridge availability
#   6. ROS 2 -> Gazebo message bridge
#   7. Gazebo differential-drive command path
#
# This script does NOT modify /opt/ros and does NOT install packages.
# ============================================================

set +e

PASS=0
FAIL=0
WARN=0
TMP_DIR="$(mktemp -d /tmp/ros_gazebo_test.XXXXXX)"
GZ_PID=""
BRIDGE_PID=""

cleanup() {
    echo
    echo "[INFO] Cleaning up test processes..."
    [ -n "$BRIDGE_PID" ] && kill "$BRIDGE_PID" 2>/dev/null || true
    [ -n "$GZ_PID" ] && kill "$GZ_PID" 2>/dev/null || true
    wait "$BRIDGE_PID" 2>/dev/null || true
    wait "$GZ_PID" 2>/dev/null || true
    rm -rf "$TMP_DIR"
}
trap cleanup EXIT INT TERM

pass() {
    echo "[PASS] $1"
    PASS=$((PASS + 1))
}

fail() {
    echo "[FAIL] $1"
    FAIL=$((FAIL + 1))
}

warn() {
    echo "[WARN] $1"
    WARN=$((WARN + 1))
}

echo "============================================================"
echo "       ROS 2 Jazzy + Gazebo Integration Validation"
echo "============================================================"
echo

# ------------------------------------------------------------
# 1. ROS 2 environment
# ------------------------------------------------------------
echo "---- TEST 1: ROS 2 environment ----"

if [ -f /opt/ros/jazzy/setup.bash ]; then
    # ROS 2 setup scripts may reference optional variables while nounset is enabled.
    # Temporarily disable nounset during sourcing so the validation script works
    # even when the parent terminal has "set -u" enabled.
    set +u
    # shellcheck disable=SC1091
    source /opt/ros/jazzy/setup.bash
    set +u
else
    fail "ROS 2 Jazzy setup file not found: /opt/ros/jazzy/setup.bash"
fi

if command -v ros2 >/dev/null 2>&1; then
    pass "ros2 command is available"
else
    fail "ros2 command is not available"
fi

if [ "${ROS_DISTRO:-}" = "jazzy" ]; then
    pass "ROS_DISTRO = jazzy"
else
    fail "ROS_DISTRO is '${ROS_DISTRO:-not set}', expected jazzy"
fi

# ------------------------------------------------------------
# 2. Required ROS 2 packages
# ------------------------------------------------------------
echo
echo "---- TEST 2: Required ROS 2 packages ----"

for pkg in rclpy std_msgs geometry_msgs; do
    if ros2 pkg prefix "$pkg" >/dev/null 2>&1; then
        pass "ROS package available: $pkg"
    else
        fail "ROS package missing: $pkg"
    fi
done

# ------------------------------------------------------------
# 3. ROS 2 pub/sub test
# ------------------------------------------------------------
echo
echo "---- TEST 3: ROS 2 publisher/subscriber ----"

PUB_TOPIC="/ros_gazebo_validation_text"
ECHO_LOG="$TMP_DIR/echo.log"

ros2 topic echo "$PUB_TOPIC" std_msgs/msg/String >"$ECHO_LOG" 2>&1 &
ECHO_PID=$!

sleep 2

ros2 topic pub --once "$PUB_TOPIC" std_msgs/msg/String \
    "{data: 'ROS2_GAZEBO_TEST_OK'}" >/dev/null 2>&1

sleep 2

if grep -q "ROS2_GAZEBO_TEST_OK" "$ECHO_LOG"; then
    pass "ROS 2 publisher -> topic -> subscriber works"
else
    fail "ROS 2 publisher/subscriber test failed"
fi

kill "$ECHO_PID" 2>/dev/null || true
wait "$ECHO_PID" 2>/dev/null || true

# ------------------------------------------------------------
# 4. Gazebo installation
# ------------------------------------------------------------
echo
echo "---- TEST 4: Gazebo installation ----"

if command -v gz >/dev/null 2>&1; then
    pass "Gazebo 'gz' command is available"
    echo "       $(gz sim --version 2>&1 | head -n 1)"
else
    fail "Gazebo 'gz' command is not available"
fi

# Check Gazebo Sim packages known to be useful for this test.
if command -v gz >/dev/null 2>&1; then
    if gz plugin --list 2>/dev/null | grep -qi "DiffDrive"; then
        pass "Gazebo DiffDrive system is available"
    else
        warn "Gazebo DiffDrive system was not found in plugin listing"
    fi
fi

# ------------------------------------------------------------
# 5. Create a minimal Gazebo test world
# ------------------------------------------------------------
echo
echo "---- TEST 5: Gazebo simulation ----"

WORLD="$TMP_DIR/test_world.sdf"

cat > "$WORLD" <<'EOF'
<?xml version="1.0"?>
<sdf version="1.9">
  <world name="ros_gazebo_validation_world">
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
              <size>20 20</size>
            </plane>
          </geometry>
        </collision>
      </link>
    </model>

    <model name="test_robot">
      <pose>0 0 0.25 0 0 0</pose>

      <link name="base_link">
        <inertial>
          <mass>5</mass>
          <inertia>
            <ixx>0.2</ixx>
            <iyy>0.2</iyy>
            <izz>0.3</izz>
            <ixy>0</ixy>
            <ixz>0</ixz>
            <iyz>0</iyz>
          </inertia>
        </inertial>

        <collision name="collision">
          <geometry>
            <box>
              <size>0.8 0.6 0.3</size>
            </box>
          </geometry>
        </collision>

        <visual name="visual">
          <geometry>
            <box>
              <size>0.8 0.6 0.3</size>
            </box>
          </geometry>
        </visual>
      </link>

      <link name="left_wheel">
        <pose>0 0.35 0 1.57079632679 0 0</pose>
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
              <radius>0.18</radius>
              <length>0.12</length>
            </cylinder>
          </geometry>
        </collision>
        <visual name="visual">
          <geometry>
            <cylinder>
              <radius>0.18</radius>
              <length>0.12</length>
            </cylinder>
          </geometry>
        </visual>
      </link>

      <link name="right_wheel">
        <pose>0 -0.35 0 1.57079632679 0 0</pose>
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
              <radius>0.18</radius>
              <length>0.12</length>
            </cylinder>
          </geometry>
        </collision>
        <visual name="visual">
          <geometry>
            <cylinder>
              <radius>0.18</radius>
              <length>0.12</length>
            </cylinder>
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

      <plugin
        filename="gz-sim-diff-drive-system"
        name="gz::sim::systems::DiffDrive">
        <left_joint>left_wheel_joint</left_joint>
        <right_joint>right_wheel_joint</right_joint>
        <wheel_separation>0.70</wheel_separation>
        <wheel_radius>0.18</wheel_radius>
        <topic>/cmd_vel</topic>
        <odom_topic>/odom</odom_topic>
        <frame_id>odom</frame_id>
        <child_frame_id>base_link</child_frame_id>
      </plugin>
    </model>
  </world>
</sdf>
EOF

if command -v gz >/dev/null 2>&1; then
    GZ_LOG="$TMP_DIR/gazebo.log"

    # Start Gazebo server without requiring the GUI.
    gz sim -r -s "$WORLD" >"$GZ_LOG" 2>&1 &
    GZ_PID=$!

    sleep 5

    if kill -0 "$GZ_PID" 2>/dev/null; then
        pass "Gazebo simulation server is running"
    else
        fail "Gazebo simulation server stopped unexpectedly"
        echo "       Last Gazebo messages:"
        tail -n 15 "$GZ_LOG"
    fi
else
    fail "Gazebo simulation test skipped because 'gz' is unavailable"
fi

# ------------------------------------------------------------
# 6. ros_gz_bridge
# ------------------------------------------------------------
echo
echo "---- TEST 6: ROS 2 <-> Gazebo bridge ----"

if ros2 pkg prefix ros_gz_bridge >/dev/null 2>&1; then
    pass "ros_gz_bridge package is available"
else
    fail "ros_gz_bridge package is missing"
fi

# ------------------------------------------------------------
# 7. Actual ROS 2 -> Gazebo Twist bridge
# ------------------------------------------------------------
echo
echo "---- TEST 7: ROS 2 -> Gazebo Twist communication ----"

if ros2 pkg prefix ros_gz_bridge >/dev/null 2>&1 && [ -n "$GZ_PID" ] && kill -0 "$GZ_PID" 2>/dev/null; then

    GZ_TWIST_LOG="$TMP_DIR/gz_twist.log"

    ros2 run ros_gz_bridge parameter_bridge \
        "/cmd_vel@geometry_msgs/msg/Twist@gz.msgs.Twist" \
        >"$TMP_DIR/bridge.log" 2>&1 &
    BRIDGE_PID=$!

    sleep 3

    if kill -0 "$BRIDGE_PID" 2>/dev/null; then
        pass "ros_gz_bridge is running"
    else
        fail "ros_gz_bridge failed to start"
        cat "$TMP_DIR/bridge.log"
    fi

    # Listen to the Gazebo Transport side.
    gz topic -e -t /cmd_vel >"$GZ_TWIST_LOG" 2>&1 &
    GZ_ECHO_PID=$!

    sleep 2

    # Publish a ROS 2 Twist command.
    ros2 topic pub --once /cmd_vel geometry_msgs/msg/Twist \
        "{linear: {x: 0.5, y: 0.0, z: 0.0}, angular: {x: 0.0, y: 0.0, z: 0.0}}" \
        >/dev/null 2>&1

    sleep 3

    if grep -q "0.5" "$GZ_TWIST_LOG"; then
        pass "ROS 2 Twist reached Gazebo through ros_gz_bridge"
    else
        fail "ROS 2 Twist did not appear on the Gazebo /cmd_vel topic"
        echo "       Gazebo topic output:"
        tail -n 20 "$GZ_TWIST_LOG"
        echo "       Bridge output:"
        tail -n 20 "$TMP_DIR/bridge.log"
    fi

    kill "$GZ_ECHO_PID" 2>/dev/null || true
    wait "$GZ_ECHO_PID" 2>/dev/null || true

else
    fail "ROS 2 -> Gazebo bridge test could not run"
fi

# ------------------------------------------------------------
# Final result
# ------------------------------------------------------------
echo
echo "============================================================"
echo "                         SUMMARY"
echo "============================================================"
echo
printf "PASS : %s\n" "$PASS"
printf "WARN : %s\n" "$WARN"
printf "FAIL : %s\n" "$FAIL"
echo

if [ "$FAIL" -eq 0 ]; then
    echo "RESULT: ROS 2 + Gazebo integration is READY."
    echo
    echo "You have verified:"
    echo "  ROS 2 installation"
    echo "  ROS 2 communication"
    echo "  Gazebo simulation"
    echo "  ros_gz_bridge"
    echo "  ROS 2 -> Gazebo Twist communication"
else
    echo "RESULT: ROS 2 + Gazebo is NOT fully validated."
    echo
    echo "Send the COMPLETE output of this script."
    echo "The failed test(s) will show exactly what needs attention."
fi

echo
echo "============================================================"
