#!/bin/bash

# Ref: https://github.com/Qengineering/Install-OpenCV-Jetson-Nano

set -e

CV_VERSION=4.10.0

install_opencv() {
    # Check if the file /proc/device-tree/model exists
    echo ""

    # You can find the ARCH and PTX using CUDA's builtin sample deviceQuery
    ARCH=7.2
    PTX="sm_72"
    NO_JOB=''

    echo ""

    echo "Installing OpenCV $CV_VERSION on your AGX Xavier"
    echo "It will take 3.5 hours !"

    # reveal the CUDA location
    cd ~
    sudo sh -c "echo '/usr/local/cuda/lib64' >> /etc/ld.so.conf.d/nvidia-tegra.conf"
    sudo ldconfig

    if [ -f /etc/os-release ]; then
        # Source the /etc/os-release file to get variables
        . /etc/os-release
        # Extract the major version number from VERSION_ID
        VERSION_MAJOR=$(echo "$VERSION_ID" | cut -d'.' -f1)
        # Check if the extracted major version is 22 or earlier
        if [ "$VERSION_MAJOR" = "22" ]; then
            sudo apt-get install -y libswresample-dev libdc1394-dev
        else
            sudo apt-get install -y libavresample-dev libdc1394-22-dev
        fi
    else
        sudo apt-get install -y libavresample-dev libdc1394-22-dev
    fi

    # install the common dependencies
    sudo apt-get install -y cmake \
        libjpeg-dev libjpeg8-dev libjpeg-turbo8-dev \
        libpng-dev libtiff-dev libglew-dev \
        libavcodec-dev libavformat-dev libswscale-dev \
        libgtk2.0-dev libgtk-3-dev libcanberra-gtk* \
        python3-pip \
        libxvidcore-dev libx264-dev \
        libtbb-dev libxine2-dev \
        libv4l-dev v4l-utils qv4l2 \
        libtesseract-dev libpostproc-dev \
        libvorbis-dev \
        libfaac-dev libmp3lame-dev libtheora-dev \
        libopencore-amrnb-dev libopencore-amrwb-dev \
        libopenblas-dev libatlas-base-dev libblas-dev \
        liblapack-dev liblapacke-dev libeigen3-dev gfortran \
        libhdf5-dev libprotobuf-dev protobuf-compiler \
        libgoogle-glog-dev libgflags-dev

    # remove old versions or previous builds
    cd ~
    sudo rm -rf opencv*
    # download the latest version

    git clone --depth 1 --branch "$CV_VERSION" "https://github.com/opencv/opencv.git"
    git clone --depth 1 --branch "$CV_VERSION" "https://github.com/opencv/opencv_contrib.git"

    # set install dir
    cd ~/opencv
    mkdir build
    cd build

    # run cmake
    cmake -D CMAKE_BUILD_TYPE=RELEASE \
        -D CMAKE_INSTALL_PREFIX=/usr \
        -D OPENCV_EXTRA_MODULES_PATH=~/opencv_contrib/modules \
        -D EIGEN_INCLUDE_PATH=/usr/include/eigen3 \
        -D WITH_OPENCL=OFF \
        -D CUDA_ARCH_BIN=${ARCH} \
        -D CUDA_ARCH_PTX=${PTX} \
        -D WITH_CUDA=ON \
        -D WITH_CUDNN=ON \
        -D WITH_CUBLAS=ON \
        -D ENABLE_FAST_MATH=ON \
        -D CUDA_FAST_MATH=ON \
        -D OPENCV_DNN_CUDA=ON \
        -D ENABLE_NEON=ON \
        -D WITH_QT=OFF \
        -D WITH_OPENMP=ON \
        -D BUILD_TIFF=ON \
        -D WITH_FFMPEG=ON \
        -D WITH_GSTREAMER=ON \
        -D WITH_TBB=ON \
        -D BUILD_TBB=ON \
        -D BUILD_TESTS=OFF \
        -D WITH_EIGEN=ON \
        -D WITH_V4L=ON \
        -D WITH_LIBV4L=ON \
        -D WITH_PROTOBUF=ON \
        -D OPENCV_ENABLE_NONFREE=ON \
        -D INSTALL_C_EXAMPLES=OFF \
        -D INSTALL_PYTHON_EXAMPLES=OFF \
        -D PYTHON3_PACKAGES_PATH=/usr/lib/python3/dist-packages \
        -D OPENCV_GENERATE_PKGCONFIG=ON \
        -D BUILD_EXAMPLES=OFF \
        -D CMAKE_CXX_FLAGS="-march=native -mtune=native" \
        -D CMAKE_C_FLAGS="-march=native -mtune=native" ..

    make -j ${NO_JOB}

    directory="/usr/include/opencv4/opencv2"
    if [ -d "$directory" ]; then
        # Directory exists, so delete it
        sudo rm -rf "$directory"
    fi

    sudo make install
    sudo ldconfig

    # cleaning (frees 320 MB)
    make clean
    sudo apt-get update

    echo "Congratulations!"
    echo "You've successfully installed OpenCV $CV_VERSION on your Xavier"
}

cd ~

if [ -d ~/opencv/build ]; then
    echo " "
    echo "You have a directory ~/opencv/build on your disk."
    echo "Continuing the installation will replace this folder."
    echo " "

    printf "Do you wish to continue (Y/n)?"
    read answer

    if [ "$answer" != "${answer#[Nn]}" ]; then
        echo "Leaving without installing OpenCV"
    else
        install_opencv
    fi
else
    install_opencv
fi
