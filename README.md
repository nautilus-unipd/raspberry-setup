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

Follow the official Docker installation steps for Ubuntu:

### Add Docker’s official GPG key

```bash
sudo apt-get update
sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL \
  https://download.docker.com/linux/ubuntu/gpg \
  -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
```

### Add Docker repository

```bash
echo \
  "deb [arch=$(dpkg --print-architecture) \
  signed-by=/etc/apt/keyrings/docker.asc] \
  https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" \
  | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
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

## 3. Run the Docker container

Start the container in interactive mode, with elevated privileges and direct access to video devices:

```bash
sudo docker run -it --privileged \
  --net=host \
  -v /dev:/dev/ \
  -v /run/udev/:/run/udev/ \
  --group-add video \
  ghcr.io/nautilus-unipd/raspberry-setup:latest
```

Inside the container, you will find Ubuntu 24.04 and ROS 2 Jazzy already configured and ready to use with Raspberry Pi MIPI cameras.

## 4. Test the system

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
