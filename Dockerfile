FROM ros:jazzy

USER root

# Create, if not existing, 'ubuntu' user
RUN id -u ubuntu &>/dev/null || useradd -m -s /bin/bash ubuntu

# Set no password to 'ubuntu'
RUN apt update && apt install -y sudo && \
    echo 'ubuntu ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/ubuntu-nopasswd && \
    chmod 0440 /etc/sudoers.d/ubuntu-nopasswd

RUN apt update && apt install -y --no-install-recommends \
        sudo \
        python3-pip \
        python3-libcamera libcamera-tools \
        libcamera-dev \
        gstreamer1.0-tools \
        && apt clean \
        && rm -rf /var/lib/apt/lists/*

# Install libcap-dev for python-prctl (required by picamera2)
RUN apt update && apt install -y libcap-dev python3-dev && apt clean && rm -rf /var/lib/apt/lists/*

# Install base dependencies 
RUN apt update && \
    apt install -y \
    git python3-jinja2 python3-colcon-meson \
    libboost-dev libgnutls28-dev openssl libtiff5-dev pybind11-dev \
    qtbase5-dev libqt5core5a libqt5gui5 libqt5widgets5 meson cmake \
    python3-yaml python3-ply libglib2.0-dev libgstreamer-plugins-base1.0-dev \
    libboost-program-options-dev libdrm-dev libexif-dev ninja-build \
    libpng-dev libopencv-dev libavdevice-dev libepoxy-dev \
    gstreamer1.0-tools gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-libcamera \
    ros-jazzy-cv-bridge python3-opencv ros-jazzy-image-view && \
    apt clean && rm -rf /var/lib/apt/lists/* 

# Install python dependencies
COPY requirements.txt /tmp/requirements.txt
RUN pip3 install --ignore-installed --no-cache-dir --break-system-packages -r /tmp/requirements.txt

# Create pykms stub for picamera2 compatibility
COPY pykms_stub.py /usr/local/lib/python3.12/dist-packages/pykms.py
COPY kms_stub.py /usr/local/lib/python3.12/dist-packages/kms.py

# Build and install libcamera
WORKDIR /opt
RUN git clone https://github.com/raspberrypi/libcamera.git && \
    cd libcamera && \
    meson setup build --buildtype=release \
      -Dpipelines=rpi/vc4,rpi/pisp \
      -Dipas=rpi/vc4,rpi/pisp \
      -Dv4l2=enabled -Dgstreamer=enabled -Dtest=false \
      -Dlc-compliance=disabled -Dcam=disabled -Dqcam=disabled \
      -Ddocumentation=disabled -Dpycamera=enabled \
      --prefix=/usr/local && \
    ninja -C build && \
    ninja -C build install && \
    ldconfig && \
    echo "/usr/local/lib" >> /etc/ld.so.conf.d/libcamera.conf && \
    ARCH=$(uname -m) && echo "/usr/local/lib/${ARCH}-linux-gnu" >> /etc/ld.so.conf.d/libcamera.conf && \
    ldconfig

# Verify libcamera installation and ensure Python bindings are accessible
RUN PYTHON_VERSION=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')") && \
    find /usr/local -name "_libcamera*.so" -exec ln -sf {} /usr/local/lib/python${PYTHON_VERSION}/dist-packages/ \; && \
    find /usr/local -name "libcamera" -type d -path "*/site-packages/*" -exec cp -r {} /usr/local/lib/python${PYTHON_VERSION}/dist-packages/ \;

# Install picamera2 Python library and test all camera-related imports
RUN pip3 install --no-cache-dir --break-system-packages picamera2 && \
    python3 -c "import libcamera; print('libcamera import successful')" || echo "libcamera import failed" && \
    python3 -c "import pykms; print('pykms stub import successful')" || echo "pykms import failed" && \
    python3 -c "import kms; print('kms stub import successful')" || echo "kms import failed" && \
    python3 -c "import picamera2; print('picamera2 import successful')" || echo "picamera2 import failed"

# Build and install rpicam-apps (optional command-line camera tools)
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

# --- ENVIRONMENT SETUP FOR UBUNTU USER ---
ENV HOME=/home/ubuntu

# Dynamically detect architecture and Python version, then set system-wide environment variables
RUN ARCH=$(uname -m) && \
    PYTHON_VERSION=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')") && \
    echo "export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig:/usr/local/lib/${ARCH}-linux-gnu/pkgconfig:\$PKG_CONFIG_PATH" >> /etc/environment && \
    echo "export LD_LIBRARY_PATH=/usr/local/lib:/usr/local/lib/${ARCH}-linux-gnu:\$LD_LIBRARY_PATH" >> /etc/environment && \
    echo "export GST_PLUGIN_PATH=/usr/local/lib/gstreamer-1.0:\$GST_PLUGIN_PATH" >> /etc/environment && \
    echo "export PYTHONPATH=/usr/local/lib/python${PYTHON_VERSION}/dist-packages:/usr/local/lib/python${PYTHON_VERSION}/site-packages:/usr/local/lib/python3/dist-packages:/usr/local/lib/python3.12/site-packages:/usr/local/lib/python${PYTHON_VERSION}/site-packages:\$PYTHONPATH" >> /etc/environment

# Set default Docker environment variables for libcamera, GStreamer, and Python
ENV PKG_CONFIG_PATH=/usr/local/lib/pkgconfig
ENV LD_LIBRARY_PATH=/usr/local/lib
ENV GST_PLUGIN_PATH=/usr/local/lib/gstreamer-1.0

# Configure .bashrc for ubuntu user with ROS and camera environment
RUN ARCH=$(uname -m) && \
    PYTHON_VERSION=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')") && \
    echo "cd \$HOME" >> /home/ubuntu/.bashrc && \
    echo "source /opt/ros/jazzy/local_setup.bash" >> /home/ubuntu/.bashrc && \
    echo "export GST_PLUGIN_PATH=/usr/local/lib/gstreamer-1.0:/opt/libcamera/build/src/gstreamer/" >> /home/ubuntu/.bashrc && \
    echo "export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig:/usr/local/lib/${ARCH}-linux-gnu/pkgconfig:\$PKG_CONFIG_PATH" >> /home/ubuntu/.bashrc && \
    echo "export LD_LIBRARY_PATH=/usr/local/lib:/usr/local/lib/${ARCH}-linux-gnu:\$LD_LIBRARY_PATH" >> /home/ubuntu/.bashrc && \
    echo "export PYTHONPATH=/usr/local/lib/python${PYTHON_VERSION}/dist-packages:/usr/local/lib/python${PYTHON_VERSION}/site-packages:/usr/local/lib/python3/dist-packages:/usr/local/lib/python3.12/site-packages:\$PYTHONPATH" >> /home/ubuntu/.bashrc && \
    #echo "cd \$HOME/sensing-rigs-ros2/ros2_ws" >> /home/ubuntu/.bashrc && \
    #echo "[ -f install/setup.bash ] && source install/setup.bash" >> /home/ubuntu/.bashrc && \
    echo "export LIBCAMERA_LOG_LEVELS=*:4" >> /home/ubuntu/.bashrc && \
    chown ubuntu:ubuntu /home/ubuntu/.bashrc

# Add auto build command (with colcon)
#COPY entrypoint.sh /entrypoint.sh
#RUN chmod +x /entrypoint.sh
#ENTRYPOINT ["/entrypoint.sh"]
#CMD ["bash"]

# Switch to the ubuntu user
USER ubuntu
WORKDIR /home/ubuntu

# Copy debug script
COPY debug_libcamera.py /home/ubuntu/debug_libcamera.py

# Final verification of Python imports with detailed debugging
RUN export PYTHONPATH="/usr/local/lib/python3.12/dist-packages:/usr/local/lib/python3.12/site-packages:/usr/local/lib/python3/dist-packages:$PYTHONPATH" 
