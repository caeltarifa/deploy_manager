#!/bin/bash
# Script: 02_package_management.sh
# Purpose: Secure package management and updates
# Covers: CIS 1.2.1 – 1.2.2, 1.5.2 – 1.5.3, 1.9

set -euo pipefail

checkingin() {
    LOG="/var/log/hardening_02_package_management.log"
    BACKUP_DIR="/root/hardening_backups/$(date +%F_%T)_02_package_management"
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

# 1.2.1 Ensure package manager repositories are configured
check_repos() {
    log "1.2.1 Checking for configured repositories..."
    grep -E '^\s*deb ' /etc/apt/sources.list /etc/apt/sources.list.d/* || true
}

# 1.2.2 Ensure GPG keys are configured
check_gpg_keys() {
    log "1.2.2 Verifying GPG keys..."
    apt-key list || true
}

# 1.5.2 Ensure prelink is not installed
remove_prelink() {
    log "1.5.2 Removing prelink if installed..."
    apt-get purge -y prelink || true
}

# 1.5.3 Ensure Automatic Error Reporting is not enabled
disable_apport() {
    # Disables sending debugging data to Ubuntu
    log "1.5.3 Disabling apport crash reporting..."
    if [ -f /etc/default/apport ]; then
        sed -i 's/^enabled=.*/enabled=0/' /etc/default/apport || true
    else
        echo "enabled=0" > /etc/default/apport
    fi

    # Stop/disable/mask Apport units if present
    systemctl stop apport.service 2>/dev/null || true
    systemctl stop apport-autoreport.service 2>/dev/null || true
    systemctl disable apport.service apport-autoreport.service 2>/dev/null || true
    systemctl mask apport.service apport-autoreport.service 2>/dev/null || true

    # Uploader also off
    systemctl stop whoopsie.service 2>/dev/null || true
    systemctl disable whoopsie.service 2>/dev/null || true    
}

# 1.9 Ensure updates and patches are installed
install_updates() {
    log "1.9 Updating packages, patches, fail2ban"
    apt-get update
    apt-get install fail2ban ufw clamav -y
}

postchecking(){
    log "Postchecking"

    if grep -qE '^\s*deb ' /etc/apt/sources.list /etc/apt/sources.list.d/* 2>/dev/null; then
        log "[1.2.1] PASS: repositories are configured."
    else
        log "[1.2.1] FAIL: no active repositories found."
    fi

    if apt-get -o Debug::NoLocking=true update >/dev/null 2>&1; then
        log "[1.2.2] PASS: GPG keys valid (apt-get update succeeded)."
    else
        log "[1.2.2] FAIL: GPG key/repo issue detected."
    fi

    if dpkg -s prelink >/dev/null 2>&1; then
        log "[1.5.2] FAIL: prelink still installed."
    else
        log "[1.5.2] PASS: prelink not installed."
    fi

    if grep -q '^enabled=0' /etc/default/apport 2>/dev/null && ! systemctl is-active --quiet apport.service 2>/dev/null; then
        log "[1.5.3] PASS: apport disabled."
    else
        log "[1.5.3] FAIL: apport still enabled or running."
    fi

    if ! apt-get -s upgrade | grep -q '^Inst '; then
        log "[1.9] PASS: no pending upgrades."
    else
        log "[1.9] INFO: upgrades still pending."
    fi
}

main() {
    require_root
    checkingin
    check_repos
    check_gpg_keys
    remove_prelink
    disable_apport
    install_updates
    postchecking
    log "02_package_management.sh completed."
}

main "$@"

# NOTE: Being careful about upgrading because libraries, deendencies and headers can render on akiraedge fails.
# 