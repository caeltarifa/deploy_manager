#!/bin/bash
# Script: 06_cron_and_at.sh
# Purpose: Secure cron and at daemon
# Covers: 5.1.1 – 5.1.9

set -euo pipefail

checkingin(){
    LOG="/var/log/hardening_06_cron_and_at.log"
    BACKUP_DIR="/root/hardening_backups/$(date +%F_%T)_06_cron_and_at"
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

# 5.1.1 Ensure cron daemon is enabled and running
ensure_cron_enabled_running() {
    log "5.1.1 Ensuring cron is enabled and running..."
    systemctl enable --now cron.service
}

# 5.1.2 Ensure permissions on /etc/crontab are configured
secure_crontab_permissions() {
    log "5.1.2 Securing /etc/crontab..."
    cp -a /etc/crontab "$BACKUP_DIR"
    chown root:root /etc/crontab
    chmod 600 /etc/crontab
}

# helper to secure a cron directory (0700) and its files (0600)
_secure_cron_dir() {
    local d="$1"
    [ -d "$d" ] || return 0
    chown root:root "$d"
    chmod 700 "$d"
    find "$d" -xdev -type f -exec chown root:root {} \; -exec chmod 600 {} \; 2>/dev/null || true
}

# 5.1.3 Ensure permissions on /etc/cron.hourly are configured
secure_cron_hourly()   { log "5.1.3 Securing /etc/cron.hourly...";   cp -a /etc/cron.hourly "$BACKUP_DIR" 2>/dev/null || true; _secure_cron_dir /etc/cron.hourly; }

# 5.1.4 Ensure permissions on /etc/cron.daily are configured
secure_cron_daily()    { log "5.1.4 Securing /etc/cron.daily...";    cp -a /etc/cron.daily  "$BACKUP_DIR" 2>/dev/null || true; _secure_cron_dir /etc/cron.daily; }

# 5.1.5 Ensure permissions on /etc/cron.weekly are configured
secure_cron_weekly()   { log "5.1.5 Securing /etc/cron.weekly...";   cp -a /etc/cron.weekly "$BACKUP_DIR" 2>/dev/null || true; _secure_cron_dir /etc/cron.weekly; }

# 5.1.6 Ensure permissions on /etc/cron.monthly are configured
secure_cron_monthly()  { log "5.1.6 Securing /etc/cron.monthly...";  cp -a /etc/cron.monthly "$BACKUP_DIR" 2>/dev/null || true; _secure_cron_dir /etc/cron.monthly; }

# 5.1.7 Ensure permissions on /etc/cron.d are configured
secure_cron_d()        { log "5.1.7 Securing /etc/cron.d...";        cp -a /etc/cron.d      "$BACKUP_DIR" 2>/dev/null || true; _secure_cron_dir /etc/cron.d; }

# 5.1.8 Ensure "cron" is restricted to authorized users
restrict_cron_users() {
    log "5.1.8 Restricting cron to authorized users..."
    echo "root" > /etc/cron.allow
    chown root:root /etc/cron.allow
    chmod 600 /etc/cron.allow
    if [ -f /etc/cron.deny ]; then
        mv /etc/cron.deny "$BACKUP_DIR/cron.deny.bak"
        rm -f /etc/cron.deny
    fi
}

# 5.1.9 Ensure "at" is restricted to authorized users
restrict_at_users() {
    log "5.1.9 Restricting at to authorized users..."
    echo "root" > /etc/at.allow
    chown root:root /etc/at.allow
    chmod 600 /etc/at.allow
    if [ -f /etc/at.deny ]; then
        mv /etc/at.deny "$BACKUP_DIR/at.deny.bak"
        rm -f /etc/at.deny
    fi
}

postcheck(){
    log "Post-checking"

    # 5.1.1
    systemctl is-enabled cron >/dev/null 2>&1 && systemctl is-active cron >/dev/null 2>&1 \
      && log "5.1.1 PASS: cron enabled and running." \
      || log "5.1.1 FAIL: cron not enabled or not running."

    # 5.1.2
    [ "$(stat -c %a /etc/crontab)" = "600" ] && [ "$(stat -c %U:%G /etc/crontab)" = "root:root" ] \
      && log "5.1.2 PASS: /etc/crontab perms/owner OK." \
      || log "5.1.2 FAIL: /etc/crontab perms/owner wrong."

    # 5.1.3–5.1.7 dirs 0700 root:root
    _chk_dir() { local d="$1" n="$2"; [ -d "$d" ] && [ "$(stat -c %a "$d")" = "700" ] && [ "$(stat -c %U:%G "$d")" = "root:root" ]; }
    _chk_dir /etc/cron.hourly  5.1.3 && log "5.1.3 PASS: /etc/cron.hourly secure."  || log "5.1.3 FAIL: /etc/cron.hourly not secure."
    _chk_dir /etc/cron.daily   5.1.4 && log "5.1.4 PASS: /etc/cron.daily secure."   || log "5.1.4 FAIL: /etc/cron.daily not secure."
    _chk_dir /etc/cron.weekly  5.1.5 && log "5.1.5 PASS: /etc/cron.weekly secure."  || log "5.1.5 FAIL: /etc/cron.weekly not secure."
    _chk_dir /etc/cron.monthly 5.1.6 && log "5.1.6 PASS: /etc/cron.monthly secure." || log "5.1.6 FAIL: /etc/cron.monthly not secure."
    _chk_dir /etc/cron.d       5.1.7 && log "5.1.7 PASS: /etc/cron.d secure."       || log "5.1.7 FAIL: /etc/cron.d not secure."

    # also ensure files inside are <=600 and root-owned
    _chk_files() { local d="$1"; [ -d "$d" ] || return 0; 
      find "$d" -xdev -type f \( -perm -0077 -o ! -user root -o ! -group root \) -print -quit | grep -q . && return 1 || return 0; }
    _chk_files /etc/cron.hourly  && _chk_files /etc/cron.daily && _chk_files /etc/cron.weekly && _chk_files /etc/cron.monthly && _chk_files /etc/cron.d \
      && log "5.1.x PASS: cron file perms/owners OK." \
      || log "5.1.x FAIL: some cron files too permissive or not root-owned."

    # 5.1.8
    [ -f /etc/cron.allow ] && [ ! -f /etc/cron.deny ] \
      && [ "$(stat -c %a /etc/cron.allow)" = "600" ] && [ "$(stat -c %U:%G /etc/cron.allow)" = "root:root" ] \
      && log "5.1.8 PASS: cron restricted via cron.allow." \
      || log "5.1.8 FAIL: cron.allow/deny policy not compliant."

    # 5.1.9
    [ -f /etc/at.allow ] && [ ! -f /etc/at.deny ] \
      && [ "$(stat -c %a /etc/at.allow)" = "600" ] && [ "$(stat -c %U:%G /etc/at.allow)" = "root:root" ] \
      && log "5.1.9 PASS: at restricted via at.allow." \
      || log "5.1.9 FAIL: at.allow/deny policy not compliant."
}

main() {
    require_root
    checkingin
    ensure_cron_enabled_running
    secure_crontab_permissions
    secure_cron_hourly
    secure_cron_daily
    secure_cron_weekly
    secure_cron_monthly
    secure_cron_d
    restrict_cron_users
    restrict_at_users
    postcheck
    log "06_cron_and_at.sh completed."
}

main "$@"
