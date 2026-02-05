#!/system/bin/sh

# Wait for system to fully boot
sleep 20

# ==============================
# CPU: FORCE PERFORMANCE MODE
# ==============================

for cpu in /sys/devices/system/cpu/cpu*; do
  [ -d "$cpu" ] || continue

  echo performance > "$cpu/cpufreq/scaling_governor" 2>/dev/null

  MAX_FREQ=$(cat "$cpu/cpufreq/cpuinfo_max_freq" 2>/dev/null)
  if [ -n "$MAX_FREQ" ]; then
    echo $MAX_FREQ > "$cpu/cpufreq/scaling_max_freq" 2>/dev/null
    echo $MAX_FREQ > "$cpu/cpufreq/scaling_min_freq" 2>/dev/null
  fi
done

# ==============================
# GPU: FORCE MAX FREQUENCY
# (Adreno / Mali supported)
# ==============================

# Adreno GPU
if [ -d /sys/class/kgsl/kgsl-3d0 ]; then
  GPU_PATH=/sys/class/kgsl/kgsl-3d0

  echo 0 > $GPU_PATH/bus_split 2>/dev/null
  echo 100 > $GPU_PATH/force_clk_on 2>/dev/null
  echo 100 > $GPU_PATH/force_bus_on 2>/dev/null
  echo 100 > $GPU_PATH/force_rail_on 2>/dev/null
  echo 0 > $GPU_PATH/throttling 2>/dev/null

  MAX_GPU_FREQ=$(cat $GPU_PATH/devfreq/max_freq 2>/dev/null)
  if [ -n "$MAX_GPU_FREQ" ]; then
    echo $MAX_GPU_FREQ > $GPU_PATH/devfreq/min_freq
    echo $MAX_GPU_FREQ > $GPU_PATH/devfreq/max_freq
  fi
fi

# Mali GPU
if [ -d /sys/class/devfreq ]; then
  for gpu in /sys/class/devfreq/*gpu*; do
    MAX_FREQ=$(cat $gpu/max_freq 2>/dev/null)
    if [ -n "$MAX_FREQ" ]; then
      echo $MAX_FREQ > $gpu/min_freq
      echo $MAX_FREQ > $gpu/max_freq
      echo performance > $gpu/governor
    fi
  done
fi

# ==============================
# DISABLE ALL POWER SAVING
# ==============================

# Disable thermal throttling (if accessible)
for zone in /sys/class/thermal/thermal_zone*; do
  echo disabled > $zone/mode 2>/dev/null
done

# Disable scheduler energy awareness
echo 0 > /proc/sys/kernel/sched_energy_aware 2>/dev/null

# Disable battery optimizations
settings put global adaptive_battery_management_enabled 0
settings put global app_standby_enabled 0
settings put global background_check_enabled 0

# Keep performance locked
while true; do
  sleep 30
done