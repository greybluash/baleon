---
layout: post
title: "Build a Portable Raspberry Pi 5 Router with OpenWRT, LTE, WireGuard & Jellyfin"
description: "Step-by-step guide to building a portable router using Raspberry Pi 5 with OpenWRT, NVMe storage, LTE failover, WireGuard VPN, and Jellyfin streaming."
date: 2025-04-21 15:01:36 +0300
image: '/images/pi-supply-1920-unsplash.jpg'
tags: [tech,raspberrypi]
---
Photo by <a href="https://unsplash.com/@pisupply?utm_content=creditCopyText&utm_medium=referral&utm_source=unsplash">Pi Supply</a> on <a href="https://unsplash.com/photos/green-and-black-circuit-board-SvRjqO-A51g?utm_content=creditCopyText&utm_medium=referral&utm_source=unsplash">Unsplash</a>
      

Want a portable router that can use public Wi-Fi, LTE/3G fallback, run WireGuard, and even stream your media with Jellyfin? With a Raspberry Pi 5, OpenWRT, and a few add-ons, you can create a travel-ready powerhouse. Here's the full guide!

## 🧰 What You’ll Need

- Raspberry Pi 5 with active cooling  
- NVMe SSD (with a compatible USB 3.0 adapter or HAT)  
- USB LTE/3G modem (like Quectel EC25 or SIM7600)  
- External battery pack or 12V power supply  
- microSD card (for OpenWRT boot)  
- Optional: USB Wi-Fi adapter  
- Ethernet cable(s)

---

## 🧱 Step 1: Flash and Install OpenWRT

1. **Download Raspberry Pi 5 image** (use snapshot until official stable is out):  
   [OpenWRT Snapshots](https://downloads.openwrt.org/snapshots/targets/bcm27xx/bcm2712/)

2. **Flash it to your microSD card** using Balena Etcher:

   ```bash
   balenaEtcher --flash openwrt-*-rpi5.img.gz
   ```

3. Insert the microSD, connect Ethernet or serial, and power on.

4. SSH in:

   ```bash
   ssh root@192.168.1.1
   ```

---

## 💾 Step 2: Mount NVMe Storage via LuCI

1. **Install required packages** for disk management in LuCI:

   ```bash
   opkg update
   opkg install luci-app-fstab block-mount kmod-usb-storage kmod-fs-ext4 e2fsprogs
   ```

2. **Plug in your NVMe drive** via USB or HAT. Check it's detected:

   ```bash
   lsblk
   ```

   You should see something like `/dev/sda1`.

3. **Format the drive** (if needed):

   ```bash
   mkfs.ext4 /dev/sda1
   ```

4. **Go to LuCI**: Navigate to **System > Mount Points**

5. Click **“Add”**, then:
   - Set **device** to `/dev/sda1`
   - Choose **mount point** as `/mnt/nvme`
   - Check **Enable this mount**
   - Click **Save & Apply**

6. If you want it mounted now without rebooting:

   ```bash
   block mount
   ```

7. Verify it’s mounted:

   ```bash
   df -h
   ```

   You should see `/mnt/nvme` listed.

---

## 🌐 Step 3: Connect to Public Wi-Fi

1. Install packages:

   ```bash
   opkg update
   opkg install wpad-basic-wolfssl luci-proto-wifi
   ```

2. Plug in USB Wi-Fi adapter and reboot if necessary.

3. Go to **Network > Wireless** in LuCI:
   - Click **Scan** on the second adapter (e.g., `wlan1`)
   - Join a public Wi-Fi network
   - Create a new interface (e.g., `wwan`), set protocol to DHCP
   - Assign it to a new firewall zone `wwan`

---

## 📡 Step 4: Add 3G/LTE Connectivity

1. Install packages:

   ```bash
   opkg install chat comgt kmod-usb-serial-option kmod-usb-serial-wwan \
       kmod-usb-net-qmi-wwan uqmi luci-proto-qmi
   ```

2. Configure LTE interface:

   ```bash
   uci set network.lte=interface
   uci set network.lte.proto='qmi'
   uci set network.lte.device='/dev/cdc-wdm0'
   uci set network.lte.apn='your.apn.here'
   uci commit network
   /etc/init.d/network restart
   ```

---

## 🔁 Step 5: Setup Multi-WAN Failover

1. Install mwan3:

   ```bash
   opkg install mwan3 luci-app-mwan3
   ```

2. Configure interfaces and metrics:

   ```bash
   uci set mwan3.wan.metric='10'
   uci set mwan3.wwan.metric='20'
   uci set mwan3.lte.metric='30'
   uci commit mwan3
   /etc/init.d/mwan3 restart
   ```

3. Fine-tune rules and health checks in LuCI under **Network > Load Balancing**.

---

## 🔐 Step 6: Install WireGuard VPN

1. Install packages:

   ```bash
   opkg install wireguard-tools luci-proto-wireguard luci-app-wireguard
   ```

2. Generate keys:

   ```bash
   wg genkey | tee privatekey | wg pubkey > publickey
   ```

3. Add a WireGuard interface in LuCI or configure manually in `/etc/config/network`.

4. Set firewall zone and routing rules to allow VPN traffic.

---

## 🎥 Step 7: Run Jellyfin on Local Network

1. Install Docker:

   ```bash
   opkg update
   opkg install docker docker-compose luci-app-dockerman
   /etc/init.d/dockerd start
   ```

2. Create a `docker-compose.yml` file:

   ```yaml
   version: '3.8'
   services:
     jellyfin:
       image: jellyfin/jellyfin
       container_name: jellyfin
       network_mode: host
       volumes:
         - /mnt/nvme/jellyfin/config:/config
         - /mnt/nvme/media:/media
       restart: unless-stopped
   ```

3. Start the container:

   ```bash
   docker compose up -d
   ```

4. Access Jellyfin from a LAN client: `http://192.168.1.1:8096`

---

## 🧠 Optional Tweaks

- Use `adblock` or `dnscrypt-proxy` for privacy
- Install Zerotier or Tailscale for remote access
- Share storage via Samba or NFS
- Setup a captive portal for guest access

---

## 🎉 You’re Done!

You now have a fully mobile, multi-WAN failover router with local streaming, VPN security, and massive storage—all powered by a Pi 5. Perfect for road trips, hotel Wi-Fi, or remote work!
