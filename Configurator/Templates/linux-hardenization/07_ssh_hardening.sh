#!/bin/bash
# Script: 07_ssh_hardening.sh
# Purpose: Harden SSH configuration
# Covers: CIS 5.2.1 – 5.2.22

set -euo pipefail

checkingin() {
    LOG="/var/log/hardening_07_ssh_hardening.log"
    BACKUP_DIR="/root/hardening_backups/$(date +%F_%T)_07_ssh_hardening"
    mkdir -p "$BACKUP_DIR"
    SSHD_CONFIG="/etc/ssh/sshd_config"
}

log() { echo "[$(date +'%F %T')] $1" | tee -a "$LOG"; }
fail() { log "ERROR: $1"; exit 1; }

require_root() {
  if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
    echo "Run as root" >&2
    exit 1
  fi
}

backup_sshd_config() {
    log "Backing up sshd_config..."
    cp "$SSHD_CONFIG" "$BACKUP_DIR/sshd_config.bak"
}

# 5.2.1 Ensure permissions on /etc/ssh/sshd_config are configured
set_sshd_config_permissions() {
    log "5.2.1 - Setting permissions on sshd_config..."
    chown root:root "$SSHD_CONFIG"
    chmod 600 "$SSHD_CONFIG"
}

# 5.2.2 Ensure permissions on SSH private host key files are configured
secure_private_host_keys() {
    log "5.2.2 - Securing SSH private host keys..."
    find /etc/ssh -type f -name 'ssh_host_*_key' -exec chmod 600 {} \;
    find /etc/ssh -type f -name 'ssh_host_*_key' -exec chown root:root {} \;
}

# 5.2.3 Ensure permissions on SSH public host key files are configured
secure_public_host_keys() {
    log "5.2.3 - Securing SSH public host keys..."
    find /etc/ssh -type f -name 'ssh_host_*_key.pub' -exec chmod 644 {} \;
    find /etc/ssh -type f -name 'ssh_host_*_key.pub' -exec chown root:root {} \;
}

# Update or append sshd_config parameters
set_sshd_option() {
    local key="$1"
    local value="$2"
    
    # Remove ALL existing occurrences (handles duplicates and Match blocks)
    sed -i "/^[[:space:]]*${key}\b.*/d" "$SSHD_CONFIG"

    if grep -nE '^[[:space:]]*Match[[:space:]]' "$SSHD_CONFIG" >/dev/null; then
        local ln
        ln="$(grep -nE '^[[:space:]]*Match[[:space:]]' "$SSHD_CONFIG" | head -1 | cut -d: -f1)"
        awk -v ln="$ln" -v k="$key" -v v="$value" 'NR==ln{print k" "v} {print}' "$SSHD_CONFIG" > "${SSHD_CONFIG}.tmp" \
          && mv "${SSHD_CONFIG}.tmp" "$SSHD_CONFIG"
    else
        echo "${key} ${value}" >> "$SSHD_CONFIG"
    fi
}

# 5.2.4 – 5.2.22 various sshd_config hardening
configure_sshd_options() {
    log "5.2.4–5.2.22 - Configuring sshd_config options..."

    set_sshd_option "LogLevel" "INFO"                       # 5.2.5
    set_sshd_option "PermitRootLogin" "no"                 # 5.2.7
    set_sshd_option "PermitEmptyPasswords" "no"            # 5.2.9
    set_sshd_option "PermitUserEnvironment" "no"           # 5.2.10
    set_sshd_option "HostbasedAuthentication" "no"         # 5.2.8
    set_sshd_option "IgnoreRhosts" "yes"                   # 5.2.11
    set_sshd_option "LoginGraceTime" "60"                  # 5.2.21
    set_sshd_option "MaxAuthTries" "4"                     # 5.2.18
    set_sshd_option "MaxStartups" "10:30:60"               # 5.2.19
    set_sshd_option "MaxSessions" "10"                     # 5.2.20
    set_sshd_option "ClientAliveInterval" "300"            # 5.2.22
    set_sshd_option "ClientAliveCountMax" "0"              # 5.2.22

    # 5.2.6 - PAM enabled
    set_sshd_option "UsePAM" "yes"

    # 5.2.13 – 5.2.15 - Strong crypto settings
    set_sshd_option "Ciphers" "chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes256-ctr"
    set_sshd_option "MACs" "hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com"
    set_sshd_option "KexAlgorithms" "curve25519-sha256,curve25519-sha256@libssh.org"

    # 5.2.17 - SSH warning banner
    set_sshd_option "Banner" "/etc/issue.net"

    # 5.2.4 - SSH access is limited (adjust per policy)
    set_sshd_option "AllowUsers" "admin_sumato"

    # Test config and reload service safely
    if sshd -t; then
        systemctl reload ssh 2>/dev/null || systemctl reload sshd 2>/dev/null || \
        systemctl restart ssh 2>/dev/null || systemctl restart sshd 2>/dev/null
        log "5.2.4–5.2.22 - sshd configuration applied."
    else
        fail "5.2.x - sshd_config test failed; not reloading."
    fi
}

