#!/usr/bin/env bash
set -euo pipefail
shopt -s inherit_errexit nullglob

################################################################################
# Proxmox 8.3.5 Automated Post-Install Script (April 2025)
# Maintained by Assistant GPT, based on xshok, tteck, and upgrades by user
################################################################################

# Location of optional .env overrides
ENV_FILE="./xs-install-post.env"
[[ -f "$ENV_FILE" ]] && source "$ENV_FILE" || true

# ========= Defaults if no env override ==========
XS_NOENTREPO="${XS_NOENTREPO:-yes}"            # disable enterprise repo
XS_NOSUBBANNER="${XS_NOSUBBANNER:-yes}"        # remove nag
XS_APTUPGRADE="${XS_APTUPGRADE:-yes}"          # upgrade packages
XS_UTILS="${XS_UTILS:-yes}"
XS_FAIL2BAN="${XS_FAIL2BAN:-yes}"
XS_AMDFIXES="${XS_AMDFIXES:-yes}"
XS_APTIPV4="${XS_APTIPV4:-yes}"
XS_IFUPDOWN2="${XS_IFUPDOWN2:-yes}"
XS_ENTROPY="${XS_ENTROPY:-yes}"
XS_KERNELHEADERS="${XS_KERNELHEADERS:-yes}"
XS_KSMTUNED="${XS_KSMTUNED:-yes}"
XS_LIMITS="${XS_LIMITS:-yes}"
XS_JOURNALD="${XS_JOURNALD:-yes}"
XS_LOGROTATE="${XS_LOGROTATE:-yes}"
XS_MEMORYFIXES="${XS_MEMORYFIXES:-yes}"
XS_TCPBBR="${XS_TCPBBR:-yes}"
XS_TCPFASTOPEN="${XS_TCPFASTOPEN:-yes}"
XS_SWAPPINESS="${XS_SWAPPINESS:-yes}"
XS_OVHRTM="${XS_OVHRTM:-no}"

echo "Running Proxmox VE 8.3.5 Post-Install Script..."

## IPv4-only for APT acceleration & reliability
if [[ "$XS_APTIPV4" == "yes" ]]; then
  echo 'Acquire::ForceIPv4 "true";' >/etc/apt/apt.conf.d/99force-ipv4
fi

## Disable Enterprise repo, enable no-subscription
if [[ "$XS_NOENTREPO" == "yes" ]]; then
  sed -ri 's|^deb |#deb |' /etc/apt/sources.list.d/pve-enterprise.list || true
  cat >/etc/apt/sources.list.d/pve-no-subscription.list <<EOF
deb http://download.proxmox.com/debian/pve bookworm pve-no-subscription
EOF
fi

