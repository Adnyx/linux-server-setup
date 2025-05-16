#!/usr/bin/env bash
# ============================================================
#  RAID 1 Status Checker
#  Verifies RAID state, mount status, and file write access
# ============================================================

set -euo pipefail

RAID_DEVICE="/dev/md0"
MOUNT_POINT="/mnt/raid"
TEST_FILE="$MOUNT_POINT/testfile.txt"

# 1. Check /proc/mdstat
if grep -q '\[2/2\] \[UU\]' /proc/mdstat; then
  echo "RAID array status: OK (/proc/mdstat reports [2/2] [UU])"
else
  echo "WARNING: RAID array status not optimal (check /proc/mdstat)"
  grep md0 /proc/mdstat || true
fi

# 2. Check mdadm detailed status
if mdadm --detail $RAID_DEVICE | grep -q '\bactive\b'; then
  echo "RAID device state: Active"
else
  echo "WARNING: RAID device is not active"
fi

# 3. Check if mounted
if mount | grep -q "$RAID_DEVICE"; then
  echo "RAID mount status: Mounted on $(mount | grep $RAID_DEVICE | awk '{print $3}')"
else
  echo "WARNING: RAID device is not mounted"
fi

# 4. Test file creation
if touch "$TEST_FILE" 2>/dev/null && ls -l "$TEST_FILE"; then
  echo "Test file successfully written to RAID."
  rm -f "$TEST_FILE"
else
  echo "WARNING: Failed to write test file to RAID."
fi
