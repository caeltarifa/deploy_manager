#!/bin/bash
# Script: 01_filesystem_hardening.sh
# Purpose: Filesystem, USB, AIDE, ASLR, core dump restrictions
# Covers: CIS 1.1.9 – 1.5.4

set -euo pipefail

checkingin() {
    LOG="/var/log/hardening_01_filesystem.log"
    BACKUP_DIR="/root/hardening_backups/$(date +%F_%T)_01_filesystem"
    mkdir -p "$BACKUP_DIR"
}

log() { echo "[$(date +'%F %T')] $1" | tee -a "$LOG"; }
fail() { log "ERROR: $1"; exit 1; }

require_root() {
  if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
    echo "Run as root" >&2
    exit 1
  fi
}

# 1.1.9 Disable Automounting
disable_automounting() {
    log "Disabling automounting..."
    apt-get purge -y autofs
}

# 1.1.10 Disable USB Storage
disable_usb_storage() {
    log "1.1.10 Disabling USB storage..."
    cp /etc/modprobe.d/usb-storage.conf "$BACKUP_DIR/" 2>/dev/null || true
    cat <<EOF > /etc/modprobe.d/usb-storage.conf
blacklist usb-storage
install usb-storage /bin/true
EOF
    modprobe -r usb-storage || true
    update-initramfs -u
}

# 1.3.1 Ensure AIDE is installed
install_aide() {
    log "1.3.1 Installing AIDE..."
    apt-get update
    apt-get install -y aide aide-common
    DEBIAN_FRONTEND=noninteractive apt-get install -y aide aide-common postfix
    aideinit
}

# 1.3.2 Ensure filesystem integrity is regularly checked
configure_aide_cron() {
    log "1.3.2 Ensuring AIDE check is scheduled (cron.daily)…"
    cat <<EOF > /etc/cron.daily/aide
#!/bin/bash
/usr/bin/aide.wrapper --check
EOF
    chmod 700 /etc/cron.daily/aide
}

# 1.5.1 Ensure ASLR is enabled
enable_aslr() {
    log "1.5.1 Enabling ASLR..."
    echo "kernel.randomize_va_space = 2" > /etc/sysctl.d/50-cis-aslr.conf
    sysctl -w kernel.randomize_va_space=2
}

# 1.5.4 Restrict core dumps
restrict_core_dumps() {
    log "1.5.4 Restricting core dumps..."
    echo "* hard core 0" >> /etc/security/limits.conf
    echo "fs.suid_dumpable = 0" > /etc/sysctl.d/50-cis-coredump.conf
    sysctl -w fs.suid_dumpable=0
}

postcheck() {
  log "Postchecking"

  if ! dpkg -l | grep -q autofs; then
      log "[1.1.9] PASS: autofs is not installed."
  else
      log "[1.1.9] FAIL: autofs still present."
  fi

  if grep -q "usb-storage" /etc/modprobe.d/usb-storage.conf; then
      log "[1.1.10] PASS: usb-storage is blacklisted."
  else
      log "[1.1.10] FAIL: usb-storage not blacklisted."
  fi

  if command -v aide >/dev/null 2>&1; then
      log "[1.3.1] PASS: AIDE installed."
  else
      log "[1.3.1] FAIL: AIDE not installed."
  fi

  if [ -x /etc/cron.daily/aide ]; then
      log "[1.3.2] PASS: AIDE cron job exists."
  else
      log "[1.3.2] FAIL: AIDE cron job missing."
  fi

  if [ "$(sysctl -n kernel.randomize_va_space)" -eq 2 ]; then
      log "[1.5.1] PASS: ASLR is enabled."
  else
      log "[1.5.1] FAIL: ASLR is not enabled."
  fi

  if [ "$(sysctl -n fs.suid_dumpable)" -eq 0 ]; then
      log "[1.5.4] PASS: core dumps restricted via sysctl."
  else
      log "[1.5.4] FAIL: core dumps not restricted."
  fi
}

main() {
    require_root
    checkingin
    disable_automounting
    disable_usb_storage
    install_aide
    configure_aide_cron
    enable_aslr
    restrict_core_dumps
    postcheck
    log "01_filesystem_hardening.sh completed."
}

main "$@"

# NOTES: 
# 1- AIDE + POSFIX has been configured locally. Le domain name 
# assigned is SRV-SOD-0XX, where XX corresponds the host on.
# 2- limit what AIDE scans because databse can get extra disk space.