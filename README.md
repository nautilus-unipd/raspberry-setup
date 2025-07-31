# raspberry-setup

**Raspberry Pi 5 Setup Instructions**

This repository contains the Dockerfile and container image to run Ubuntu 24.04 (Noble) with ROS 2 Jazzy on a Raspberry Pi 5. It includes all **libcamera** and **rpicam-apps** modules pre-installed, so you can use Raspberry Pi MIPI cameras out of the box.

## Requirements

* Raspberry Pi 5 with 64-bit Raspberry Pi OS
* Internet connection

## 1. Install 64-bit Raspberry Pi OS

1. Download and install **Raspberry Pi Imager**: [https://www.raspberrypi.com/software/](https://www.raspberrypi.com/software/)
2. Select the OS: **Raspberry Pi OS (64-bit)**
3. Write the image to your SD card and boot your Raspberry Pi

## 2. Install Docker Engine

Follow the official Docker installation steps for Debian: [https://docs.docker.com/engine/install/debian/](https://docs.docker.com/engine/install/debian/)

### Add Docker’s official GPG key

```bash
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
```

### Add Docker repository

```bash
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
```

### Install Docker Engine and plugins

```bash
sudo apt-get install -y \
  docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-buildx-plugin \
  docker-compose-plugin
```

## 3. Add "admin" to sudoers and to "docker" group

```bash
echo "admin   ALL=(ALL:ALL) ALL" | sudo tee -a /etc/sudoers
sudo usermod -aG docker admin
```

## 4. Modify ssh settings
```bash
mkdir -p ~/.ssh && chmod 700 ~/.ssh && touch ~/.ssh/config && chmod 600 ~/.ssh/config && \
grep -q "Host raspberrypi" ~/.ssh/config || echo -e "\nHost raspberrypi\n    HostName raspberrypi.local\n    User admin\n    ServerAliveInterval 30\n    ServerAliveCountMax 5" >> ~/.ssh/config
```

## 5. Test the system

Connect a MIPI camera to the CSI port, then run:

```bash
rpicam-hello --list-cameras
```

You should see the connected camera(s) listed. If you get output like:

```
Available cameras
-----------------
0 : imx708 [4608x2592 10-bit RGGB]
```

then your camera is working correctly.

---

## 5. Share Internet Access with Jetson Nano (via Ethernet)

To allow the Jetson Nano to access the internet through the Raspberry Pi (using Ethernet), run the following on the Raspberry Pi:

```bash
# Create a shared network connection over eth0
sudo nmcli connection add type ethernet ifname eth0 con-name jetson-network-shared ipv4.method shared ipv4.addresses 192.168.2.1/24

# Enable IP forwarding and NAT
sudo apt update
sudo apt install iptables-persistent

sudo iptables -t nat -A POSTROUTING -s 192.168.2.0/24 -o wlan0 -j MASQUERADE
sudo iptables -A FORWARD -i wlan0 -o eth0 -m state --state RELATED,ESTABLISHED -j ACCEPT
sudo iptables -A FORWARD -i eth0 -o wlan0 -j ACCEPT

# Save firewall rules
sudo netfilter-persistent save
```

Once configured, the Jetson Nano connected to the Raspberry Pi via Ethernet should have internet access.
.
