#!/bin/bash
# Script: 05_auditd_logging.sh
# Purpose: Configure and harden auditd, journald, and audit tools integrity
# Covers: CIS 4.1.4.4–4.1.4.11, 4.2.1.2–4.2.1.7, 4.2.3

set -euo pipefail

checkingin() {
    LOG="/var/log/hardening_05_auditd_logging.log"
    BACKUP_DIR="/root/hardening_backups/$(date +%F_%T)_05_auditd_logging"
    mkdir -p "$BACKUP_DIR"

    AUDITD_CONFIG="/etc/audit/auditd.conf"
    AUDIT_RULES="/etc/audit/rules.d/audit.rules"
    JOURNALD_CONFIG="/etc/systemd/journald.conf"
}

log() { echo "[$(date +'%F %T')] $1" | tee -a "$LOG"; }
fail() { log "ERROR: $1"; exit 1; }

require_root() {
  if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
    echo "Run as root" >&2
    exit 1
  fi
}

backup_configs() {
    log "Backing up audit and journald configs to $BACKUP_DIR"
    cp -a "$AUDITD_CONFIG" "$BACKUP_DIR/"
    cp -a "$AUDIT_RULES" "$BACKUP_DIR/"
    cp -a "$JOURNALD_CONFIG" "$BACKUP_DIR/"
}

# 4.1.4.1 Ensure auditd is installed
install_auditd() {
    log "Installing auditd package..."
    apt-get update
    apt-get install -y auditd audispd-plugins
}

# 4.1.4.4 Ensure auditd.conf permissions are 600 and owned by root
configure_auditd_permissions() {
    log "Setting permissions on audit config and rules files..."
    chmod 600 "$AUDITD_CONFIG" "$AUDIT_RULES"
    chown root:root "$AUDITD_CONFIG" "$AUDIT_RULES"
}

# 4.1.4.5–4.1.4.9 Ensure auditd.conf parameters are set securely
configure_auditd_conf() {
    log "Configuring auditd parameters (CIS 4.1.4.5–4.1.4.9)..."

    sed -i 's/^max_log_file = .*/max_log_file = 8/' "$AUDITD_CONFIG"
    sed -i 's/^max_log_file_action = .*/max_log_file_action = ROTATE/' "$AUDITD_CONFIG"
    sed -i 's/^space_left = .*/space_left = 75/' "$AUDITD_CONFIG"
    sed -i 's/^space_left_action = .*/space_left_action = SYSLOG/' "$AUDITD_CONFIG"
    sed -i 's/^action_mail_acct = .*/action_mail_acct = root/' "$AUDITD_CONFIG"
    sed -i 's/^admin_space_left = .*/admin_space_left = 50/' "$AUDITD_CONFIG"
    sed -i 's/^admin_space_left_action = .*/admin_space_left_action = SUSPEND/' "$AUDITD_CONFIG"
    sed -i 's/^disk_full_action = .*/disk_full_action = SUSPEND/' "$AUDITD_CONFIG"
    sed -i 's/^disk_error_action = .*/disk_error_action = SUSPEND/' "$AUDITD_CONFIG"

    systemctl is-active --quiet auditd && systemctl restart auditd
}

# 4.2.1.2 – 4.2.1.7, 4.2.3 Configure audit rules
configure_audit_rules() {
    log "Configuring audit rules (CIS 4.2.1.2–4.2.1.7, 4.2.3)..."

    cat > "$AUDIT_RULES" << 'EOF'
# CIS 4.2.1.3 – 4.2.1.6: Track user and group changes
-w /etc/group -p wa -k identity
-w /etc/passwd -p wa -k identity
-w /etc/gshadow -p wa -k identity
-w /etc/shadow -p wa -k identity
-w /etc/security/opasswd -p wa -k identity

# CIS 4.2.1.3 Monitor authentication logs
-w /var/log/faillog -p wa -k logins
-w /var/log/lastlog -p wa -k logins
-w /var/log/tallylog -p wa -k logins
-w /var/run/faillock/ -p wa -k logins

# CIS 4.2.1.6: Monitor sudo access
-w /etc/sudoers -p wa -k actions
-w /etc/sudoers.d/ -p wa -k actions

# CIS 4.2.1.4: Track time changes
-a always,exit -F arch=b64 -S adjtimex -S settimeofday -k time-change
-a always,exit -F arch=b32 -S adjtimex -S settimeofday -k time-change
-a always,exit -F arch=b64 -S clock_settime -k time-change
-a always,exit -F arch=b32 -S clock_settime -k time-change

# CIS 4.2.1.5: Monitor hostname and locale changes
-w /etc/hosts -p wa -k system-locale
-w /etc/hostname -p wa -k system-locale
-w /etc/issue -p wa -k system-locale

# CIS 4.2.1.7: Monitor MAC policy changes
-w /etc/apparmor/ -p wa -k MAC-policy

# CIS 4.2.3: Monitor privileged command usage
-a always,exit -F path=/usr/bin/sudo -F perm=x -k privileged
EOF

    chmod 600 "$AUDIT_RULES"
    chown root:root "$AUDIT_RULES"

    augenrules --load
}