postchecking(){
    log "Post-checking"

    if [ "$(stat -c '%U:%G %a' "$SSHD_CONFIG")" = "root:root 600" ]; then
        log "5.2.1 - PASS: sshd_config ownership/perms are root:root 600."
    else
        log "5.2.1 - FAIL: sshd_config perms: $(stat -c '%U:%G %a' "$SSHD_CONFIG")."
    fi

    if ! find /etc/ssh -xdev -type f -name 'ssh_host_*_key' \( ! -perm 600 -o ! -user root -o ! -group root \) | grep -q .; then
        log "5.2.2 - PASS: private host keys are 600 root:root."
    else
        log "5.2.2 - FAIL: private host key ownership/permissions incorrect."
    fi

    if ! find /etc/ssh -xdev -type f -name 'ssh_host_*_key.pub' \( ! -perm 644 -o ! -user root -o ! -group root \) | grep -q .; then
        log "5.2.3 - PASS: public host keys are 644 root:root."
    else
        log "5.2.3 - FAIL: public host key ownership/permissions incorrect."
    fi

    # Effective configuration checks
    if sshd -t 2>/dev/null; then
        CFG="$(sshd -T 2>/dev/null)"
    else
        log "5.2.x - FAIL: sshd configuration test failed."
        return
    fi

    #echo "$CFG" | grep -q '^loglevel info'                    && log "5.2.5 - PASS: LogLevel INFO."                  || log "5.2.5 - FAIL: LogLevel not INFO."
    val=$(echo "$CFG" | awk '/^loglevel[[:space:]]/{print $2}')
    if printf '%s' "${val:-}" | tr '[:upper:]' '[:lower:]' | grep -qx 'info'; then
        log "5.2.5 - PASS: LogLevel INFO."
    else
        log "5.2.5 - FAIL: LogLevel is ${val:-<unset>}."
    fi
    echo "$CFG" | grep -q '^permitrootlogin no'               && log "5.2.7 - PASS: PermitRootLogin no."            || log "5.2.7 - FAIL: PermitRootLogin not no."
    echo "$CFG" | grep -q '^hostbasedauthentication no'       && log "5.2.8 - PASS: HostbasedAuthentication no."    || log "5.2.8 - FAIL: HostbasedAuthentication not no."
    echo "$CFG" | grep -q '^permitemptypasswords no'          && log "5.2.9 - PASS: PermitEmptyPasswords no."       || log "5.2.9 - FAIL: PermitEmptyPasswords not no."
    echo "$CFG" | grep -q '^permituserenvironment no'         && log "5.2.10 - PASS: PermitUserEnvironment no."     || log "5.2.10 - FAIL: PermitUserEnvironment not no."
    echo "$CFG" | grep -q '^ignorerhosts yes'                 && log "5.2.11 - PASS: IgnoreRhosts yes."             || log "5.2.11 - FAIL: IgnoreRhosts not yes."
    echo "$CFG" | grep -q '^usepam yes'                       && log "5.2.6 - PASS: UsePAM yes."                    || log "5.2.6 - FAIL: UsePAM not yes."
    #echo "$CFG" | grep -q '^login_grace_time 60'              && log "5.2.21 - PASS: LoginGraceTime 60."            || log "5.2.21 - FAIL: LoginGraceTime not 60."
    val=$(echo "$CFG" | awk '/^logingracetime[[:space:]]/{print $2}')
    if echo "${val}" | grep -Eq '^(60|60s|1m)$'; then
        log "5.2.21 - PASS: LoginGraceTime 60."
    else
        log "5.2.21 - FAIL: LoginGraceTime is ${val:-<unset>}."
    fi
    echo "$CFG" | grep -q '^maxauthtries 4'                   && log "5.2.18 - PASS: MaxAuthTries 4."               || log "5.2.18 - FAIL: MaxAuthTries not 4."
    echo "$CFG" | grep -q '^maxstartups 10:30:60'             && log "5.2.19 - PASS: MaxStartups 10:30:60."         || log "5.2.19 - FAIL: MaxStartups mismatch."
    echo "$CFG" | grep -q '^maxsessions 10'                   && log "5.2.20 - PASS: MaxSessions 10."               || log "5.2.20 - FAIL: MaxSessions not 10."
    echo "$CFG" | grep -q '^clientaliveinterval 300'          && log "5.2.22 - PASS: ClientAliveInterval 300."      || log "5.2.22 - FAIL: ClientAliveInterval not 300."
    echo "$CFG" | grep -q '^clientalivecountmax 0'            && log "5.2.22 - PASS: ClientAliveCountMax 0."        || log "5.2.22 - FAIL: ClientAliveCountMax not 0."
    echo "$CFG" | grep -q '^ciphers .*chacha20-poly1305@openssh.com' && log "5.2.13 - PASS: Ciphers include strong set." || log "5.2.13 - FAIL: Ciphers weak/missing."
    echo "$CFG" | grep -q '^macs .*hmac-sha2-512-etm@openssh.com'    && log "5.2.14 - PASS: MACs include strong set."    || log "5.2.14 - FAIL: MACs weak/missing."
    echo "$CFG" | grep -q '^kexalgorithms .*curve25519-sha256'       && log "5.2.15 - PASS: KexAlgorithms strong."       || log "5.2.15 - FAIL: KexAlgorithms weak/missing."
    echo "$CFG" | grep -q '^banner /etc/issue.net'            && log "5.2.17 - PASS: Banner /etc/issue.net."        || log "5.2.17 - FAIL: Banner not set."
    echo "$CFG" | grep -q '^allowusers .*admin_sumato'           && log "5.2.4 - PASS: Access limited via AllowUsers."  || log "5.2.4 - FAIL: AllowUsers not set as expected."

    # Service state
    systemctl is-active --quiet ssh  2>/dev/null && log "5.2.x - PASS: ssh service active."  || true
    systemctl is-active --quiet sshd 2>/dev/null && log "5.2.x - PASS: sshd service active." || true
}

main() {
    require_root
    checkingin
    backup_sshd_config
    set_sshd_config_permissions
    secure_private_host_keys
    secure_public_host_keys
    configure_sshd_options
    postchecking
    log "07_ssh_hardening.sh completed."
}

main "$@"
