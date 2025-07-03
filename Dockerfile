FROM ros:jazzy

USER root

# Create, if not existing, 'ubuntu' user
RUN id -u ubuntu &>/dev/null || useradd -m -s /bin/bash ubuntu

# Set no password to 'ubuntu'
RUN apt-get update && apt-get install -y sudo && \
    echo 'ubuntu ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/ubuntu-nopasswd && \
    chmod 0440 /etc/sudoers.d/ubuntu-nopasswd

# Install base dependencies
RUN apt-get update && \
    apt-get install -y python3-pip git python3-jinja2 python3-colcon-meson \
    libboost-dev libgnutls28-dev openssl libtiff5-dev pybind11-dev \
    qtbase5-dev libqt5core5a libqt5gui5 libqt5widgets5 meson cmake \
    python3-yaml python3-ply libglib2.0-dev libgstreamer-plugins-base1.0-dev \
    libboost-program-options-dev libdrm-dev libexif-dev ninja-build \
    libpng-dev libopencv-dev libavdevice-dev libepoxy-dev \
    gstreamer1.0-tools gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-libcamera \
    ros-jazzy-cv-bridge python3-opencv 

# Install python dependencies
COPY requirements.txt /tmp/requirements.txt
RUN pip3 install --no-cache-dir --break-system-packages -r /tmp/requirements.txt

# Build and install libcamera
WORKDIR /opt
RUN git clone https://github.com/raspberrypi/libcamera.git && \
    cd libcamera && \
    meson setup build --buildtype=release \
      -Dpipelines=rpi/vc4,rpi/pisp \
      -Dipas=rpi/vc4,rpi/pisp \
      -Dv4l2=enabled -Dgstreamer=enabled -Dtest=false \
      -Dlc-compliance=disabled -Dcam=disabled -Dqcam=disabled \
      -Ddocumentation=disabled -Dpycamera=enabled && \
    ninja -C build && \
    ninja -C build install

# Build and install rpicam-apps
WORKDIR /opt
RUN git clone https://github.com/raspberrypi/rpicam-apps.git && \
    cd rpicam-apps && \
    meson setup build \
      -Denable_libav=enabled \
      -Denable_drm=enabled \
      -Denable_egl=enabled \
      -Denable_qt=enabled \
      -Denable_opencv=enabled \
      -Denable_tflite=disabled \
      -Denable_hailo=disabled && \
    meson compile -C build && \
    meson install -C build && \
    ldconfig

# Set environment for the ubuntu user
ENV HOME=/home/ubuntu

# Set up .bashrc for ubuntu
RUN echo "cd \$HOME" >> /home/ubuntu/.bashrc && \
    echo "source /opt/ros/jazzy/local_setup.bash" >> /home/ubuntu/.bashrc && \
    echo "export GST_PLUGIN_PATH=/opt/libcamera/build/src/gstreamer/" >> /home/ubuntu/.bashrc && \
    echo "cd \$HOME/sensing-rigs-ros2/ros2_ws" >> /home/ubuntu/.bashrc && \
    echo "[ -f install/setup.bash ] && source install/setup.bash" >> /home/ubuntu/.bashrc && \
    chown ubuntu:ubuntu /home/ubuntu/.bashrc

# Add auto build command (with colcon)
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["bash"]

# Switch to the ubuntu user
USER ubuntu
WORKDIR /home/ubuntu
