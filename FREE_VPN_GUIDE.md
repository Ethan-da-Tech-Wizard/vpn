# Complete Free & Secure WireGuard VPN Guide

This guide explains how to deploy, manage, and connect to your own **100% Free, Private WireGuard VPN**.

---

## 🛡️ Why Self-Hosted WireGuard VPN?

| Commercial "Free" VPNs | Your Private WireGuard VPN |
| :--- | :--- |
| ❌ Sell your browsing data to advertisers | ✅ **Zero logs** — 100% open source & private |
| ❌ Inject third-party ads & trackers | ✅ No ads, no malware, no speed limits |
| ❌ Leaks real IP via DNS or IPv6 fallbacks | ✅ Hardened anti-leak firewall & encrypted DNS |
| ❌ Bandwidth caps (1GB - 10GB/mo) | ✅ Unlimited bandwidth |

### 🔒 How This Protects You
- **Facebook & Tracker Isolation**: Facebook, websites, and data brokers only see your VPN server's public IP address. Your home IP and physical location are hidden.
- **Workplace / Company Compatibility**: When you log into work accounts or SSO, your identity is authenticated through your credentials. The VPN encrypts all traffic between your device and the internet.

---

## ☁️ 100% Free Cloud Server Options

You can host this VPN server for **$0/month forever** using standard cloud free tiers:

### Option A: Oracle Cloud Always Free (Recommended)
1. Sign up for an **Oracle Cloud Free Tier** account (no charges ever for Always Free resources).
2. Create a Compute Instance:
   - **Image**: Ubuntu 22.04 LTS or 24.04 LTS
   - **Shape**: `VM.Standard.A1.Flex` (Up to 4 ARM vCPUs, 24 GB RAM — 100% Free)
3. Under **Networking** -> **Ingress Rules** for your VCN, add:
   - **UDP Port 51820** (WireGuard tunnel)
   - **TCP Port 3000** (Web Dashboard)
4. SSH into your server and clone/copy this folder.

### Option B: AWS / Google Cloud Free Tier
- **AWS**: t2.micro or t3.micro (12 months free, 750 hrs/month).
- **GCP**: e2-micro instance (Always Free tier in selected US regions).

---

## 🚀 Quick Setup & Installation

Run the automated installer on your server:

```bash
cd /home/ethan/vpn
./setup.sh
```

The script will automatically:
1. Enable kernel packet forwarding (`net.ipv4.ip_forward = 1`).
2. Install WireGuard, iptables, and anti-leak firewalls.
3. Configure encrypted DNS resolvers (Cloudflare `1.1.1.1` & Quad9 `9.9.9.9`).
4. Generate a default profile (`myphone.conf`).

---

## 🖥️ Launching the Web Dashboard

Start the sleek Glassmorphic Management Dashboard:

```bash
cd /home/ethan/vpn/dashboard
npm start
```

Access the dashboard at `http://YOUR_SERVER_IP:3000`:
- **Create new profiles** with 1-click for phone, laptop, or tablet.
- **Scan QR Code** directly from mobile screen.
- **Download `.conf`** configuration files for desktop.

---

## 💻 CLI Client Management Commands

You can also manage devices directly from the command line:

```bash
# Add a new client profile
./manage-vpn.sh add iphone

# Display QR code in terminal for mobile scanning
./manage-vpn.sh qr iphone

# List all active clients and IPs
./manage-vpn.sh list

# Revoke a device
./manage-vpn.sh revoke iphone

# View server status and connections
./manage-vpn.sh status
```

---

## 📱 Connecting Devices

### 1. iOS / Android Mobile App
1. Install the official **WireGuard** app from Apple App Store or Google Play Store.
2. Open the app, tap **+** -> **Scan from QR code**.
3. Scan the QR code shown in your Web Dashboard or terminal (`./manage-vpn.sh qr <device>`).
4. Toggle the switch to **ON**.

### 2. Windows & macOS Desktop
1. Download the official WireGuard client from [wireguard.com/install](https://www.wireguard.com/install/).
2. Open WireGuard -> **Add Tunnel** -> Select the downloaded `.conf` file from your Dashboard.
3. Click **Activate**.

### 3. Linux Desktop CLI
```bash
sudo apt install wireguard-tools
sudo wg-quick up /path/to/device.conf
```

---

## ✅ Verifying Privacy & IP Leak Protection

Once connected to your VPN:

1. Open your web browser and visit:
   - [https://ipleak.net](https://ipleak.net)
   - [https://dnsleaktest.com](https://dnsleaktest.com)
2. **Verify standard checks**:
   - **Your IP Address**: Must show your VPN server IP, NOT your home ISP IP.
   - **DNS Address**: Must show Cloudflare (`1.1.1.1`) or Quad9 (`9.9.9.9`), NOT your local ISP DNS.
   - **WebRTC / IPv6**: Must show zero leaks.
