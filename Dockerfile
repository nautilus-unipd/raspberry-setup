FROM ros:jazzy

USER root

# Set no password to 'ubuntu'
RUN apt-get update && apt-get install -y sudo && \
    echo 'ubuntu ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/ubuntu-nopasswd && \
    chmod 0440 /etc/sudoers.d/ubuntu-nopasswd

# Install packages
RUN apt-get update && \
    apt-get install -y python3-pip git python3-jinja2 python3-colcon-meson \
    libboost-dev libgnutls28-dev openssl libtiff5-dev pybind11-dev \
    qtbase5-dev libqt5core5a libqt5gui5 libqt5widgets5 meson cmake \
    python3-yaml python3-ply libglib2.0-dev libgstreamer-plugins-base1.0-dev \
    libboost-program-options-dev libdrm-dev libexif-dev ninja-build \
    libpng-dev libopencv-dev libavdevice-dev libepoxy-dev

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

# Set ubuntu as default user
USER ubuntu

# Set up .bashrc
ENV HOME=/home/ubuntu
RUN echo "cd \$HOME" >> $HOME/.bashrc && \
    echo "source /opt/ros/jazzy/local_setup.bash" >> $HOME/.bashrc && \
    cd $HOME