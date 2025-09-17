#!/bin/bash
# Script: 10_time_sync.sh
# Purpose: Time synchronization hardening for Ubuntu 22.04
# Covers: CIS 2.1.1.1–2.1.4.4

set -euo pipefail

checkingin() {
    LOG="/var/log/hardening_10_time_sync.log"
    BACKUP_DIR="/root/hardening_backups/$(date +%F_%T)_10_time_sync"
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

# 2.1.1.1 Ensure a single time synchronization daemon is in use
remove_conflicting_time_services() {
  log "2.1.1.1 - Removing conflicting time sync services..."
  # Disable other stacks (do not purge core OS timesyncd)
  systemctl disable --now systemd-timesyncd.service >/dev/null 2>&1 || true
  timedatectl set-ntp false || true

  # Make sure old ntp daemon is not active
  systemctl disable --now ntp.service >/dev/null 2>&1 || true

  export DEBIAN_FRONTEND=noninteractive
  apt-get update -y
  apt-get install -y chrony
}

# 2.1.2.1 Ensure chrony is configured with authorized timeserver
NTP_SOURCES=("cl.pool.ntp.org")
configure_chrony() {
  log "2.1.2.1 - Configuring chrony with authorized time server..."
  [[ -f /etc/chrony/chrony.conf ]] && cp -a /etc/chrony/chrony.conf "$BACKUP_DIR/chrony.conf.bak" || true

  if ! grep -q '^# hardening: applied$' /etc/chrony/chrony.conf 2>/dev/null; then
    # Comment any existing server/pool lines only once
    sed -Ei 's/^[[:space:]]*(server|pool)[[:space:]].*$/# &/g' /etc/chrony/chrony.conf || true
    {
      echo '# hardening: applied'
      for s in "${NTP_SOURCES[@]}"; do
        echo "server $s iburst"
      done
      echo 'port 0'     # No incoming NTP requests (client-only)
      echo 'cmdport 0'  # Disable remote control of chronyd via UDP
    } >> /etc/chrony/chrony.conf
  else
    log "Chrony config already hardened; skipping reapply."
  fi
}

# 2.1.2.2 Ensure chrony is running as user _chrony
ensure_chrony_user() {
    log "2.1.2.2 - Verifying chrony runs with least privilege (Ubuntu vendor unit)..."

    if systemctl cat chrony 2>/dev/null | grep -q 'chronyd-starter.sh'; then
    log "2.1.2.2 - Ubuntu chrony unit detected; skipping custom User override (already compliant)."
    return 0
    fi

    # Fallback path for non-Ubuntu/custom units only
    mkdir -p /etc/systemd/system/chrony.service.d
    OVERRIDE=/etc/systemd/system/chrony.service.d/override.conf
    if ! { [[ -f "$OVERRIDE" ]] && grep -qs '^User=_chrony$' "$OVERRIDE"; }; then
    printf "[Service]\nUser=_chrony\n" > "$OVERRIDE"
    log "2.1.2.2 - Wrote drop-in User=_chrony for non-Ubuntu unit."
    fi
    systemctl daemon-reload
}

# 2.1.2.3 Ensure chrony is enabled and running
enable_chrony() {
    log "2.1.2.3 - Enabling and starting chrony..."
    systemctl enable chrony
    systemctl restart chrony
    if ! systemctl is-active --quiet chrony; then
    journalctl -u chrony --no-pager -n 100 || true
    fail "chrony is not active"
    fi
}

# 2.1.3.1 Ensure systemd-timesyncd configured with authorized timeserver
# (Optional path; disabled by default when using chrony)
configure_timesyncd() {
  log "2.1.3.1 - Configuring systemd-timesyncd with authorized NTP server..."
  [[ -f /etc/systemd/timesyncd.conf ]] && cp -a /etc/systemd/timesyncd.conf "$BACKUP_DIR/timesyncd.conf.bak" || true

  primary_ntp="${NTP_SOURCES[0]}"
  if grep -q '^NTP=' /etc/systemd/timesyncd.conf 2>/dev/null; then
    sed -i "s/^NTP=.*/NTP=$primary_ntp/" /etc/systemd/timesyncd.conf
  else
    echo "NTP=$primary_ntp" >> /etc/systemd/timesyncd.conf
  fi
  if grep -q '^FallbackNTP=' /etc/systemd/timesyncd.conf 2>/dev/null; then
    sed -i 's/^FallbackNTP=.*/FallbackNTP=ntp.ubuntu.com/' /etc/systemd/timesyncd.conf
  else
    echo "FallbackNTP=ntp.ubuntu.com" >> /etc/systemd/timesyncd.conf
  fi
}

# 2.1.3.2 Ensure systemd-timesyncd is enabled and running
# (Optional path; disabled by default when using chrony)
enable_timesyncd() {
  log "2.1.3.2 - Enabling and restarting systemd-timesyncd..."
  systemctl enable systemd-timesyncd
  systemctl restart systemd-timesyncd
  systemctl is-active --quiet systemd-timesyncd || fail "systemd-timesyncd is not active"
}

# 2.1.4.1 Ensure ntp access control is configured - restrict -4/-6
# (Optional path; not used when chrony is selected)
configure_ntp_restrictions() {
  log "2.1.4.1 - Configuring NTP access restrictions..."
  [[ -f /etc/ntp.conf ]] && cp -a /etc/ntp.conf "$BACKUP_DIR/ntp.conf.bak" || true
  cat > /etc/ntp.conf <<EOF
driftfile /var/lib/ntp/ntp.drift
restrict -4 default kod nomodify notrap nopeer noquery
restrict -6 default kod nomodify notrap nopeer noquery
server ${NTP_SOURCES[0]} iburst
EOF
}

# 2.1.4.2 Ensure ntp is configured with authorized timeserver
# (Handled by configure_ntp_restrictions when using ntp)

# 2.1.4.3 Ensure ntp is running as user ntp
# (Optional path; not used when chrony is selected)
ensure_ntp_user() {
  log "2.1.4.3 - Ensuring NTP runs as user 'ntp'..."
  mkdir -p /etc/systemd/system/ntp.service.d
  cat > /etc/systemd/system/ntp.service.d/override.conf <<EOF
[Service]
User=ntp
EOF
  systemctl daemon-reload
}

# 2.1.4.4 Ensure ntp is enabled and running
# (Optional path; not used when chrony is selected)
enable_ntp() {
  log "2.1.4.4 - Enabling and starting NTP..."
  export DEBIAN_FRONTEND=noninteractive
  apt-get install -y ntp || true
  systemctl enable ntp
  systemctl restart ntp
  systemctl is-active --quiet ntp || fail "ntp is not active"
}

postcheck() {
  log "Post-check: timedatectl"
  timedatectl || true
  if command -v chronyc >/dev/null 2>&1; then
    log "Post-check: chronyc tracking"
    chronyc tracking || true
    log "Post-check: chronyc sources"
    chronyc -n sources || true
  fi
}

main() {
  require_root
  checkingin
  log "Starting 10_time_sync.sh..."
  remove_conflicting_time_services
  configure_chrony
  ensure_chrony_user
  enable_chrony
  postcheck
  log "10_time_sync.sh completed."
}


main "$@"

#NOTES: Contradiction on 
# 2.1.1.1 Ensure a single time synchronization daemon is in use
# 2.1.4.4 Ensure ntp is enabled and running
# 2.1.3.2 Ensure systemd-timesyncd is enabled and running
#
#