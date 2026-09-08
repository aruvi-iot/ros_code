#!/usr/bin/env bash
# check_ros_gazebo_deps.sh
# Checks ROS 2 + Gazebo dependencies and basic runtime on Ubuntu

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

pass() { echo -e "${GREEN}[PASS]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
fail() { echo -e "${RED}[FAIL]${NC} $1"; }

section() { echo -e "\n=== $1 ==="; }

# ---------- System ----------
section "SYSTEM"

# OS
if [ -f /etc/lsb-release ]; then
  os_desc=$(lsb_release -d | cut -f2)
  pass "OS: $os_desc"
else
  fail "lsb-release not found"
fi

# CPU cores & model
cores=$(nproc)
model=$(cat /proc/cpuinfo | grep "model name" | head -n1 | cut -d':' -f2 | xargs)
pass "CPU: $cores cores – $model"

# RAM
ram_total=$(free -h | awk '/^Mem:/ {print $2}')
ram_used=$(free -h | awk '/^Mem:/ {print $3}')
pass "RAM: total=$ram_total, used=$ram_used"

# Disk
disk_root=$(df -h / | awk 'NR==2 {print $4 " available on " $6}')
pass "Disk: $disk_root"

# ---------- GPU (NVIDIA) ----------
section "GPU (NVIDIA)"

if command -v nvidia-smi >/dev/null 2>&1; then
  gpu_info=$(nvidia-smi --query-gpu=name,memory.total --format=csv,noheader,nounits 2>/dev/null || echo "")
  if [ -n "$gpu_info" ]; then
    pass "NVIDIA GPU detected:"
    nvidia-smi --query-gpu=name,memory.total --format=csv
  else
    warn "nvidia-smi runs but no GPU info returned"
  fi
  if command -v nvcc >/dev/null 2>&1; then
    cuda_ver=$(nvcc --version | grep "release" | head -n1)
    pass "CUDA: $cuda_ver"
  else
    warn "nvcc not found (CUDA toolkit may be missing)"
  fi
else
  warn "nvidia-smi not found – may be integrated GPU or missing driver"
fi

# ---------- ROS 2 ----------
section "ROS 2"

if [ -z "$ROS_DISTRO" ]; then
  warn "ROS_DISTRO not set in this shell"
else
  pass "ROS_DISTRO=$ROS_DISTRO"
fi

# Try to source ROS if not already
if ! command -v ros2 >/dev/null 2>&1; then
  # Common paths for Jazzy / Humble
  for setup in \
    /opt/ros/jazzy/setup.bash \
    /opt/ros/humble/setup.bash \
    /opt/ros/rolling/setup.bash
  do
    if [ -f "$setup" ]; then
      # shellcheck disable=SC1090
      source "$setup"
      pass "Sourced ROS from: $setup"
      break
    fi
  done
fi

if command -v ros2 >/dev/null 2>&1; then
  ros_ver=$(ros2 --version 2>&1 | head -n1)
  pass "ros2: $ros_ver"
else
  fail "ros2 command not found"
fi

# Core tools
for tool in colcon rosdep vcs git python3 pip3; do
  if command -v "$tool" >/dev/null 2>&1; then
    ver=$("$tool" --version 2>&1 | head -n1 || echo "version unknown")
    pass "$tool: $ver"
  else
    fail "$tool not found"
  fi
done

# Python version
py_ver=$(python3 --version 2>&1)
pass "Python: $py_ver"

# ---------- Gazebo Sim ----------
section "GAZEBO SIM"

if command -v gz >/dev/null 2>&1; then
  gz_ver=$(gz sim --version 2>&1 | head -n1 || echo "unknown")
  pass "gz sim: $gz_ver"
elif command -v ignition >/dev/null 2>&1; then
  ign_ver=$(ign sim --version 2>&1 | head -n1 || echo "unknown")
  warn "Using Ignition Gazebo: $ign_ver (consider migrating to Gazebo Sim)"
else
  fail "Neither 'gz' nor 'ignition' found"
fi

# ---------- Key ROS/Gazebo packages ----------
section "KEY ROS/GAZEBO PACKAGES"

# Helper to check dpkg package
check_pkg() {
  local pkg=$1
  if dpkg -l "$pkg" 2>/dev/null | grep -q "^ii"; then
    ver=$(dpkg -l "$pkg" | awk '/^ii/ {print $3}')
    pass "$pkg ($ver)"
  else
    warn "$pkg not installed (via apt)"
  fi
}

# Core desktop
check_pkg "ros-jazzy-desktop" || check_pkg "ros-humble-desktop" || check_pkg "ros-rolling-desktop" || warn "No *-desktop package detected via dpkg"

# Gazebo bridge & sim
check_pkg "ros-jazzy-ros-gz" || check_pkg "ros-humble-ros-gz" || warn "ros-*-ros-gz not found"
check_pkg "ros-jazzy-ros-gz-sim" || check_pkg "ros-humble-ros-gz-sim" || warn "ros-*-ros-gz-sim not found"
check_pkg "ros-jazzy-gz-ros2-control" || check_pkg "ros-humble-gz-ros2-control" || warn "ros-*-gz-ros2-control not found"

# Control & description
check_pkg "ros-jazzy-ros2-control" || check_pkg "ros-humble-ros2-control" || warn "ros-*-ros2-control not found"
check_pkg "ros-jazzy-ros2-controllers" || check_pkg "ros-humble-ros2-controllers" || warn "ros-*-ros2-controllers not found"
check_pkg "ros-jazzy-xacro" || check_pkg "ros-humble-xacro" || warn "ros-*-xacro not found"

# ---------- Runtime sanity tests ----------
section "RUNTIME SANITY TESTS"

# Ensure ROS is sourced for tests
if ! command -v ros2 >/dev/null 2>&1; then
  for setup in \
    /opt/ros/jazzy/setup.bash \
    /opt/ros/humble/setup.bash \
    /opt/ros/rolling/setup.bash
  do
    if [ -f "$setup" ]; then
      # shellcheck disable=SC1090
      source "$setup"
      break
    fi
  done
fi

# Test ros2 core commands
if command -v ros2 >/dev/null 2>&1; then
  if ros2 topic list >/dev/null 2>&1; then
    pass "ros2 topic list works"
  else
    fail "ros2 topic list failed"
  fi

  if ros2 node list >/dev/null 2>&1; then
    pass "ros2 node list works"
  else
    fail "ros2 node list failed"
  fi
else
  fail "ros2 not available for runtime tests"
fi

# Test gz sim
if command -v gz >/dev/null 2>&1; then
  if gz sim -h >/dev/null 2>&1; then
    pass "gz sim help works"
  else
    fail "gz sim help failed"
  fi
else
  fail "gz not available for runtime tests"
fi

# Simple Python import checks
section "PYTHON IMPORT CHECKS"

python3 - << 'PY' || true
import sys
mods = ["rclpy", "numpy", "yaml", "xml"]
for m in mods:
    try:
        __import__(m)
        print(f"[PASS] import {m}")
    except ImportError:
        print(f"[WARN] import {m} failed")
PY

section "SUMMARY"

echo "If you see many [FAIL] lines, those components are missing or misconfigured."
echo "You can share this output to get specific install/fix commands for your setup."
