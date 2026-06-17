#!/usr/bin/env bash
# gpu-monitor.sh — NVIDIA GPU monitor for Waybar (RTX 3060)
# Outputs JSON with usage %, temperature, and alert class.

set -euo pipefail

# ── Locate nvidia-smi ──────────────────────────────────────────────────
# On NixOS the binary may be in /run/opengl-driver/bin/ (kernel driver)
# or on PATH (nvidia-utils / nvtop packages).
find_nvidia_smi() {
  if [ -x /run/opengl-driver/bin/nvidia-smi ]; then
    echo /run/opengl-driver/bin/nvidia-smi
  elif command -v nvidia-smi &>/dev/null; then
    command -v nvidia-smi
  else
    echo ""
  fi
}

# ── Query GPU data via nvidia-smi ──────────────────────────────────────
# --query-gpu returns: utilization.gpu, temperature.gpu, memory.used,
#                      memory.total, fan.speed, power.draw, power.max
SMI=$(find_nvidia_smi)

query() {
  "$SMI" \
    --query-gpu=utilization.gpu,temperature.gpu,memory.used,memory.total,fan.speed,power.draw,power.limit \
    --format=csv,noheader,nounits 2>/dev/null
}

raw=$(query) || {
  echo '{"text":"󰢮 N/A","tooltip":"nvidia-smi not available","class":"unavailable"}'
  exit 0
}

# Parse CSV fields
IFS=',' read -r gpu_usage gpu_temp mem_used mem_total fan_speed power_draw power_limit <<< "$raw"

# Trim whitespace
gpu_usage=$(echo "$gpu_usage" | xargs)
gpu_temp=$(echo "$gpu_temp" | xargs)
mem_used=$(echo "$mem_used" | xargs)
mem_total=$(echo "$mem_total" | xargs)
fan_speed=$(echo "$fan_speed" | xargs)
power_draw=$(echo "$power_draw" | xargs)
power_limit=$(echo "$power_limit" | xargs)

# ── Determine alert class ──────────────────────────────────────────────
if [ "$gpu_temp" -ge 85 ]; then
  alert_class="critical"
elif [ "$gpu_temp" -ge 70 ]; then
  alert_class="warning"
else
  alert_class="normal"
fi

# ── Build JSON output ──────────────────────────────────────────────────
text="󰢮 ${gpu_usage}% ${gpu_temp}°C"
tooltip="GPU Usage:    ${gpu_usage}%\nTemperature:  ${gpu_temp}°C\nVRAM:         ${mem_used} / ${mem_total} MiB\nFan Speed:    ${fan_speed}%\nPower Draw:   ${power_draw} / ${power_limit} W"

printf '{"text":"%s","tooltip":"%s","class":"%s"}\n' "$text" "$tooltip" "$alert_class"
