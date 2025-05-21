#!/bin/bash

current_dir=$(pwd)
output_dir="${current_dir}/output"

REBUILD=false
CLEAN=false

SCRIPT="ThirdReality"
print_info() { echo -e "\e[1;34m[${SCRIPT}] INFO:\e[0m $1"; }
print_error() { echo -e "\e[1;31m[${SCRIPT}] ERROR:\e[0m $1"; }

print_info "Usage: Build.sh [--rebuild] [--clean]"
print_info "Options:"
print_info "  --rebuild: Rebuild the env"
print_info "  --clean: Clean the output directory and remove the env"

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --rebuild) REBUILD=true ;;
        --clean) CLEAN=true ;;
        *) print_error "未知参数: $1" >&2; exit 1 ;;
    esac
    shift
done

version=$(grep '^Version:' ${current_dir}/DEBIAN/control | awk '{print $2}')
print_info "Version: $version"

if [[ "$CLEAN" == true ]]; then
    rm -rf "${output_dir}" > /dev/null 2>&1
    rm -rf ${current_dir}/*.deb > /dev/null 2>&1

    print_info "flash_firmware_${version}.deb clear ..."
    exit 0
fi

if [[ "$REBUILD" == true ]]; then
    print_info "flash_firmware_${version}.deb rebuilding ..."
    rm -rf "${output_dir}" > /dev/null 2>&1
    mkdir -p "${output_dir}"

    cp ${current_dir}/DEBIAN ${output_dir}/ -R
fi

print_info "Create output directory ..."
mkdir -p "${output_dir}"

print_info "syncing DEBIAN ..."
cp ${current_dir}/DEBIAN ${output_dir}/ -R

mkdir -p ${output_dir}/lib/firmware/bl706/partition_1m_images
mkdir -p ${output_dir}/lib/firmware/bl706/partition_2m_images

cp ${current_dir}/partition_1m_images ${output_dir}/lib/firmware/bl706/ -R
cp ${current_dir}/partition_2m_images ${output_dir}/lib/firmware/bl706/ -R

if [ -f "${current_dir}/bflb_iot.tar.gz" ]; then
    cp ${current_dir}/bflb_iot.tar.gz ${output_dir}/lib/firmware/bl706/
fi

if [ -f "${current_dir}/bl706_func.sh" ]; then
    cp ${current_dir}/bl706_func.sh ${output_dir}/lib/firmware/bl706/
    chmod +x ${output_dir}/lib/firmware/bl706/bl706_func.sh
fi

if [ -f "${current_dir}/bl706_func.sh" ]; then
    cp ${current_dir}/bl706_func.sh ${output_dir}/lib/firmware/bl706/
    chmod +x ${output_dir}/lib/firmware/bl706/bl706_func.sh
fi

if [ -f "${current_dir}/upgrade_firmware.sh" ]; then
    cp ${current_dir}/upgrade_firmware.sh ${output_dir}/lib/firmware/bl706/
    chmod +x ${output_dir}/lib/firmware/bl706/upgrade_firmware.sh
fi

print_info "Start to build flash_firmware_${version}.deb ..."
dpkg-deb --build ${output_dir} ${current_dir}/flash_firmware_${version}.deb


rm -rf ${output_dir}/usr/

print_info "Build flash_firmware_${version}.deb finished ..."



