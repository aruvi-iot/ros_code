#!/usr/bin/env bash
set +e
PASS=0; FAIL=0; WARN=0
check_cmd(){ local n="$1" c="$2"; if command -v "$c" >/dev/null 2>&1; then echo "[PASS] $n: $(command -v "$c")"; ((PASS++)); else echo "[FAIL] $n: '$c' not found"; ((FAIL++)); fi; }
check_pkg(){ if ros2 pkg prefix "$1" >/dev/null 2>&1; then echo "[PASS] ROS package: $1"; ((PASS++)); else echo "[FAIL] ROS package missing: $1"; ((FAIL++)); fi; }
echo '=============================================='; echo '       ROS 2 + Gazebo Environment Check'; echo '=============================================='; echo
printf '%s\n' '---- 1. Basic commands ----'
check_cmd 'ROS 2 CLI' ros2; check_cmd colcon colcon; check_cmd 'Python 3' python3; check_cmd Git git; check_cmd rosdep rosdep
echo; echo '---- 2. ROS 2 environment ----'
if [ -n "$ROS_DISTRO" ]; then echo "[PASS] ROS_DISTRO = $ROS_DISTRO"; ((PASS++)); else echo '[FAIL] ROS_DISTRO is not set (source your ROS 2 setup.bash)'; ((FAIL++)); fi
if [ -n "$ROS_VERSION" ]; then echo "[PASS] ROS_VERSION = $ROS_VERSION"; ((PASS++)); else echo '[FAIL] ROS_VERSION is not set'; ((FAIL++)); fi
echo; echo '---- 3. Required ROS 2 packages ----'
if command -v ros2 >/dev/null 2>&1; then check_pkg rclpy; check_pkg geometry_msgs; check_pkg std_msgs; check_pkg sensor_msgs; else echo '[SKIP] ros2 unavailable'; fi
echo; echo '---- 4. Gazebo ----'
if command -v gz >/dev/null 2>&1; then echo '[PASS] Gazebo Sim (gz) found'; gz sim --version 2>/dev/null; ((PASS++)); elif command -v gazebo >/dev/null 2>&1; then echo '[WARN] Gazebo Classic found'; gazebo --version 2>/dev/null; ((WARN++)); else echo '[FAIL] Gazebo not found (neither gz nor gazebo)'; ((FAIL++)); fi
echo; echo '---- 5. Python ROS 2 modules ----'
python3 - <<'PY'
import importlib.util
for m in ['rclpy','geometry_msgs','std_msgs','sensor_msgs']:
    print(f"[PASS] Python module: {m}" if importlib.util.find_spec(m) else f"[FAIL] Python module missing: {m}")
PY
echo; echo '---- 6. Project workspace ----'
if [ -d "$HOME/workspace/robot_projects/src/robot_controller" ]; then echo '[PASS] robot_controller package found'; ((PASS++)); else echo '[WARN] robot_controller package not found'; ((WARN++)); fi
echo; echo '=============================================='; echo '                  SUMMARY'; echo '=============================================='; echo "PASS : $PASS"; echo "WARN : $WARN"; echo "FAIL : $FAIL"; echo
[ "$FAIL" -eq 0 ] && echo 'RESULT: Environment looks ready for the beginner ROS 2 + Gazebo project.' || echo 'RESULT: Some dependencies are missing. Send the complete output.'
