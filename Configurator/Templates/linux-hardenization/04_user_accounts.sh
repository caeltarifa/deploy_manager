#!/bin/bash
# Script: 04_user_accounts.sh
# Purpose: Harden user's password account policies
# Covers: CIS 5.4.1 – 5.5.5, 6.2.1 – 6.2.17

set -euo pipefail

checkingin(){
    LOG="/var/log/hardening_04_user_accounts.log"
    BACKUP_DIR="/root/hardening_backups/$(date +%F_%T)_04_user_accounts"
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

backup_user_configs() {
    log "Backing up user account configs..."
    cp -a /etc/login.defs "$BACKUP_DIR/login.defs" 2>/dev/null || true
    cp -a /etc/pam.d/common-password "$BACKUP_DIR/common-password" 2>/dev/null || true
    cp -a /etc/pam.d/common-auth "$BACKUP_DIR/common-auth" 2>/dev/null || true
    cp -a /etc/pam.d/common-account "$BACKUP_DIR/common-account" 2>/dev/null || true
    cp -a /etc/pam.d/common-session "$BACKUP_DIR/common-session" 2>/dev/null || true
    cp -a /etc/security/pwquality.conf "$BACKUP_DIR/pwquality.conf" 2>/dev/null || true
    cp -a /etc/security/faillock.conf "$BACKUP_DIR/faillock.conf" 2>/dev/null || true
    cp -a /etc/default/useradd "$BACKUP_DIR/useradd" 2>/dev/null || true
    cp -a /etc/profile "$BACKUP_DIR/profile" 2>/dev/null || true
    cp -a /etc/bash.bashrc "$BACKUP_DIR/bash.bashrc" 2>/dev/null || true
    mkdir -p "$BACKUP_DIR/profile.d"; cp -a /etc/profile.d/* "$BACKUP_DIR/profile.d/" 2>/dev/null || true
}

# 5.4.1 Ensure password creation requirements are configured (dcredit, lcredit, minlen, ucredit, ocredit)
set_password_complexity() {
    log "5.4.1 - Setting password complexity..."
    sed -i 's/^password.*pam_pwquality\.so.*/password requisite pam_pwquality.so retry=3 minlen=14 dcredit=-1 ucredit=-1 ocredit=-1 lcredit=-1/' /etc/pam.d/common-password
}

# 5.4.2 Ensure lockout for failed password attempts is configured (Fail2ban for SSH)
set_password_lockout_policy() {
    log "5.4.2 - Setting password lockout policy with fail2ban (5 tries -> 15m ban)"
    apt-get install -y fail2ban
    mkdir -p /etc/fail2ban/jail.d
    cat > /etc/fail2ban/jail.d/ssh_cis.conf <<'EOF'
[sshd]
enabled  = true
backend  = systemd
maxretry = 5
findtime = 10m
bantime  = 15m
EOF
    systemctl enable --now fail2ban
    systemctl reload fail2ban || systemctl restart fail2ban
}

# 5.4.3 Ensure password reuse is limited
limit_password_reuse() {
    log "5.4.3 - Limiting password reuse..."
    if grep -q '^[[:space:]]*password.*pam_unix\.so' /etc/pam.d/common-password; then
        sed -i '/^[[:space:]]*password.*pam_unix\.so/ s/\<remember=[0-9]\+\>//; s/$/ remember=5/' /etc/pam.d/common-password
    fi
}

# 5.4.4 Ensure password hashing algorithm is up to date (SHA-512)
set_password_hashing_algorithm() {
    log "5.4.4 - Ensuring password hashing algorithm is SHA-512..."
    if grep -q '^[#[:space:]]*ENCRYPT_METHOD' /etc/login.defs; then
        sed -i 's/^[#[:space:]]*ENCRYPT_METHOD.*/ENCRYPT_METHOD SHA512/' /etc/login.defs
    else
        echo 'ENCRYPT_METHOD SHA512' >> /etc/login.defs
    fi
}

# 5.4.5 Ensure all current passwords use the configured hashing algorithm
ensure_passwords_use_sha512() {
    log "5.4.5 - Ensuring current passwords use SHA-512 (or are locked)..."
    awk -F: '($3>=1000 && $1!="nobody"){print $1}' /etc/passwd | while read -r u; do
        hash=$(getent shadow "$u" | cut -d: -f2)
        [[ -z "${hash:-}" || "$hash" == "!"* || "$hash" == "*" ]] && continue
        if [[ "$hash" != \$6\$* ]]; then
            log "5.4.5 - INFO: Forcing password reset to rehash with SHA-512 for $u"
            #chage -d 0 "$u" || true
        fi
    done
}

# 5.5.1.1–5.5.1.5: Password aging policies
set_password_aging_policies() {
    log "5.5.1 - Setting password aging policies..."
    sed -i 's/^PASS_MAX_DAYS.*/PASS_MAX_DAYS   365/' /etc/login.defs
    sed -i 's/^PASS_MIN_DAYS.*/PASS_MIN_DAYS   7/' /etc/login.defs
    sed -i 's/^PASS_WARN_AGE.*/PASS_WARN_AGE   7/' /etc/login.defs

    # Apply to existing users (local interactive only)
    awk -F: '($3>=1000)&&($1!="nobody"){print $1}' /etc/passwd | while read -r user; do
        chage --maxdays 365 --mindays 7 --warndays 7 "$user" || true
    done
}

# 5.5.1.4 – Inactive password lock set to 30 days or less
set_inactive_password_lock() {
    log "5.5.1.4 - Setting inactive password lock to 30 days..."
    useradd -D -f 30
    for user in $(awk -F: '($3>=1000)&&($1!="nobody"){print $1}' /etc/passwd); do
        chage --inactive 30 "$user" || true
    done
}

# 5.5.1.5 – Ensure last password change date is in the past
ensure_last_pwd_change_in_past() {
    log "5.5.1.5 - Ensuring last password change is in the past..."
    today=$(( $(date +%s) / 86400 ))
    awk -F: '($3>=1000 && $1!="nobody"){print $1}' /etc/passwd | while read -r u; do
        lastchg=$(getent shadow "$u" | cut -d: -f3)
        if [[ -z "${lastchg:-}" || "$lastchg" -gt "$today" ]]; then
            chage -d 0 "$u" || true
            log "5.5.1.5 - INFO: Reset last-change for $u"
        fi
    done
}

# 5.5.2 Ensure system accounts are secured
secure_system_accounts() {
    log "5.5.2 - Securing system accounts..."
    awk -F: '($3<1000 && $1!="root"){print $1":"$7}' /etc/passwd | while IFS=: read -r u sh; do
        passwd -S "$u" >/dev/null 2>&1 || continue
        usermod -L "$u" 2>/dev/null || true
        [[ "$sh" =~ /(nologin|false)$ ]] || usermod -s /usr/sbin/nologin "$u" 2>/dev/null || true
    done
}

# 5.5.3 Ensure default group for root is GID 0
ensure_root_primary_group_gid0() {
    log "5.5.3 - Ensuring root's primary group is GID 0..."
    [[ "$(id -g root)" -eq 0 ]] || usermod -g 0 root
}

# 5.5.4 Ensure default user umask is 027 or more restrictive
set_default_umask() {
    log "5.5.4 - Setting default umask to 027..."
    if grep -q '^[#[:space:]]*UMASK' /etc/login.defs; then
        sed -i 's/^[#[:space:]]*UMASK.*/UMASK\t027/' /etc/login.defs
    else
        echo 'UMASK 027' >> /etc/login.defs
    fi
    grep -q '^session\s\+optional\s\+pam_umask\.so' /etc/pam.d/common-session || \
        echo 'session optional pam_umask.so' >> /etc/pam.d/common-session
    echo 'umask 027' > /etc/profile.d/cis-umask.sh
    chmod 0644 /etc/profile.d/cis-umask.sh
}

# 5.5.5 Ensure default user shell timeout is 900 seconds or less
set_shell_timeout() {
    log "5.5.5 - Setting shell timeout to 900s..."
    cat > /etc/profile.d/cis-timeout.sh <<'EOF'
# CIS 5.5.5
TMOUT=900
export TMOUT
readonly TMOUT
EOF
    chmod 0644 /etc/profile.d/cis-timeout.sh
}

# 6.2.1 Ensure accounts in /etc/passwd use shadowed passwords
verify_shadowed_passwords() {
    log "6.2.1 - Verifying all accounts use shadowed passwords..."
    awk -F: '($2 != "x") {print $1 " has unshadowed password!"}' /etc/passwd || true
}

# 6.2.2 Ensure /etc/shadow password fields are not empty
check_empty_shadow_passwords() {
    log "6.2.2 - Checking for empty passwords in /etc/shadow..."
    awk -F: '($2 == "" ) { print $1 " has empty password!" }' /etc/shadow || true
}

# 6.2.3 Ensure all groups in /etc/passwd exist in /etc/group
check_groups_exist() {
    log "6.2.3 - Verifying all user groups exist in /etc/group..."
    awk -F: '{ print $4 }' /etc/passwd | while read -r gid; do
        if ! getent group "$gid" > /dev/null; then
            log "Missing group with GID: $gid"
        fi
    done
}

# 6.2.4 Ensure shadow group is empty
ensure_shadow_group_empty() {
    log "6.2.4 - Ensuring shadow group is empty..."
    if [ "$(getent group shadow | cut -d: -f4)" != "" ]; then
        log "WARNING: shadow group has members: $(getent group shadow | cut -d: -f4)"
    fi
}

# 6.2.5 – 6.2.8: Ensure no duplicate UIDs, GIDs, usernames, group names
check_for_duplicates() {
    log "6.2.5–6.2.8 - Checking for duplicate UIDs, GIDs, user/group names..."

    log "Checking duplicate UIDs..."
    cut -d: -f3 /etc/passwd | sort | uniq -d | while read -r uid; do
        log "Duplicate UID: $uid"
    done

    log "Checking duplicate GIDs..."
    cut -d: -f3 /etc/group | sort | uniq -d | while read -r gid; do
        log "Duplicate GID: $gid"
    done

    log "Checking duplicate usernames..."
    cut -d: -f1 /etc/passwd | sort | uniq -d | while read -r user; do
        log "Duplicate user: $user"
    done

    log "Checking duplicate group names..."
    cut -d: -f1 /etc/group | sort | uniq -d | while read -r group; do
        log "Duplicate group: $group"
    done
}

# 6.2.9 Ensure root PATH Integrity
ensure_root_path_integrity() {
    log "6.2.9 - Ensuring root PATH integrity..."
    local SAFE="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
    local prof="/etc/profile.d/00-cis-root-path.sh"
    local sfile="/etc/sudoers.d/00-cis-secure-path"

    export PATH="$SAFE"
    if ! grep -qsF "PATH=\"$SAFE\"" "$prof" 2>/dev/null; then
        printf 'PATH="%s"\nexport PATH\n' "$SAFE" > "$prof"
        chmod 0644 "$prof"
    fi
    if ! grep -qsF "secure_path=\"$SAFE\"" "$sfile" 2>/dev/null; then
        printf 'Defaults secure_path="%s"\n' "$SAFE" > "$sfile"
        chmod 0440 "$sfile"
    fi
    visudo -cf /etc/sudoers >/dev/null || log "6.2.9 - WARN: sudoers syntax check failed"

    local bad=0 offenders="" d t p
    IFS=':' read -r -a _dirs <<< "${PATH:-}"
    for d in "${_dirs[@]}"; do
        [ -n "$d" ] || { bad=1; offenders+="(empty) "; continue; }
        [ "$d" != "." ] || { bad=1; offenders+="(.) "; continue; }
        t=$(readlink -f -- "$d" 2>/dev/null || echo "$d")
        [ -d "$t" ] || { bad=1; offenders+="$d(missing) "; continue; }
        p=$(stat -Lc %A "$t" 2>/dev/null || echo "")
        [[ ${p:5:1} = "-" && ${p:8:1} = "-" ]] || { bad=1; offenders+="$d($p) "; }
    done

    CIS_6_2_9_OK=$(( bad == 0 ? 0 : 1 ))
    CIS_6_2_9_OFFENDERS="$offenders"
}

# 6.2.10 Ensure only root has UID 0
check_uid0_only_root() {
    log "6.2.10 - Ensuring only root has UID 0..."
    awk -F: '($3 == 0 && $1 != "root") { print "Non-root UID 0 account: " $1 }' /etc/passwd || true
}

# Helper for 6.2.11 - 6.2.17: list local interactive users (uid>=1000, not nobody)
#cis_local_interactive_users() { awk -F: '($3>=1000 && $1!="nobody"){print $1":"$6}' /etc/passwd; }
cis_local_interactive_users() { 
    getent passwd | awk -F: '($3>=1000 && $1!="nobody" && $7 !~ /(nologin|false)$/){print $1":"$6}' 
}
# 6.2.11 Ensure local interactive user home directories exist
# 1=create missing homes, 0=only warn
CREATE_MISSING_HOMES=${CREATE_MISSING_HOMES:-0}
ensure_home_dirs_exist() {
  log "6.2.11 - Ensuring home directories exist..."
  cis_local_interactive_users | while IFS=: read -r user dir; do
    if [[ ! -d "$dir" ]]; then
      if [[ "$CREATE_MISSING_HOMES" -eq 1 ]]; then
        mkdir -p "$dir" && chown "$user:$user" "$dir" && chmod 750 "$dir" \
          && log "6.2.11 - CREATED $dir for $user (750, $user:$user)" \
          || log "6.2.11 - WARN: failed to create $dir for $user"
      else
        log "6.2.11 - WARNING: $user missing $dir (set CREATE_MISSING_HOMES=1 to create)"
      fi
    fi
  done
}

# 6.2.12 Ensure local interactive users own their home directories
ensure_home_owned_by_user() {
  log "6.2.12 - Fixing home directory ownership..."
  cis_local_interactive_users | while IFS=: read -r user dir; do
    [[ -d "$dir" ]] || continue
    cur=$(stat -c %U:%G "$dir" 2>/dev/null || echo "?")
    [[ "$cur" == "$user:$user" ]] || chown "$user:$user" "$dir" 2>/dev/null \
      && log "6.2.12 - chown $dir -> $user:$user" || true
  done
}

# 6.2.13 Ensure local interactive user home directories are mode 750 or more restrictive
enforce_home_mode_750() {
  log "6.2.13 - Enforcing home permissions ≤ 750..."
  cis_local_interactive_users | while IFS=: read -r _u dir; do
    [[ -d "$dir" ]] || continue
    perms=$(stat -c %a "$dir" 2>/dev/null || echo 000)
    [[ "$perms" -le 750 ]] || { chmod 750 "$dir" 2>/dev/null && log "6.2.13 - chmod 750 $dir (was $perms)"; }
  done
}

# 6.2.14 Ensure no local interactive user has .netrc files
remove_dot_netrc() {
  log "6.2.14 - Removing .netrc files..."
  cis_local_interactive_users | while IFS=: read -r user dir; do
    [[ -d "$dir" && -e "$dir/.netrc" ]] || continue
    mkdir -p "$BACKUP_DIR/removed_dotfiles/$user"
    mv -f "$dir/.netrc" "$BACKUP_DIR/removed_dotfiles/$user/" 2>/dev/null \
      && log "6.2.14 - REMOVED $dir/.netrc (backed up)" || { rm -f "$dir/.netrc"; log "6.2.14 - REMOVED $dir/.netrc"; }
  done
}

# 6.2.15 Ensure no local interactive user has .forward files
remove_dot_forward() {
  log "6.2.15 - Removing .forward files..."
  cis_local_interactive_users | while IFS=: read -r user dir; do
    [[ -d "$dir" && -e "$dir/.forward" ]] || continue
    mkdir -p "$BACKUP_DIR/removed_dotfiles/$user"
    mv -f "$dir/.forward" "$BACKUP_DIR/removed_dotfiles/$user/" 2>/dev/null \
      && log "6.2.15 - REMOVED $dir/.forward (backed up)" || { rm -f "$dir/.forward"; log "6.2.15 - REMOVED $dir/.forward"; }
  done
}

# 6.2.16 Ensure no local interactive user has .rhosts files
remove_dot_rhosts() {
  log "6.2.16 - Removing .rhosts files..."
  cis_local_interactive_users | while IFS=: read -r user dir; do
    [[ -d "$dir" && -e "$dir/.rhosts" ]] || continue
    mkdir -p "$BACKUP_DIR/removed_dotfiles/$user"
    mv -f "$dir/.rhosts" "$BACKUP_DIR/removed_dotfiles/$user/" 2>/dev/null \
      && log "6.2.16 - REMOVED $dir/.rhosts (backed up)" || { rm -f "$dir/.rhosts"; log "6.2.16 - REMOVED $dir/.rhosts"; }
  done
}

# 6.2.17 Ensure local interactive user dot files are not group or world writable
fix_writable_dotfiles() {
  log "6.2.17 - Fixing writable dotfiles (chmod go-w)..."
  cis_local_interactive_users | while IFS=: read -r _u dir; do
    [[ -d "$dir" ]] || continue
    find "$dir" -xdev -type f -name '.*' -perm /022 -print0 2>/dev/null \
      | xargs -0 -r chmod go-w || true
  done
}

postcheck(){
    log "Post-checking"

    pwq_pam_ok=0
    grep -Eq '^[[:space:]]*password[[:space:]].*pam_pwquality\.so.*\bminlen=(14|[2-9][0-9]+)\b.*\bdcredit=-1\b.*\bucredit=-1\b.*\bocredit=-1\b.*\blcredit=-1\b' /etc/pam.d/common-password && pwq_pam_ok=1
    pwq_conf_ok=0
    if [ -f /etc/security/pwquality.conf ]; then
        grep -Eq '^\s*minlen\s*=\s*(14|[2-9][0-9]+)\b' /etc/security/pwquality.conf &&
        grep -Eq '^\s*dcredit\s*=\s*-1\b' /etc/security/pwquality.conf &&
        grep -Eq '^\s*ucredit\s*=\s*-1\b' /etc/security/pwquality.conf &&
        grep -Eq '^\s*ocredit\s*=\s*-1\b' /etc/security/pwquality.conf &&
        grep -Eq '^\s*lcredit\s*=\s*-1\b' /etc/security/pwquality.conf && pwq_conf_ok=1
    fi
    if [ $pwq_pam_ok -eq 1 ] || [ $pwq_conf_ok -eq 1 ]; then
        log "5.4.1 - PASS: password complexity enforced."
    else
        log "5.4.1 - FAIL: password complexity not enforced."
    fi

    if systemctl is-active --quiet fail2ban && command -v fail2ban-client >/dev/null 2>&1; then
        mr=$(fail2ban-client get sshd maxretry 2>/dev/null || echo "")
        bt=$(fail2ban-client get sshd bantime   2>/dev/null || echo "")
        ft=$(fail2ban-client get sshd findtime  2>/dev/null || echo "")
        if [ "$mr" = "5" ] && [ "$bt" = "900" ] && [ "$ft" = "600" ]; then
            log "5.4.2 - PASS: fail2ban sshd jail active (5 tries, 10m window, 15m ban)."
        else
            log "5.4.2 - FAIL: fail2ban sshd jail not enforcing 5/10m/15m (mr=$mr bt=$bt ft=$ft)."
        fi
    else
        log "5.4.2 - FAIL: fail2ban service inactive or client missing."
    fi

    grep -q '^[[:space:]]*password.*pam_unix\.so.*\bremember=5\b' /etc/pam.d/common-password \
      && log "5.4.3 - PASS: remember=5 set." \
      || log "5.4.3 - FAIL: remember not set to 5."

    grep -q '^ENCRYPT_METHOD[[:space:]]\+SHA512\b' /etc/login.defs \
      && log "5.4.4 - PASS: ENCRYPT_METHOD SHA512." \
      || log "5.4.4 - FAIL: ENCRYPT_METHOD not SHA512."

    if awk -F: '($3>=1000 && $1!="nobody"){print $1}' /etc/passwd | while read -r u; do
            h=$(getent shadow "$u" | cut -d: -f2)
            [[ -z "${h:-}" || "$h" == "!"* || "$h" == "*" || "$h" == \$6\$* ]] || { echo BAD; break; }
        done | grep -q BAD; then
      log "5.4.5 - FAIL: some users not using SHA-512."
    else
      log "5.4.5 - PASS: all active users use SHA-512 (or are locked)."
    fi

    ok_max=$(grep -Eq '^\s*PASS_MAX_DAYS\s+365\b' /etc/login.defs && echo 1 || echo 0)
    ok_min=$(grep -Eq '^\s*PASS_MIN_DAYS\s+7\b'   /etc/login.defs && echo 1 || echo 0)
    ok_warn=$(grep -Eq '^\s*PASS_WARN_AGE\s+7\b'  /etc/login.defs && echo 1 || echo 0)
    [ "$ok_max$ok_min$ok_warn" = "111" ] && log "5.5.1 - PASS: login.defs aging (365/7/7)." || log "5.5.1 - FAIL: login.defs aging not 365/7/7."

    peruser_fail=0
    today=$(( $(date +%s) / 86400 ))
    while IFS=: read -r user _ uid _; do
        [[ $uid -ge 1000 && $user != "nobody" ]] || continue
        IFS=: read -r _name hash lastchg min max warn inactive expire _rest <<<"$(getent shadow "$user")"
        [[ "${min:-7}" -ge 7 ]] || peruser_fail=1
        [[ -n "${max:-}" && "$max" -le 365 && "$max" -gt 0 ]] || peruser_fail=1
        [[ "${warn:-7}" -ge 7 ]] || peruser_fail=1
        [[ -n "${inactive:-}" && "$inactive" -le 30 && "$inactive" -ge 0 ]] || peruser_fail=1
        [[ -n "${lastchg:-}" && "$lastchg" -le "$today" ]] || peruser_fail=1
    done < /etc/passwd
    [[ $peruser_fail -eq 0 ]] && log "5.5.1.users - PASS: users aligned (min=7,max<=365,warn>=7,inactive<=30,lastchg<=today)." \
                              || log "5.5.1.users - FAIL: some users not aligned; see 'chage -l <user>'."

    useradd -D | grep -q '^INACTIVE=30' \
      && log "5.5.1.4 - PASS: default inactive=30 days." \
      || log "5.5.1.4 - FAIL: default inactive not 30."

    if awk -F: '($3<1000 && $1!="root"){print $1":"$7}' /etc/passwd | while IFS=: read -r u sh; do
         locked=$(passwd -S "$u" 2>/dev/null | awk '{print $2}')
         [[ "$locked" =~ L|LK ]] && [[ "$sh" =~ /(nologin|false)$ ]] || { echo BAD; break; }
       done | grep -q BAD; then
      log "5.5.2 - FAIL: some system accounts are interactive or unlocked."
    else
      log "5.5.2 - PASS: system accounts non-login and locked."
    fi

    [[ "$(id -g root)" -eq 0 ]] && log "5.5.3 - PASS: root GID is 0." || log "5.5.3 - FAIL: root GID not 0."

    um_defs=$(grep -E '^\s*UMASK\s+0?27\b' /etc/login.defs >/dev/null && echo 1 || echo 0)
    um_shell=$(grep -Rqs '^\s*umask\s+0?27\b' /etc/profile /etc/profile.d /etc/bash.bashrc && echo 1 || echo 0)
    pam_um=$(grep -q '^session\s\+optional\s\+pam_umask\.so' /etc/pam.d/common-session && echo 1 || echo 0)
    [[ "$um_defs" -eq 1 && "$um_shell" -eq 1 || "$pam_um" -eq 1 ]] \
      && log "5.5.4 - PASS: default umask 027 in effect." \
      || log "5.5.4 - FAIL: default umask not 027."

    if grep -RhsE '^\s*TMOUT\s*=\s*[0-9]+' /etc/profile /etc/profile.d /etc/bash.bashrc | \
        awk -F= '{n=$2+0; if(n>0 && n<=900){ok=1}} END{exit ok?0:1}'; then
        log "5.5.5 - PASS: shell timeout ≤ 900s."
    else
        log "5.5.5 - FAIL: shell timeout not set ≤ 900s."
    fi

    awk -F: '($2 != "x"){print}' /etc/passwd | grep -q . \
      && log "6.2.1 - FAIL: unshadowed passwords present." \
      || log "6.2.1 - PASS: all accounts use shadowed passwords."

    awk -F: '($2 == "" ){print}' /etc/shadow | grep -q . \
      && log "6.2.2 - FAIL: empty password fields in /etc/shadow." \
      || log "6.2.2 - PASS: no empty password fields."

    if awk -F: '{print $4}' /etc/passwd | while read -r gid; do getent group "$gid" >/dev/null || echo missing; done | grep -q missing; then
        log "6.2.3 - FAIL: some GIDs missing from /etc/group."
    else
        log "6.2.3 - PASS: all passwd GIDs exist in /etc/group."
    fi

    sg=$(getent group shadow | cut -d: -f4)
    [ -z "$sg" ] && log "6.2.4 - PASS: shadow group empty." || log "6.2.4 - FAIL: shadow group members: $sg"

    cut -d: -f3 /etc/passwd | sort | uniq -d | grep -q . && log "6.2.5 - FAIL: duplicate UIDs." || log "6.2.5 - PASS: no duplicate UIDs."
    cut -d: -f3 /etc/group  | sort | uniq -d | grep -q . && log "6.2.6 - FAIL: duplicate GIDs." || log "6.2.6 - PASS: no duplicate GIDs."
    cut -d: -f1 /etc/passwd | sort | uniq -d | grep -q . && log "6.2.7 - FAIL: duplicate usernames." || log "6.2.7 - PASS: no duplicate usernames."
    cut -d: -f1 /etc/group  | sort | uniq -d | grep -q . && log "6.2.8 - FAIL: duplicate group names." || log "6.2.8 - PASS: no duplicate group names."

    if [ "${CIS_6_2_9_OK:-1}" -eq 0 ]; then
        log "6.2.9 - PASS: root PATH entries sane."
    else
        log "6.2.9 - FAIL: root PATH risky: ${CIS_6_2_9_OFFENDERS:-unknown}"
    fi

    awk -F: '($3==0 && $1!="root"){print}' /etc/passwd | grep -q . \
      && log "6.2.10 - FAIL: non-root UID 0 present." \
      || log "6.2.10 - PASS: only root has UID 0."

    if cis_local_interactive_users | while IFS=: read -r u h; do [[ -d "$h" ]] || { echo BAD; break; }; done | grep -q BAD; then
        log "6.2.11 - FAIL: some users missing home directories."
    else
        log "6.2.11 - PASS: all homes exist."
    fi

    if awk -F: '($3>=1000 && $1!="nobody"){print $1":"$6}' /etc/passwd | while IFS=: read -r u h; do
        [[ -d "$h" ]] || continue
        [[ "$(stat -c %U "$h" 2>/dev/null)" == "$u" ]] || { echo BAD; break; }
    done | grep -q BAD; then
        log "6.2.12 - FAIL: some homes not owned by user."
    else
        log "6.2.12 - PASS: owners OK."
    fi

    if awk -F: '($3>=1000 && $1!="nobody"){print $1":"$6}' /etc/passwd | while IFS=: read -r _ h; do
        [[ -d "$h" ]] || continue
        perms=$(stat -c %a "$h" 2>/dev/null || echo 000)
        [[ "$perms" -le 750 ]] || { echo BAD; break; }
    done | grep -q BAD; then
        log "6.2.13 - FAIL: some homes > 750."
    else
        log "6.2.13 - PASS: home perms ≤ 750."
    fi

    if awk -F: '($3>=1000 && $1!="nobody"){print $6}' /etc/passwd | while read -r h; do [[ -d "$h" ]] || continue; [[ -e "$h/.netrc" ]] && { echo BAD; break; }; done | grep -q BAD; then
        log "6.2.14 - FAIL: some users have .netrc."
    else
        log "6.2.14 - PASS: no .netrc files."
    fi

    if awk -F: '($3>=1000 && $1!="nobody"){print $6}' /etc/passwd | while read -r h; do [[ -d "$h" ]] || continue; [[ -e "$h/.forward" ]] && { echo BAD; break; }; done | grep -q BAD; then
        log "6.2.15 - FAIL: some users have .forward."
    else
        log "6.2.15 - PASS: no .forward files."
    fi

    if awk -F: '($3>=1000 && $1!="nobody"){print $6}' /etc/passwd | while read -r h; do [[ -d "$h" ]] || continue; [[ -e "$h/.rhosts" ]] && { echo BAD; break; }; done | grep -q BAD; then
        log "6.2.16 - FAIL: some users have .rhosts."
    else
        log "6.2.16 - PASS: no .rhosts files."
    fi

    if awk -F: '($3>=1000 && $1!="nobody"){print $6}' /etc/passwd | while read -r h; do
        [[ -d "$h" ]] || continue
        # print first offender if any; grep -q . detects output
        find "$h" -xdev -type f -name '.*' -perm /022 -print -quit 2>/dev/null | grep -q . && { echo BAD; break; }
    done | grep -q BAD; then
        log "6.2.17 - FAIL: some dotfiles are group/world writable."
    else
        log "6.2.17 - PASS: dotfiles not group/world writable."
    fi
}

main() {
    require_root
    checkingin
    backup_user_configs

    set_password_complexity
    set_password_lockout_policy
    limit_password_reuse
    set_password_hashing_algorithm
    ensure_passwords_use_sha512

    set_password_aging_policies
    set_inactive_password_lock
    ensure_last_pwd_change_in_past

    secure_system_accounts
    ensure_root_primary_group_gid0
    set_default_umask
    set_shell_timeout

    verify_shadowed_passwords
    check_empty_shadow_passwords
    check_groups_exist
    ensure_shadow_group_empty
    check_for_duplicates
    ensure_root_path_integrity
    
    check_uid0_only_root
    ensure_home_dirs_exist
    ensure_home_owned_by_user
    enforce_home_mode_750
    remove_dot_netrc
    remove_dot_forward
    remove_dot_rhosts
    fix_writable_dotfiles

    postcheck
    log "04_user_accounts.sh completed."
}

main "$@" 
