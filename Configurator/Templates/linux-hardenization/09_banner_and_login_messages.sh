#!/bin/bash
# Script: 09_banner_and_login_messages.sh
# Purpose: Configure system login banners and file permissions per CIS benchmark
# Covers: CIS 1.7.1–1.7.6

set -euo pipefail

checkingin(){
    LOG="/var/log/hardening_09_banner_and_login_messages.log"
    BACKUP_DIR="/root/hardening_backups/$(date +%F_%T)_09_banner_and_login_messages"
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

# Banner text (generic warning)
BANNER_TEXT="Authorized users only at SumatoID organization. All activity may be monitored and reported."

# 1.7.1 Configure message of the day (MOTD)
configure_motd() {
    log "1.7.1 - Configuring /etc/motd..."
    cp /etc/motd "$BACKUP_DIR/motd.bak" 2>/dev/null || true
    echo "$BANNER_TEXT" > /etc/motd
    chmod 644 /etc/motd
}

# 1.7.2 Local login banner (/etc/issue)
configure_issue() {
    log "1.7.2 - Configuring /etc/issue..."
    cp /etc/issue "$BACKUP_DIR/issue.bak" 2>/dev/null || true
    echo "$BANNER_TEXT" > /etc/issue
    chmod 644 /etc/issue
}

# 1.7.3 Remote login banner (/etc/issue.net)
configure_issue_net() {
    log "1.7.3 - Configuring /etc/issue.net..."
    cp /etc/issue.net "$BACKUP_DIR/issue.net.bak" 2>/dev/null || true
    echo "$BANNER_TEXT" > /etc/issue.net
    chmod 644 /etc/issue.net
}

# 1.7.1/1.7.2/1.7.3 Platform Flags
disable_motd_dynamic_scripts() {
    log "1.7.1–1.7.3 - Disabling platform-specific MOTD scripts..."
    chmod -x /etc/update-motd.d/* || true
}

# 1.7.4 Ensure permissions on /etc/motd are configured
check_permissions_motd() {
    log "1.7.4 - Ensuring permissions on /etc/motd..."
    chown root:root /etc/motd
    chmod 644 /etc/motd
}

# 1.7.5 Ensure permissions on /etc/issue are configured
check_permissions_issue() {
    log "1.7.5 - Ensuring permissions on /etc/issue..."
    chown root:root /etc/issue
    chmod 644 /etc/issue
}

# 1.7.6 Ensure permissions on /etc/issue.net are configured
check_permissions_issue_net() {
    log "1.7.6 - Ensuring permissions on /etc/issue.net..."
    chown root:root /etc/issue.net
    chmod 644 /etc/issue.net
}

postchecking(){
    log "Post-checking"

    local BAD_RE='(\\v|\\r|\\m|\\s|Ubuntu|Debian|CentOS|Red Hat|Linux|kernel|release)'

    _check_banner() {
        local file="$1" tag="$2"
        if [[ -f "$file" ]]; then
            if grep -Eq "$BAD_RE" "$file"; then
                log "$tag FAIL: $file contains system/escape info."
            else
                log "$tag PASS: $file content sanitized."
            fi
        else
            log "$tag FAIL: $file missing."
        fi
    }

    _check_banner /etc/motd      "1.7.1 -"
    _check_banner /etc/issue     "1.7.2 -"
    _check_banner /etc/issue.net "1.7.3 -"

    if [[ -d /etc/update-motd.d ]]; then
        if find /etc/update-motd.d -type f -perm -111 2>/dev/null | grep -q .; then
            log "1.7.1–1.7.3 FAIL: some /etc/update-motd.d scripts are still executable."
        else
            log "1.7.1–1.7.3 PASS: /etc/update-motd.d scripts not executable."
        fi
    else
        log "1.7.1–1.7.3 INFO: /etc/update-motd.d not present."
    fi

    _perm() { stat -c '%a %U:%G' "$1" 2>/dev/null || echo "???"; }

    if [[ "$(_perm /etc/motd)" == "644 root:root" ]]; then
        log "1.7.4 - PASS: /etc/motd perms 644 root:root."
    else
        log "1.7.4 - FAIL: /etc/motd perms $(_perm /etc/motd) (expected 644 root:root)."
    fi

    if [[ "$(_perm /etc/issue)" == "644 root:root" ]]; then
        log "1.7.5 - PASS: /etc/issue perms 644 root:root."
    else
        log "1.7.5 - FAIL: /etc/issue perms $(_perm /etc/issue) (expected 644 root:root)."
    fi

    if [[ "$(_perm /etc/issue.net)" == "644 root:root" ]]; then
        log "1.7.6 - PASS: /etc/issue.net perms 644 root:root."
    else
        log "1.7.6 - FAIL: /etc/issue.net perms $(_perm /etc/issue.net) (expected 644 root:root)."
    fi
}


main() {
    require_root
    checkingin
    configure_motd
    configure_issue
    configure_issue_net
    disable_motd_dynamic_scripts
    check_permissions_motd
    check_permissions_issue
    check_permissions_issue_net
    postchecking
    log "09_banner_and_login_messages.sh completed."
}

main "$@"
