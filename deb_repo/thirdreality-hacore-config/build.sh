#!/bin/bash

current_dir=$(pwd)
output_dir="${current_dir}/output"
config_dir="/var/lib/homeassistant"

REBUILD=false
CLEAN=false

SCRIPT="ThirdReality"
print_info() { echo -e "\e[1;34m[${SCRIPT}] INFO:\e[0m $1"; }
print_error() { echo -e "\e[1;31m[${SCRIPT}] ERROR:\e[0m $1"; }

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --rebuild) REBUILD=true ;;
        --clean) CLEAN=true ;;
        *) echo "未知参数: $1" >&2; exit 1 ;;
    esac
    shift
done

version=$(grep '^Version:' ${current_dir}/DEBIAN/control | awk '{print $2}')
print_info "Version: $version"

if [[ "$CLEAN" == true ]]; then
    
    rm -rf "${output_dir}" > /dev/null 2>&1

    print_info "Removing ${config_dir}"
    rm -rf "${config_dir}" > /dev/null 2>&1
    rm -rf ${current_dir}/*.deb > /dev/null 2>&1

    print_info "hacore-config_${version}.deb clear ..."
    exit 0
fi


if [[ "$REBUILD" == true ]]; then
    print_info "hacore-config_${version}.deb rebuilding ..."
    rm -rf "${output_dir}" > /dev/null 2>&1
    rm -rf "${config_dir}" > /dev/null 2>&1

    mkdir -p "${output_dir}"
    mkdir -p "${config_dir}"

    cp ${current_dir}/DEBIAN ${output_dir}/ -R
    cp ${current_dir}/homeassistant/*  "${config_dir}/" -R
fi

print_info "Create output directory ..."
mkdir -p "${output_dir}"
mkdir -p "${config_dir}"

print_info "syncing DEBIAN ..."
cp ${current_dir}/DEBIAN ${output_dir}/ -R


if [ ! -d "${config_dir}/homeassistant" ]; then
    cp ${current_dir}/homeassistant/*  "${config_dir}/" -R
fi

rm -rf ${output_dir}/var > /dev/null 2>&1
rm -rf ${output_dir}/etc > /dev/null 2>&1 
rm -rf ${output_dir}/usr > /dev/null 2>&1

mkdir -p ${output_dir}/var/lib/homeassistant
chmod 755 ${output_dir}/var/lib/homeassistant

mkdir -p ${output_dir}/etc
chmod 755 ${output_dir}/etc

ls -l ${config_dir}

cp ${config_dir}/* ${output_dir}/var/lib/homeassistant/ -R
rm -rf ${output_dir}/var/lib/homeassistant/homeassistant/.HA_VERSION

cp /etc/hassio.json ${output_dir}/etc/ 

print_info "Start to build hacore-config_${version}.deb ..."
dpkg-deb --build ${output_dir} ${current_dir}/hacore-config_${version}.deb


rm -rf ${output_dir}/var > /dev/null 2>&1
rm -rf ${output_dir}/etc > /dev/null 2>&1
rm -rf ${output_dir}/usr > /dev/null 2>&1

print_info "Build hacore-config_${version}.deb finished ..."
