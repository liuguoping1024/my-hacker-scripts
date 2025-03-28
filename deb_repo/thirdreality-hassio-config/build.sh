#!/bin/bash

# hassio-config 与 zigpy_tools有部分功能是重复的

current_dir=$(pwd)
output_dir="${current_dir}/output"
config_dir="/var/lib/homeassistant"
zigpy_dir="/usr/local/thirdreality/zigpy_tools"

REBUILD=false
CLEAN=false

SCRIPT="ThirdReality"
print_info() { echo -e "\e[1;34m[${SCRIPT}] INFO:\e[0m $1"; }
print_error() { echo -e "\e[1;31m[${SCRIPT}] ERROR:\e[0m $1"; }

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

    print_info "Removing ${config_dir}"
    rm -rf "${config_dir}" > /dev/null 2>&1
    rm -rf ${current_dir}/*.deb > /dev/null 2>&1

    rm -rf /usr/local/bin/zigpy_help.sh
    rm -rf ${zigpy_dir}/ > /dev/null 2>&1    

    print_info "hassio-config_${version}.deb clear ..."
    exit 0
fi

if [[ "$REBUILD" == true ]]; then
    print_info "hassio-config_${version}.deb rebuilding ..."
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

# ----------------------------------- 8>< -----------------
# { zigpy_tools part begin
if [ ! -e "/usr/bin/python3" ]; then
    print_info "No Python found, abort ..."
    exit 1
fi

if [ ! -e "/usr/local/bin/zigpy_help.sh" ]; then
    cp ${current_dir}/zigpy_help.sh /usr/local/bin/zigpy_help.sh
fi

print_info "Create zigpy directory ..."
mkdir -p ${zigpy_dir}

if [ ! -e "${zigpy_dir}/bin/activate" ]; then
    print_info "Building zigpy_tools venv ..."
    
    print_info "Using python: /usr/bin/python3"

    cd ${zigpy_dir}
    /usr/bin/python3 -m venv .

    source ${zigpy_dir}/bin/activate
    pip3 config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple/
    pip3 config set install.trusted-host pypi.tuna.tsinghua.edu.cn

    python3 -m pip install zigpy==0.77.1 zigpy_zigate==0.13.2 zigpy-cli==1.1.0

    deactivate
fi

if [ ! -e "${zigpy_dir}/bin/zigpy_hw_info.sh" ]; then
    cp ${current_dir}/zigpy_hw_info.sh ${zigpy_dir}/bin/zigpy_hw_info.sh
fi

echo "Backup zigpy files for hassio-config_${version}.deb ..."

if [ ! -d "${output_dir}/${zigpy_dir}" ]; then
    mkdir -p ${output_dir}/${zigpy_dir}
    chmod 755 ${output_dir}/${zigpy_dir}
fi

mkdir -p ${output_dir}/usr/local/bin/
chmod 755 ${output_dir}/usr/local/bin/
cp /usr/local/bin/zigpy_help.sh ${output_dir}/usr/local/bin/

cp ${zigpy_dir}/* ${output_dir}/${zigpy_dir}/ -R

# } zigpy_tools part end
# ----------------------------------- 8>< -----------------


if [ ! -e "${config_dir}/homeassistant"]; then
    cp ${current_dir}/homeassistant/*  "${config_dir}/" -R
fi

# ----------------------------------- 8>< -----------------

echo "Backup config files for hassio-config_${version}.deb ..."

mkdir -p ${output_dir}/var/lib/homeassistant
chmod 755 ${output_dir}/var/lib/homeassistant

mkdir -p ${output_dir}/etc
chmod 755 ${output_dir}/etc

cp /var/lib/homeassistant/* ${output_dir}/var/lib/homeassistant/ -R
rm -rf ${output_dir}/var/lib/homeassistant/homeassistant/.HA_VERSION

cp /etc/hassio.json ${output_dir}/etc/ 

print_info "Start to build hassio-config_${version}.deb ..."
dpkg-deb --build ${output_dir} ${current_dir}/hassio-config_${version}.deb


rm -rf ${output_dir}/var > /dev/null 2>&1
rm -rf ${output_dir}/etc > /dev/null 2>&1
rm -rf ${output_dir}/usr > /dev/null 2>&1

print_info "Build hassio-config_${version}.deb finished ..."
