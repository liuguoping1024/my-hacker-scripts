#!/bin/bash

current_dir=$(pwd)
work_dir="$current_dir/operating-system"
echo "Working directory is '$work_dir'"

/usr/bin/git version

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
if [ ! -e "$work_dir/.apt_checked" ]; then
    touch $work_dir/.apt_checked
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
if [ ! -e "$work_dir/key.pem" ]; then
    openssl req -x509 -newkey rsa:4096 -keyout "$work_dir/key.pem" \
                -out "$work_dir/cert.pem" -days 3650 -nodes \
                -subj "/O=ThirdReality/CN=ThirdReality Self-signed Development Certificate"
fi

#sudo scripts/enter.sh make rpi4_64
#sudo scripts/enter.sh make O=output_rpi4_64 rpi4_64

/usr/bin/make -C $work_dir/buildroot O=$work_dir/output BR2_EXTERNAL=$work_dir/buildroot-external "thirdreality_hubv3_defconfig"

/usr/bin/make -C $work_dir/buildroot O=$work_dir/output BR2_EXTERNAL=$work_dir/buildroot-external