# 4.1.4.10 Ensure journald is configured to store logs persistently
configure_journald() {
    log "Configuring systemd-journald for persistent logging (CIS 4.1.4.10)..."
    sed -i 's/^#Storage=.*/Storage=persistent/' "$JOURNALD_CONFIG"
    systemctl restart systemd-journald
}

# 4.1.4.11 Verify audit tools have correct permissions
verify_audit_tools_integrity() {
    log "Verifying audit tools integrity (CIS 4.1.4.11)..."
    local tools=("/sbin/auditctl" "/sbin/ausearch" "/sbin/aureport")

    for tool in "${tools[@]}"; do
        if [ -f "$tool" ]; then
            chmod 750 "$tool"
            chown root:root "$tool"
            log "Set permissions for $tool"
        else
            log "Warning: $tool not found!"
        fi
    done
}

postchecking(){
    log "Post-checking"

    # 4.1.4.4 Check permissions on auditd.conf
    if [[ -f "$AUDITD_CONFIG" ]]; then
        perms=$(stat -c "%a" "$AUDITD_CONFIG")
        owner=$(stat -c "%U:%G" "$AUDITD_CONFIG")
        if [[ "$perms" == "600" && "$owner" == "root:root" ]]; then
            log "[4.1.4.4] PASS: $AUDITD_CONFIG has correct permissions."
        else
            log "[4.1.4.4] FAIL: $AUDITD_CONFIG permissions ($perms) or ownership ($owner) incorrect."
        fi
    else
        log "[4.1.4.4] FAIL: $AUDITD_CONFIG not found."
    fi

    # 4.1.4.5–4.1.4.9 Check auditd.conf parameters
    declare -A auditd_params=(
        [max_log_file]=8
        [max_log_file_action]="ROTATE"
        [space_left]=75
        [space_left_action]="SYSLOG"
        [action_mail_acct]="root"
        [admin_space_left]=50
        [admin_space_left_action]="SUSPEND"
        [disk_full_action]="SUSPEND"
        [disk_error_action]="SUSPEND"
    )
    for param in "${!auditd_params[@]}"; do
        expected="${auditd_params[$param]}"
        actual=$(grep -E "^$param\s*=" "$AUDITD_CONFIG" | awk -F= '{gsub(/ /,"",$2); print $2}')
        if [[ "$actual" == "$expected" ]]; then
            log "[4.1.4.5–9] PASS: $param=$expected"
        else
            log "[4.1.4.5–9] FAIL: $param expected '$expected' but found '$actual'"
        fi
    done

    # 4.1.4.10 Check journald persistent config
    if grep -q '^Storage=persistent' "$JOURNALD_CONFIG"; then
        log "[4.1.4.10] PASS: Journald set to persistent."
    else
        log "[4.1.4.10] FAIL: Journald not set to persistent."
    fi

    # 4.1.4.11 Check audit tools permissions
    for tool in /sbin/auditctl /sbin/ausearch /sbin/aureport; do
        if [[ -f "$tool" ]]; then
            perms=$(stat -c "%a" "$tool")
            owner=$(stat -c "%U:%G" "$tool")
            if [[ "$perms" == "750" && "$owner" == "root:root" ]]; then
                log "[4.1.4.11] PASS: $tool permissions and ownership OK."
            else
                log "[4.1.4.11] FAIL: $tool permissions ($perms) or owner ($owner) incorrect."
            fi
        else
            log "[4.1.4.11] WARN: $tool not found."
        fi
    done

    # 4.2.1.2 – 4.2.1.7, 4.2.3 Check that rules are loaded
    if auditctl -l | grep -q "/etc/passwd"; then
        log "[4.2.1.2–7, 4.2.3] PASS: Audit rules appear to be loaded."
    else
        log "[4.2.1.2–7, 4.2.3] FAIL: Audit rules not loaded or missing critical rules."
    fi
}

main() {
    require_root
    checkingin
    install_auditd               
    backup_configs
    configure_auditd_permissions 
    configure_auditd_conf        
    configure_audit_rules        
    configure_journald           
    verify_audit_tools_integrity 
    postchecking
    log "05_auditd_logging.sh completed."
}

main "$@"