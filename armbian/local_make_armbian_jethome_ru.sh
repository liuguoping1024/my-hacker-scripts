#!/bin/bash

current_dir=$(pwd)
work_dir="$current_dir/_work"
echo "Working directory is '$work_dir'"

/usr/bin/git version


#-------------------------------------------
echo "Installing armbian-build ..."

mkdir -p $work_dir
cd $work_dir

if [ ! -d "$work_dir/armbian-os" ]; then
  /usr/bin/git clone git@github.com:jethome-iot/armbian-build.git -b v24.11 armbian-os

  cd $work_dir/armbian-os

  /usr/bin/git rev-parse --verify --quiet v24.11
  /usr/bin/git config --local gc.auto 0
  /usr/bin/git sparse-checkout disable
  /usr/bin/git config --local --unset-all extensions.worktreeConfig
  /usr/bin/git log -1 --format=%H
else
  cd $work_dir/armbian-os
  /usr/bin/git pull
  /usr/bin/git log -1 --format=%H
fi

#-------------------------------------------
echo "Installing userpatches ..."

cd $work_dir/armbian-os

if [ ! -d "$work_dir/armbian-os/userpatches.repo" ]; then
  /usr/bin/git clone git@github.com:jethome-iot/armbian-os.git -b main userpatches.repo

  cd $work_dir/armbian-os/userpatches.repo
  /usr/bin/git config --local gc.auto 0
  /usr/bin/git sparse-checkout disable
  /usr/bin/git config --local --unset-all extensions.worktreeConfig
  /usr/bin/git log -1 --format=%H
else
  cd $work_dir/armbian-os/userpatches.repo
  /usr/bin/git pull
  /usr/bin/git log -1 --format=%H
fi

#-------------------------------------------
echo "Installing tools ..."

cd $work_dir/armbian-os

if [ ! -d "$work_dir/armbian-os/tools.repo" ]; then
  /usr/bin/git clone git@github.com:jethome-ru/jethome-tools.git -b convert_jhos tools.repo

  cd $work_dir/armbian-os/tools.repo
  /usr/bin/git config --local gc.auto 0
  /usr/bin/git sparse-checkout disable
  /usr/bin/git config --local --unset-all extensions.worktreeConfig
  /usr/bin/git log -1 --format=%H
else
  cd $work_dir/armbian-os/tools.repo
  /usr/bin/git pull
  /usr/bin/git log -1 --format=%H  
fi



#-------------------------------------------
cd $work_dir/armbian-os

if [ ! -d "$work_dir/armbian-os/userpatches" ]; then
  echo "Init userpatches ..."
  mkdir -pv userpatches
  rsync -av userpatches.repo/userpatches-jethub/. userpatches/

  echo 24.11.1.jh.5.3 > userpatches/VERSION

  # ??
  sudo rm -f userpatches/VERSION
else
  echo "Updating userpatches ..."
  #rsync -av userpatches.repo/userpatches-jethub/. userpatches/
  echo 24.11.1.jh.5.3 > userpatches/VERSION
  sudo rm -f userpatches/VERSION
fi

#-------------------------------------------

# calculate loop from runner name
if [ -z "${ImageOS}" ]; then
  USE_FIXED_LOOP_DEVICE=$(echo ${RUNNER_NAME} | rev | cut -d"-" -f1  | rev | sed 's/^0*//' | sed -e 's/^/\/dev\/loop/')
fi

echo "Start building ..."

./compile.sh 'BETA=no' 'BOARD=jethubj100' 'BRANCH=current' 'BUILD_DESKTOP=no' 'BUILD_MINIMAL=no' 'RELEASE=jammy' 'REVISION=24.11.1.jh.5.3' jethome-images REVISION="24.11.1.jh.5.3" USE_FIXED_LOOP_DEVICE="$USE_FIXED_LOOP_DEVICE" SHARE_LOG=yes MAKE_FOLDERS="archive" IMAGE_VERSION=24.11.1.jh.5.3 SHOW_DEBIAN=yes SHARE_LOG=yes  UPLOAD_TO_OCI_ONLY=yes


echo "Armbian build finished."
#-------------------------------------------



if ! command -v "dtc" > /dev/null 2>&1; then
   sudo apt update \
   && sudo apt install device-tree-compiler -y
fi

if ! command -v "cc" > /dev/null 2>&1; then
   sudo apt update \
   && sudo apt install build-essential cpp -y
fi

if ! command -v "zip" > /dev/null 2>&1; then
     sudo apt update \
     && sudo apt install zip -y
fi
  
  
UBOOTDEB=$(find output | grep linux-u-boot | head -n 1)
IMG=$(find output | grep  -e  ".*images.*Armbian.*img.xz$" | head -n 1)
# Armbian_23.8.0-trunk.52.jh.3.5_Jethubj80_bookworm_current_6.1.32.burn.img
  
cd $work_dir/armbian-os/tools.repo
  
DEB="../${UBOOTDEB}"
dpkg -x "$DEB" output
UBOOT=$(find output/usr/lib -name u-boot.nosd.bin | head -n 1)
echo UBOOT: ${UBOOT}
find ../output

echo "Start convert image ..."

### 'BETA=yes' 'BOARD=jethubj80' 'BRANCH=current' 'BUILD_DESKTOP=no' 'BUILD_MINIMAL=no' 'RELEASE=bookworm'
EVALCMD=$(echo 'BETA=no' 'BOARD=jethubj100' 'BRANCH=current' 'BUILD_DESKTOP=no' 'BUILD_MINIMAL=no' 'RELEASE=jammy' 'REVISION=24.11.1.jh.5.3' jethome-images | sed 's/jethome-images//')
eval ${EVALCMD}
echo ${EVALCMD}
case ${BOARD} in
  jethubj100)
    ./convert.sh ../${IMG} d1 armbian compress output/usr/lib/linux*/u-boot.nosd.bin
    SUPPORTED="D1,D1P"
    ;;
  jethubj200)
    ./convert.sh ../${IMG} d2 armbian compress output/usr/lib/linux*/u-boot.nosd.bin
    SUPPORTED="D2"
    ;;
  jethubj80)
    ./convert.sh ../${IMG} h1 armbian compress output/usr/lib/linux*/u-boot.nosd.bin
    SUPPORTED="H1"
    ;;
  *)
    echo "Unsupported board" ${BOARD}
    echo "Error in convert: Unsupported board" ${BOARD} >> GITHUB_STEP_SUMMARY
    exit 200
    ;;
esac

rm -rf output/usr

IMGBURN=$(find output | grep  -e  "Armbian.*burn.img.zip$" | head -n 1)
echo IMGBURN: ${IMGBURN}
[ -z "${IMGBURN}" ] && exit 50

CHANNEL="release"

# if [ "${BETA}" == "yes" ]; then
#   case "v24.11" in
#     main*)
#       CHANNEL="nightly"
#       ;;
#     v2*)
#       CHANNEL="rc"
#       ;;
#     *)
#       CHANNEL="${BUILD_REF}"
#       ;;
#   esac
  
# else
#   CHANNEL="release"
# fi
  
echo "board=${BOARD}"
echo "brd=${BOARD:6}"
echo "branch=${BRANCH}"
echo "channel=${CHANNEL}"
echo "release=${RELEASE}"
echo "supported=${SUPPORTED}"
echo "image=${IMG}"
echo "imageburn=tools/${IMGBURN}"


