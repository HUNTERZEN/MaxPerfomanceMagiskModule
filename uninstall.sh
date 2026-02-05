#!/system/bin/sh
# Max Performance Module - Uninstall Script

ui_print "• Removing Max Performance Module"
ui_print "• Restoring system defaults"

# ==============================
# RESTORE CPU GOVERNORS
# ==============================

for cpu in /sys/devices/system/cpu/cpu*; do
  [ -d "$cpu" ] || continue

  # Try common stock governors
  for gov in schedutil interactive ondemand; do
    if grep -q "$gov" "$cpu/cpufreq/scaling_available_governors" 2>/dev/null; then
      echo "$gov" > "$cpu/cpufreq/scaling_governor" 2>/dev/null
      break
    fi
  done

  MINF=$(cat "$cpu/cpufreq/cpuinfo_min_freq" 2>/dev/null)
  MAXF=$(cat "$cpu/cpufreq/cpuinfo_max_freq" 2>/dev/null)

  [ -n "$MINF" ] && echo "$MINF" > "$cpu/cpufreq/scaling_min_freq" 2>/dev/null
  [ -n "$MAXF" ] && echo "$MAXF" > "$cpu/cpufreq/scaling_max_freq" 2>/dev/null
done

# ==============================
# RESTORE GPU (ADRENO)
# ==============================

if [ -d /sys/class/kgsl/kgsl-3d0 ]; then
  GPU_PATH=/sys/class/kgsl/kgsl-3d0

  echo 1 > $GPU_PATH/bus_split 2>/dev/null
  echo 0 > $GPU_PATH/force_clk_on 2>/dev/null
  echo 0 > $GPU_PATH/force_bus_on 2>/dev/null
  echo 0 > $GPU_PATH/force_rail_on 2>/dev/null
  echo 1 > $GPU_PATH/throttling 2>/dev/null

  if [ -f $GPU_PATH/devfreq/governor ]; then
    echo msm-adreno-tz > $GPU_PATH/devfreq/governor 2>/dev/null
  fi
fi

# ==============================
# RESTORE GPU (MALI)
# ==============================

if [ -d /sys/class/devfreq ]; then
  for gpu in /sys/class/devfreq/*gpu*; do
    echo simple_ondemand > $gpu/governor 2>/dev/null

    MINF=$(cat $gpu/min_freq 2>/dev/null)
    MAXF=$(cat $gpu/max_freq 2>/dev/null)

    [ -n "$MINF" ] && echo "$MINF" > $gpu/min_freq 2>/dev/null
    [ -n "$MAXF" ] && echo "$MAXF" > $gpu/max_freq 2>/dev/null
  done
fi

# ==============================
# RE-ENABLE THERMALS
# ==============================

for zone in /sys/class/thermal/thermal_zone*; do
  echo enabled > $zone/mode 2>/dev/null
done

# ==============================
# RESTORE KERNEL SCHEDULER
# ==============================

echo 1 > /proc/sys/kernel/sched_energy_aware 2>/dev/null

# ==============================
# RESTORE BATTERY FEATURES
# ==============================

settings put global adaptive_battery_management_enabled 1
settings put global app_standby_enabled 1
settings put global background_check_enabled 1

ui_print "• System defaults restored"
ui_print "• Reboot recommended"

