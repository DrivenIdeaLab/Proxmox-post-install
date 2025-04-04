# Proxmox 8.3.5 Automated Post-Install Script Suite

---

The **Proxmox 8.3.5 Automated Post-Install** script is a comprehensive, fast, and secure setup tool. It disables enterprise nag, fixes repositories, installs essential tools, hardens security, optimizes kernel and system parameters, plus applies AMD and virtualization tweaks on **fresh Proxmox VE 8.3.5 installs**.

Automate your post-install setup and save hours 🌟.

---

## Features

- Disables enterprise subscription repo & removes nag screen  
- Switches to official no-subscription repo  
- Upgrades system packages to latest  
- Installs essential CLI tools  
- Installs kernel headers, haveged, fail2ban  
- Hardens SSH and GUI access with fail2ban rules  
- Applies AMD Ryzen/EPYC fixes automatically (if detected)  
- Optimizes kernel sysctl (limits, inotify, panic, TCP BBR, entropy, swappiness)  
- Adds optional OVH monitoring support  
- Restarts networking cleanly with ifupdown2  
- Fully compatible with **Proxmox VE 8.3.5**  
- Modular config via `.env` overrides file  
- Fully idempotent & safe to run multiple times  
- **Fast**: Runs in just minutes, reboot & done!

---

## Prerequisites

- Fresh **Proxmox VE 8.3.5** or existing cluster node upgrade  
- Root access

---

## Quick Start

1. **Login as root** (`ssh root@pve-ip`) or via console.  
2. **Download or create the script:**

```bash
nano /root/install-post.sh
# Paste the script content here, then save (Ctrl+X, then Y, enter)
chmod +x /root/install-post.sh
```

3. **(Optional)** Create an `.env` file to customize features:

```bash
nano /root/xs-install-post.env
```

Sample content:

```ini
XS_NOENTREPO="yes"
XS_NOSUBBANNER="yes"
XS_APTUPGRADE="yes"
XS_FAIL2BAN="yes"
XS_AMDFIXES="yes"
XS_APTIPV4="yes"
XS_UTILS="yes"
# disable OVH RTM if not on OVH:
XS_OVHRTM="no"
```

4. **Run the script**

```bash
/root/install-post.sh
```

5. When script finishes, **REBOOT** your server:

```bash
reboot
```

Enjoy a clean, secure, optimized Proxmox!

---

## Configuration via `.env` file

All options can be toggled via environment variables in `/root/xs-install-post.env` (or in the script folder).

| Option             | Default | Description                                              |
|--------------------|---------|----------------------------------------------------------|
| XS_NOENTREPO       | yes     | Disable Proxmox enterprise repo                          |
| XS_NOSUBBANNER     | yes     | Remove subscription nag popup                            |
| XS_APTUPGRADE      | yes     | Run full apt dist-upgrade                                |
| XS_UTILS           | yes     | Install common CLI utilities                             |
| XS_FAIL2BAN        | yes     | Install and configure fail2ban protection                |
| XS_AMDFIXES        | yes     | AMD kernel param fixes (idle bug, msr ignore)            |
| XS_APTIPV4         | yes     | Force apt over IPv4 only                                 |
| XS_IFUPDOWN2       | yes     | Install ifupdown2 (safe reloads)                         |
| XS_ENTROPY         | yes     | Install haveged (faster crypto, boots)                   |
| XS_KERNELHEADERS   | yes     | Kernel headers install                                   |
| XS_KSMTUNED        | yes     | Enable kernel share memory tuning                        |
| XS_LIMITS          | yes     | Increase ulimits and inotify watchers                    |
| XS_JOURNALD        | yes     | Limit journald size, enable persistence                  |
| XS_LOGROTATE       | yes     | Optimize logrotate policy                                |
| XS_MEMORYFIXES     | yes     | Swappiness/memory sysctl fixes                           |
| XS_TCPBBR          | yes     | Enable BBR TCP congestion control                        |
| XS_TCPFASTOPEN     | yes     | Enable TCP Fast Open                                     |
| XS_SWAPPINESS      | yes     | Enforce low swappiness                                   |
| XS_OVHRTM          | no      | Install OVH RTM monitoring agent                         |

---

## What this script **does NOT** do by default

- Enable enterprise or test repos  
- Set up Ceph (can be manually done after)  
- Install zfs-auto-snapshot (manual)  
- Configure PCI passthrough explicitly (VM-level)  
- Modify firewalls (uses fail2ban instead)  

Customize more as needed!

---

## Verification

After reboot, check:

- **No subscription nag** is gone  
- `pveversion -v` shows 8.3.5  
- No unconfigured packages (`dpkg -l | grep -i hold`)  
- `fail2ban-client status` shows active jails  
- `/etc/apt/sources.list.d/pve-no-subscription.list` active, enterprise repo disabled  
- Tuning sysctls applied:

```bash
sysctl vm.swappiness
sysctl net.ipv4.tcp_congestion_control
```

Expect `10` and `bbr`.

---

## Troubleshooting

- **Run as root user** only  
- Make sure Proxmox install is fresh/unconfigured or backed up  
- Network configuration safe with console/ILO available  
- DNS must work before/script will apt update correctly  
- If partial upgrade, reboot, re-run script once packages fix themselves

---

## How to customize further

- Fork or edit this script freely  
- Adjust `.env` vars to your needs  
- Add your branding, banners, docs  
- Add your favorite agents, backup clients, etc

Consider a private fork with internal secrets or keys not published publicly 

---

## Contributing & license

**Use, modify, and redistribute freely.**  
Credit appreciated (based on xshok-proxmox, tteck community, and Assistant GPT work).

For custom consulting, contact yourself or your team.

---

## About

Based on:

- Community knowledge from [Proxmox forum](https://forum.proxmox.com)  
- xShok’s [xshok-proxmox](https://github.com/extremeshok/xshok-proxmox)  
- tteck’s Proxmox scripts [[tteck.github.io](https://tteck.github.io/Proxmox/)]  

---

## Support

For issues, pull requests, or questions — please use your private repo, issue tracker, or team chat.

This script is provided **as-is, without warranty**.

Enjoy your optimized Proxmox VE!
