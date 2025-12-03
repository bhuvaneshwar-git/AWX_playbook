#!/bin/bash

# === CONFIGURATION ===
DOMAIN="yaar.flattrade.in"
REALM="YAAR.FLATTRADE.IN"
JOIN_USER="saravanan.m"
AD_DNS="192.168.7.12"  # ⚠️ Replace with your actual AD DNS IP

# === FUNCTION: Exit on error ===
error_exit() {
    echo -e "\n[✖] ERROR: $1"
    exit 1
}

log_info() {
    echo -e "\n[✔] $1"
}

# === 1. Check root ===
if [[ $EUID -ne 0 ]]; then
    error_exit "Run this script as root (sudo)."
fi

# === 2. Install required packages ===
log_info "Installing required packages..."
apt update -y || error_exit "apt update failed"
apt install -y realmd sssd sssd-tools samba-common packagekit adcli krb5-user \
    oddjob oddjob-mkhomedir libnss-sss libpam-sss || error_exit "Package installation failed"

# === 3. Configure DNS for AD resolution ===
log_info "Configuring AD DNS ($AD_DNS)..."
RESOLVED="/etc/systemd/resolved.conf"
if ! grep -q "^DNS=" "$RESOLVED"; then
    echo -e "\n[Resolve]\nDNS=$AD_DNS\nDomains=$DOMAIN" >> "$RESOLVED"
else
    sed -i "s/^DNS=.*/DNS=$AD_DNS/" "$RESOLVED"
    sed -i "s/^Domains=.*/Domains=$DOMAIN/" "$RESOLVED"
fi
systemctl restart systemd-resolved || error_exit "Failed to restart DNS service"

# === 4. Discover domain ===
log_info "Discovering AD domain..."
realm discover "$DOMAIN" || error_exit "Failed to discover AD domain"

# === 5. Join domain ===
log_info "Joining domain using user: $JOIN_USER"
realm join --user="$JOIN_USER" "$DOMAIN" || error_exit "Failed to join domain"

# === 6. Permit AD users (login only) ===
log_info "Allowing all AD users to log in (without sudo)..."
realm permit --all || error_exit "Failed to permit AD users"

# === 7. Enable home directory creation ===
log_info "Enabling home directory auto-creation for AD users..."
PAM_FILE="/etc/pam.d/common-session"
if ! grep -q "pam_mkhomedir.so" "$PAM_FILE"; then
    echo "session required pam_mkhomedir.so skel=/etc/skel/ umask=0077" >> "$PAM_FILE"
fi

systemctl enable oddjobd && systemctl start oddjobd || error_exit "Failed to enable/start oddjobd"

# === 8. Configure /etc/sssd/sssd.conf ===
log_info "Writing secure SSSD config..."
cat > /etc/sssd/sssd.conf <<EOF
[sssd]
domains = $DOMAIN
config_file_version = 2
services = nss, pam

[domain/$DOMAIN]
ad_domain = $DOMAIN
krb5_realm = $REALM
realmd_tags = manages-system joined-with-adcli
cache_credentials = True
id_provider = ad
access_provider = ad
ldap_id_mapping = True
default_shell = /bin/bash
override_homedir = /home/%u
use_fully_qualified_names = False
EOF

chmod 600 /etc/sssd/sssd.conf || error_exit "Failed to set permissions"
systemctl restart sssd || error_exit "Failed to restart SSSD"

# === 9. Validate ===
log_info "Verifying AD user resolution..."
id "$JOIN_USER" || error_exit "AD user not resolvable after join"

# === DONE ===
log_info "🎉 SUCCESS: System joined to $DOMAIN"
log_info "✔ Local + AD logins are allowed"
log_info "✔ Home directories will be created"
log_info "✔ No sudo access is granted to AD users"