## Remove subscription nag on PVE 8
if [[ "$XS_NOSUBBANNER" == "yes" ]]; then
cat >/etc/apt/apt.conf.d/xs-no-nag <<'EOF'
DPkg::Post-Invoke { "if [ -f /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js ]; then
sed -i 's/data.status\ !==\ 'Active'/false/' /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js; fi"; };
EOF
apt --reinstall install proxmox-widget-toolkit -y || true
fi

## Upgrade apt
if [[ "$XS_APTUPGRADE" == "yes" ]]; then
  apt-get update -y && apt-get dist-upgrade -y
fi

## Common tools
if [[ "$XS_UTILS" == "yes" ]]; then
  apt-get install -y sudo curl wget git vim nano htop net-tools dnsutils build-essential unzip zip pve-headers module-assistant ca-certificates fail2ban iperf software-properties-common debian-archive-keyring pigz zfsutils-linux proxmox-backup-restore-image chrony haveged
fi

## fail2ban PVE UI brute force protection
if [[ "$XS_FAIL2BAN" == "yes" ]]; then
  cat >/etc/fail2ban/filter.d/proxmox.conf <<'EOF'
[Definition]
failregex = pvedaemon\[\d+\]: authentication failure; rhost=<HOST> user=.*
EOF

  cat >/etc/fail2ban/jail.d/proxmox.conf <<'EOF'
[proxmox]
enabled = true
port    = 8006
filter  = proxmox
maxretry = 4
findtime = 600
bantime = 3600
logpath  = /var/log/daemon.log
EOF

  systemctl enable --now fail2ban
fi

## OVH RTM Agent (skip or uncomment below)
if [[ "$XS_OVHRTM" == "yes" ]]; then
  wget -O- https://github.com/ovh/rtm/archive/master.tar.gz | tar zxC /root
  bash /root/rtm-master/install.sh || true
fi

## AMD CPU fixes if AMD detected
if [[ "$XS_AMDFIXES" == "yes" ]] && grep -qi AMD /proc/cpuinfo; then
  sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="idle=nomwait /' /etc/default/grub || true
  update-grub
  echo "options kvm ignore_msrs=Y" >> /etc/modprobe.d/kvm.conf
  echo "options kvm report_ignored_msrs=N" >> /etc/modprobe.d/kvm.conf
fi

## Enable BBR congestion control and FastOpen
if [[ "$XS_TCPBBR" == "yes" ]]; then
echo "net.core.default_qdisc=fq"      > /etc/sysctl.d/99-xs-net.conf
echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.d/99-xs-net.conf
fi
if [[ "$XS_TCPFASTOPEN" == "yes" ]]; then
echo "net.ipv4.tcp_fastopen=3" >>/etc/sysctl.d/99-xs-net.conf
fi

## Kernel panic on crash, restart after 10 seconds
cat >/etc/sysctl.d/99-xs-panic.conf <<EOF
kernel.panic=10
kernel.panic_on_oops=1
kernel.hardlockup_panic=1
EOF

## Increase limits
if [[ "$XS_LIMITS" == "yes" ]]; then
cat >/etc/security/limits.d/99-xs-limits.conf <<EOF
* soft nofile 1048576
* hard nofile 1048576
* soft nproc 1048576
* hard nproc 1048576
EOF
cat >/etc/sysctl.d/99-xs-inotify.conf <<EOF
fs.inotify.max_user_watches=1048576
fs.inotify.max_user_instances=512
fs.inotify.max_queued_events=16384
EOF
fi

## Improve journald and logrotate
if [[ "$XS_JOURNALD" == "yes" ]]; then
cat >/etc/systemd/journald.conf <<EOF
[Journal]
Storage=persistent
SystemMaxUse=64M
Compress=yes
EOF
systemctl restart systemd-journald
journalctl --vacuum-size=64M
fi
if [[ "$XS_LOGROTATE" == "yes" ]]; then
cat >/etc/logrotate.conf <<EOF
daily
rotate 7
compress
delaycompress
notifempty
create
include /etc/logrotate.d
EOF
fi

## Kernel memory tweaks
if [[ "$XS_MEMORYFIXES" == "yes" ]]; then
cat >/etc/sysctl.d/99-xs-memory.conf <<EOF
vm.swappiness=10
vm.min_free_kbytes=1048576
vm.overcommit_memory=1
vm.max_map_count=262144
EOF
fi

## Swappiness fix explicit
if [[ "$XS_SWAPPINESS" == "yes" ]]; then
echo "vm.swappiness=10" >> /etc/sysctl.d/99-xs-memory.conf
fi

## Install ifupdown2 for safe network reloads if desired
if [[ "$XS_IFUPDOWN2" == "yes" ]]; then
  apt-get install -y ifupdown2 && systemctl restart networking
fi

## Entropy improvements
if [[ "$XS_ENTROPY" == "yes" ]]; then
  apt-get install -y haveged
  systemctl enable --now haveged
fi

## Enable KSM tuning
if [[ "$XS_KSMTUNED" == "yes" ]]; then
  systemctl enable --now ksmtuned || true
fi

## Kernel headers for DKMS
if [[ "$XS_KERNELHEADERS" == "yes" ]]; then
  apt-get install -y pve-headers
fi

## Time sync via chrony (use instead of NTP)
systemctl enable --now chrony

## Finalize
update-initramfs -u -k all
update-grub || true
pve-efiboot-tool refresh || true
apt-get autoremove -y && apt-get autoclean -y

echo "Proxmox 8.3.5 Post-install complete! Please reboot now."
exit 0
