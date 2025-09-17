#!/bin/bash
# Script: 03_sysctl_kernel_tuning.sh
# Purpose: Apply kernel and network-related CIS security settings
# Covers: CIS 3.2.1 to 3.3.9

set -euo pipefail

checkingin() {
    LOG="/var/log/hardening_03_sysctl_kernel.log"
    BACKUP_DIR="/root/hardening_backups/$(date +%F_%T)_03_sysctl_kernel"
    mkdir -p "$BACKUP_DIR"

    # Backup current sysctl configs for rollback
    {
        echo "[$(date +'%F %T')] Backing up existing sysctl configs to ${BACKUP_DIR}/current_sysctl"
        mkdir -p "${BACKUP_DIR}/current_sysctl"
        cp -a /etc/sysctl.conf "${BACKUP_DIR}/current_sysctl/" 2>/dev/null || true
        cp -a /etc/sysctl.d/*.conf "${BACKUP_DIR}/current_sysctl/" 2>/dev/null || true
    } >> "${LOG}" 2>&1
}

log() { echo "[$(date +'%F %T')] $1" | tee -a "$LOG"; }
fail() { log "ERROR: $1"; exit 1; }

require_root() {
  if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
    echo "Run as root" >&2
    exit 1
  fi
}

apply_sysctl_settings() {
    log "Applying sysctl kernel network settings per CIS benchmark..."

    SYSCTL_FILE="/etc/sysctl.d/99-cis-kernel-hardening.conf"

    cat <<EOF > "$SYSCTL_FILE"
# 3.2.1 Disable Packet Redirects
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0

# 3.2.2 Disable IP Forwarding
net.ipv4.ip_forward = 0
net.ipv6.conf.all.forwarding = 0

# 3.3.1 Disable Source Routed Packets
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0
net.ipv6.conf.default.accept_source_route = 0

# 3.3.2 Disable ICMP Redirects
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0

# 3.3.3 Disable Secure ICMP Redirects
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.default.secure_redirects = 0

# 3.3.4 Log Suspicious Packets
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1

# 3.3.5 Ignore Broadcast ICMP Requests
net.ipv4.icmp_echo_ignore_broadcasts = 1

# 3.3.6 Ignore Bogus ICMP Responses
net.ipv4.icmp_ignore_bogus_error_responses = 1

# 3.3.7 Enable Reverse Path Filtering
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1

# 3.3.8 Enable TCP SYN Cookies
net.ipv4.tcp_syncookies = 1

# 3.3.9 Disable IPv6 Router Advertisements
net.ipv6.conf.all.accept_ra = 0
net.ipv6.conf.default.accept_ra = 0
EOF

    chmod 0644 "$SYSCTL_FILE"
    sysctl --system | tee -a "$LOG"
    log "Sysctl settings applied successfully."
}

postchecking(){
    log "Post-checking effective sysctl values..."

    # Expectation map: key => expected_value
    declare -A EXPECT=(
      # 3.2.1
      [net.ipv4.conf.all.send_redirects]=0
      [net.ipv4.conf.default.send_redirects]=0
      # 3.2.2
      [net.ipv4.ip_forward]=0
      [net.ipv6.conf.all.forwarding]=0
      # 3.3.1
      [net.ipv4.conf.all.accept_source_route]=0
      [net.ipv4.conf.default.accept_source_route]=0
      [net.ipv6.conf.all.accept_source_route]=0
      [net.ipv6.conf.default.accept_source_route]=0
      # 3.3.2
      [net.ipv4.conf.all.accept_redirects]=0
      [net.ipv4.conf.default.accept_redirects]=0
      [net.ipv6.conf.all.accept_redirects]=0
      [net.ipv6.conf.default.accept_redirects]=0
      # 3.3.3
      [net.ipv4.conf.all.secure_redirects]=0
      [net.ipv4.conf.default.secure_redirects]=0
      # 3.3.4
      [net.ipv4.conf.all.log_martians]=1
      [net.ipv4.conf.default.log_martians]=1
      # 3.3.5
      [net.ipv4.icmp_echo_ignore_broadcasts]=1
      # 3.3.6
      [net.ipv4.icmp_ignore_bogus_error_responses]=1
      # 3.3.7
      [net.ipv4.conf.all.rp_filter]=1
      [net.ipv4.conf.default.rp_filter]=1
      # 3.3.8
      [net.ipv4.tcp_syncookies]=1
      # 3.3.9
      [net.ipv6.conf.all.accept_ra]=0
      [net.ipv6.conf.default.accept_ra]=0
    )

    local failures=0
    for key in "\${!EXPECT[@]}"; do
        if val=$(sysctl -n "$key" 2>/dev/null); then
            if [[ "\$val" == "\${EXPECT[\$key]}" ]]; then
                log "[OK] \$key=\$val"
            else
                log "[FAIL] \$key expected=\${EXPECT[\$key]} got=\$val"
                failures=$((failures+1))
            fi
        else
            log "[FAIL] \$key not found on this system"
            failures=$((failures+1))
        fi
    done

    if (( failures > 0 )); then
        fail "Post-check detected \$failures non-compliant setting(s). Review the log."
    else
        log "All post-checks PASSED."
    fi
}

main() {
    require_root
    checkingin
    apply_sysctl_settings
    postchecking
    log "03_sysctl_kernel_tuning.sh completed."
}

main "$@"
