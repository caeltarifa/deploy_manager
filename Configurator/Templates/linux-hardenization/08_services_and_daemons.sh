#!/bin/bash
# Script: 08_services_and_daemons.sh
# Purpose: Remove/disable unnecessary services and daemons per CIS
# Covers: CIS 2.2.1–2.2.16, 2.3.1–2.3.6, 2.2.15

set -euo pipefail

checkingin() {
    LOG="/var/log/hardening_08_services_and_daemons.log"
    BACKUP_DIR="/root/hardening_backups/$(date +%F_%T)_08_services_and_daemons"
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

# 2.2.1 Ensure X Window System is not installed
remove_x_server() {
    if systemctl is-active --quiet display-manager || dpkg -l | grep -q '^ii\s\+nvidia-'; then
        log "2.2.1 - Detected desktop/NVIDIA; skipping X removal."
        return
    fi
    log "2.2.1 - Removing X Window System..."
    apt-get purge -y xserver-xorg* || true
}

# 2.2.2 Ensure Avahi Server is not installed
remove_avahi() {
    log "2.2.2 - Removing Avahi..."
    apt-get purge -y avahi-daemon avahi-autoipd || true
}

# 2.2.3 Ensure CUPS is not installed
remove_cups() {
    log "2.2.3 - Removing CUPS..."
    apt-get purge -y cups* || true
}

# 2.2.4 Ensure DHCP Server is not installed
remove_dhcp_server() {
    log "2.2.4 - Removing DHCP server..."
    apt-get purge -y isc-dhcp-server || true
}

# 2.2.6 Ensure NFS is not installed
remove_nfs() {
    log "2.2.6 - Removing NFS..."
    apt-get purge -y nfs-kernel-server || true
}

# 2.2.7 Ensure DNS Server is not installed
remove_dns_server() {
    log "2.2.7 - Removing DNS server..."
    apt-get purge -y bind9 dnsmasq || true
}

# 2.2.8 Ensure FTP Server is not installed
remove_ftp_server() {
    log "2.2.8 - Removing FTP server..."
    apt-get purge -y vsftpd || true
}

# 2.2.9 Ensure HTTP server is not installed
remove_http_server() {
    log "2.2.9 - Removing HTTP server..."
    apt-get purge -y apache2 nginx || true
}

# 2.2.10 Ensure IMAP/POP3 server is not installed
remove_imap_pop3_server() {
    log "2.2.10 - Removing IMAP/POP3 server..."
    apt-get purge -y dovecot-imapd dovecot-pop3d || true
}

# 2.2.11 Ensure Samba is not installed
remove_samba() {
    log "2.2.11 - Removing Samba..."
    apt-get purge -y samba || true
}

# 2.2.12 Ensure HTTP Proxy Server is not installed
remove_http_proxy() {
    log "2.2.12 - Removing HTTP proxy server..."
    apt-get purge -y squid || true
}

# 2.2.14 Ensure NIS Server is not installed
remove_nis_server() {
    log "2.2.14 - Removing NIS server..."
    apt-get purge -y nis || true
}

# 2.2.15 Ensure MTA is configured for local-only
restrict_mta() {
    log "2.2.15 - Configuring MTA for local-only..."
    if command -v postfix &>/dev/null; then
        cp /etc/postfix/main.cf "$BACKUP_DIR/postfix_main.cf.bak"
        postconf -e "inet_interfaces = loopback-only"
        systemctl restart postfix
    fi
}

# 2.2.16 Ensure rsync is not installed or masked
disable_rsync() {
    log "2.2.16 - Ensuring rsync is disabled..."
    systemctl mask rsync || true
    apt-get purge -y rsync || true
}

# 2.3.1 Ensure NIS client is not installed
remove_nis_client() {
    log "2.3.1 - Removing NIS client..."
    apt-get purge -y nis || true
}

# 2.3.2 Ensure rsh client is not installed
remove_rsh_client() {
    log "2.3.2 - Removing rsh client..."
    apt-get purge -y rsh-client rsh-redone-client || true
}

# 2.3.3 Ensure talk client is not installed
remove_talk_client() {
    log "2.3.3 - Removing talk client..."
    apt-get purge -y talk || true
}

# 2.3.4 Ensure telnet client is not installed
remove_telnet_client() {
    log "2.3.4 - Removing telnet client..."
    apt-get purge -y telnet || true
}

# 2.3.5 Ensure LDAP client is not installed
remove_ldap_client() {
    log "2.3.5 - Removing LDAP client..."
    apt-get purge -y ldap-utils || true
}

# 2.3.6 Ensure RPC is not installed
remove_rpc() {
    log "2.3.6 - Removing RPC..."
    apt-get purge -y rpcbind || true
}

postchecking(){
    apt autoremove -y
    log "Post-checking"
    chk_absent() { dpkg -l | awk '{print $1,$2}' | grep -Eq "^ii[[:space:]]+$1(\$|:)" && echo "present" || echo "absent"; }
    if systemctl is-active --quiet display-manager; then
        log "2.2.1 - INFO: Desktop detected; X present by design."
    elif dpkg -l | egrep -q '^ii[[:space:]]+(xserver-xorg|xserver-xorg-core|xorg)\b'; then
        log "2.2.1 - FAIL: X components installed."
    else
        log "2.2.1 - PASS: X Window System not installed."
    fi

    if dpkg -l | grep -Eq '^ii[[:space:]]+(avahi-daemon|avahi-autoipd)'; then
        log "2.2.2 - FAIL: Avahi installed."
    else
        log "2.2.2 - PASS: Avahi not installed."
    fi

    if dpkg -l | grep -Eq '^ii[[:space:]]+cups'; then
        log "2.2.3 - FAIL: CUPS packages present."
    else
        log "2.2.3 - PASS: CUPS not installed."
    fi

    if dpkg -l | grep -Eq '^ii[[:space:]]+isc-dhcp-server'; then
        log "2.2.4 - FAIL: DHCP server installed."
    else
        log "2.2.4 - PASS: DHCP server not installed."
    fi

    if dpkg -l | grep -Eq '^ii[[:space:]]+nfs-kernel-server'; then
        log "2.2.6 - FAIL: NFS server installed."
    else
        log "2.2.6 - PASS: NFS server not installed."
    fi

    if dpkg -l | grep -Eq '^ii[[:space:]]+(bind9|dnsmasq)'; then
        log "2.2.7 - FAIL: DNS server installed."
    else
        log "2.2.7 - PASS: DNS server not installed."
    fi

    if dpkg -l | grep -Eq '^ii[[:space:]]+vsftpd'; then
        log "2.2.8 - FAIL: FTP server installed."
    else
        log "2.2.8 - PASS: FTP server not installed."
    fi

    if dpkg -l | grep -Eq '^ii[[:space:]]+(apache2|nginx)'; then
        log "2.2.9 - FAIL: HTTP server installed."
    else
        log "2.2.9 - PASS: HTTP server not installed."
    fi

    if dpkg -l | grep -Eq '^ii[[:space:]]+(dovecot-imapd|dovecot-pop3d)'; then
        log "2.2.10 - FAIL: IMAP/POP3 server installed."
    else
        log "2.2.10 - PASS: IMAP/POP3 server not installed."
    fi

    if dpkg -l | egrep -q '^ii[[:space:]]+(samba|samba-common|samba-common-bin|smbclient|winbind)\b' \
        || systemctl is-active --quiet smbd 2>/dev/null \
        || systemctl is-active --quiet nmbd 2>/dev/null \
        || systemctl is-active --quiet winbind 2>/dev/null; then
        log "2.2.11 - FAIL: Samba installed or service active."
    else
        log "2.2.11 - PASS: Samba not installed."
    fi

    if dpkg -l | grep -Eq '^ii[[:space:]]+squid'; then
        log "2.2.12 - FAIL: Squid installed."
    else
        log "2.2.12 - PASS: HTTP proxy not installed."
    fi

    if dpkg -l | grep -Eq '^ii[[:space:]]+nis'; then
        log "2.2.14 - FAIL: NIS server installed."
    else
        log "2.2.14 - PASS: NIS server not installed."
    fi

    if command -v postconf >/dev/null 2>&1; then
        ii="$(postconf -h inet_interfaces 2>/dev/null || true)"
        if echo "$ii" | grep -qx 'loopback-only'; then
            # also confirm only loopback is listening on 25/tcp
            if ss -ltnp 2>/dev/null | awk '$4 ~ /:25$/ {print $4}' | grep -vqE '^(127\.0\.0\.1:25|\[::1\]:25)$'; then
                log "2.2.15 - FAIL: Postfix bound beyond loopback."
            else
                log "2.2.15 - PASS: Postfix inet_interfaces=loopback-only."
            fi
        else
            log "2.2.15 - FAIL: Postfix inet_interfaces is '$ii'."
        fi
    else
        log "2.2.15 - INFO: No Postfix detected; skip."
    fi

    if dpkg -l | grep -Eq '^ii[[:space:]]+rsync'; then
        # package present: must be masked/inactive
        if systemctl list-unit-files 2>/dev/null | grep -q '^rsync\.service'; then
            if systemctl is-enabled rsync 2>/dev/null | grep -qx 'masked' || ! systemctl is-active --quiet rsync 2>/dev/null; then
                log "2.2.16 - PASS: rsync service masked/inactive."
            else
                log "2.2.16 - FAIL: rsync service enabled/active."
            fi
        else
            log "2.2.16 - PASS: rsync package present but no service unit."
        fi
    else
        log "2.2.16 - PASS: rsync not installed."
    fi

    if dpkg -l | grep -Eq '^ii[[:space:]]+nis'; then
        log "2.3.1 - FAIL: NIS client installed."
    else
        log "2.3.1 - PASS: NIS client not installed."
    fi

    if dpkg -l | grep -Eq '^ii[[:space:]]+(rsh-client|rsh-redone-client)'; then
        log "2.3.2 - FAIL: rsh client installed."
    else
        log "2.3.2 - PASS: rsh client not installed."
    fi

    if dpkg -l | grep -Eq '^ii[[:space:]]+talk'; then
        log "2.3.3 - FAIL: talk client installed."
    else
        log "2.3.3 - PASS: talk client not installed."
    fi

    if dpkg -l | grep -Eq '^ii[[:space:]]+telnet'; then
        log "2.3.4 - FAIL: telnet client installed."
    else
        log "2.3.4 - PASS: telnet client not installed."
    fi

    if dpkg -l | grep -Eq '^ii[[:space:]]+ldap-utils'; then
        log "2.3.5 - FAIL: LDAP client installed."
    else
        log "2.3.5 - PASS: LDAP client not installed."
    fi

    if dpkg -l | grep -Eq '^ii[[:space:]]+rpcbind'; then
        log "2.3.6 - FAIL: RPC (rpcbind) installed."
    else
        log "2.3.6 - PASS: RPC (rpcbind) not installed."
    fi
    
}

main() {
    require_root
    checkingin
    remove_x_server
    remove_avahi
    remove_cups
    remove_dhcp_server
    remove_nfs
    remove_dns_server
    remove_ftp_server
    remove_http_server
    remove_imap_pop3_server
    remove_samba
    remove_http_proxy
    remove_nis_server
    restrict_mta
    disable_rsync

    remove_nis_client
    remove_rsh_client
    remove_talk_client
    remove_telnet_client
    remove_ldap_client
    remove_rpc
    postchecking

    log "08_services_and_daemons.sh completed."
}

main "$@"

# NOTE: 
# * purge the X Window System (xserver-xorg)—potentially 
# breaking the GUI/NVIDIA stack—unless a desktop display manager 
# or NVIDIA driver is detected, in which case it’s skipped.