#!/bin/bash

current_dir=$(pwd)
work_dir="$current_dir/operating-system"
echo "Working directory is '$work_dir'"

/usr/bin/git version

if [ ! -d "$current_dir/hassos-build" ]; then
    mkdir -p $current_dir/hassos-build
    ln -snf $current_dir/hassos-build /build
fi

if [ ! -d "$current_dir/hassos-cache" ]; then
    mkdir -p $current_dir/hassos-cache
    ln -snf $current_dir/hassos-cache /cache
fi

# Checkout source
if [ ! -d "$work_dir" ]; then
    /usr/bin/git clone git@github.com:TianweiiiGe/operating-system.git -b dev-hubv3
    cd $work_dir
    /usr/bin/git pull
    /usr/bin/git submodule update --init
else
    cd $work_dir
    /usr/bin/git pull
    /usr/bin/git submodule sync
fi

# Build tools
if [ ! -e "$current_dir/.apt_checked" ]; then
    touch $current_dir/.apt_checked
    apt-get update && apt-get install -y --no-install-recommends \
            bash \
            bc \
            binutils \
            build-essential \
            bzip2 \
            cpio \
            file \
            git \
            graphviz \
            jq \
            make \
            ncurses-dev \
            openssh-client \
            patch \
            perl \
            python3 \
            python3-matplotlib \
            python-is-python3 \
            qemu-utils \
            rsync \
            skopeo \
            sudo \
            unzip \
            vim \
            wget \
            zip 
fi

#prepare release key.
if [ ! -e "$current_dir/hassos-build/key.pem" ]; then
    openssl req -x509 -newkey rsa:4096 -keyout "$current_dir/hassos-build/key.pem" \
                -out "$current_dir/hassos-build/cert.pem" -days 3650 -nodes \
                -subj "/O=ThirdReality/CN=ThirdReality Self-signed Development Certificate"
fi

#sudo scripts/enter.sh make rpi4_64
#sudo scripts/enter.sh make O=output_rpi4_64 rpi4_64

/usr/bin/make -C $work_dir/buildroot O=$work_dir/output BR2_EXTERNAL=$work_dir/buildroot-external "thirdreality_hubv3_defconfig"

/usr/bin/make -C $work_dir/buildroot O=$work_dir/output BR2_EXTERNAL=$work_dir/buildroot-external


