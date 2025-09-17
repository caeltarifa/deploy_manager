#!/bin/bash
# Script: 11_file_permissions.sh
# Purpose: Secure critical system file permissions and audit SUID/SGID/orphan files
# Covers: CIS 6.1.1–6.1.13

set -euo pipefail

checkingin(){
    LOG="/var/log/hardening_11_file_permissions.log"
    BACKUP_DIR="/root/hardening_backups/$(date +%F_%T)_11_file_permissions"
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

# Backup helper
backup_file() {
    local file=$1
    if [[ -f "$file" ]]; then
        cp "$file" "$BACKUP_DIR/"
        log "Backed up $file"
    fi
}

# 6.1.1 – 6.1.8: Set correct permissions and ownership on sensitive files
harden_file_permissions() {
    log "6.1.1 – 6.1.8: Securing file permissions..."

    declare -A file_perms=(
        ["/etc/passwd"]="644 root:root"
        ["/etc/passwd-"]="644 root:root"
        ["/etc/group"]="644 root:root"
        ["/etc/group-"]="644 root:root"
        ["/etc/shadow"]="640 root:shadow"
        ["/etc/shadow-"]="640 root:shadow"
        ["/etc/gshadow"]="640 root:shadow"
        ["/etc/gshadow-"]="640 root:shadow"
    )

    for file in "${!file_perms[@]}"; do
        if [[ -e "$file" ]]; then
            backup_file "$file"
            perms=(${file_perms[$file]})
            chmod "${perms[0]}" "$file"
            chown "${perms[1]}" "$file"
            log "Set permissions ${perms[0]} and ownership ${perms[1]} on $file"
        else
            log "Warning: $file not found"
        fi
    done
}

# 6.1.9: Ensure no world-writable files exist
check_world_writable() {
    log "6.1.9: Removing world-writable bit from files"
    find / -xdev -type f -perm -0002 \
        -not -path "/tmp/*" -not -path "/var/tmp/*" -not -path "/dev/shm/*" \
        -print0 2>/dev/null | xargs -0 -r chmod o-w || true
    chmod 1777 /tmp /var/tmp /dev/shm || true
}

# 6.1.10: Ensure no unowned files or directories exist
check_unowned_files() {
    log "6.1.10: Checking for unowned files..."
    find / -xdev -nouser -print0 2>/dev/null | xargs -0 -r chown root:root || true
}

# 6.1.11: Ensure no ungrouped files or directories exist
check_ungrouped_files() {
    log "6.1.11: Checking for ungrouped files..."
    find / -xdev -nogroup -print0 2>/dev/null | xargs -0 -r chgrp root || true
}

# 6.1.12: Audit SUID executables
audit_suid_executables() {
    log "6.1.12: Auditing SUID executables..."
    find / -xdev -type f -perm -4000 -exec ls -l {} \; > "$BACKUP_DIR/suid_files.txt"
    log "SUID file audit saved."
}

# 6.1.13: Audit SGID executables
audit_sgid_executables() {
    log "6.1.13: Auditing SGID executables..."
    find / -xdev -type f -perm -2000 -exec ls -l {} \; > "$BACKUP_DIR/sgid_files.txt"
    log "SGID file audit saved."
}

postchecking(){
    log "Postchecking"

    # helper: check one file's mode/owner/group
    _chk_perm() {
        local file="$1" mode="$2" owner="$3" group="$4" tag="$5"
        if [[ -e "$file" ]]; then
            local amode aowner agroup
            amode=$(stat -c '%a' "$file") || amode="?"
            aowner=$(stat -c '%U' "$file") || aowner="?"
            agroup=$(stat -c '%G' "$file") || agroup="?"
            if [[ "$amode" == "$mode" && "$aowner" == "$owner" && "$agroup" == "$group" ]]; then
                log "$tag PASS: $file $mode $owner:$group"
            else
                log "$tag FAIL: $file is $amode $aowner:$agroup (expected $mode $owner:$group)"
            fi
        else
            log "$tag INFO: $file not present"
        fi
    }

    _chk_perm /etc/passwd   644 root root   "6.1.1 -"
    _chk_perm /etc/passwd-  644 root root   "6.1.2 -"
    _chk_perm /etc/group    644 root root   "6.1.3 -"
    _chk_perm /etc/group-   644 root root   "6.1.4 -"
    _chk_perm /etc/shadow   640 root shadow "6.1.5 -"
    _chk_perm /etc/shadow-  640 root shadow "6.1.6 -"
    _chk_perm /etc/gshadow  640 root shadow "6.1.7 -"
    _chk_perm /etc/gshadow- 640 root shadow "6.1.8 -"

    ww_count=$(find / -xdev -type f -perm -0002 -print 2>/dev/null | wc -l)
    if [[ "$ww_count" -eq 0 ]]; then
        log "6.1.9 - PASS: no world-writable files on /."
    else
        log "6.1.9 - FAIL: $ww_count world-writable files (see $BACKUP_DIR/world_writable.txt)."
    fi

    unowned_count=$(find / -xdev -nouser -print 2>/dev/null | wc -l)
    if [[ "$unowned_count" -eq 0 ]]; then
        log "6.1.10 - PASS: no unowned files/dirs on /."
    else
        log "6.1.10 - FAIL: $unowned_count unowned entries (see $BACKUP_DIR/unowned_files.txt)."
    fi

    ungrouped_count=$(find / -xdev -nogroup -print 2>/dev/null | wc -l)
    if [[ "$ungrouped_count" -eq 0 ]]; then
        log "6.1.11 - PASS: no ungrouped files/dirs on /."
    else
        log "6.1.11 - FAIL: $ungrouped_count ungrouped entries (see $BACKUP_DIR/ungrouped_files.txt)."
    fi

    suid_count=$(wc -l < "$BACKUP_DIR/suid_files.txt" 2>/dev/null || echo 0)
    if [[ -f "$BACKUP_DIR/suid_files.txt" ]]; then
        log "6.1.12 - PASS: SUID audit generated ($suid_count entries)."
    else
        log "6.1.12 - FAIL: SUID audit file missing."
    fi

    sgid_count=$(wc -l < "$BACKUP_DIR/sgid_files.txt" 2>/dev/null || echo 0)
    if [[ -f "$BACKUP_DIR/sgid_files.txt" ]]; then
        log "6.1.13 - PASS: SGID audit generated ($sgid_count entries)."
    else
        log "6.1.13 - FAIL: SGID audit file missing."
    fi
}

main() {
    require_root
    checkingin    
    harden_file_permissions
    check_world_writable
    check_unowned_files
    check_ungrouped_files
    audit_suid_executables
    audit_sgid_executables
    postchecking
    log "11_file_permissions.sh completed."
}

main "$@"
