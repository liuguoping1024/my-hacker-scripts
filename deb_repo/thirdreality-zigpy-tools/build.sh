#!/bin/bash

current_dir=$(pwd)
output_dir="${current_dir}/output"
zigpy_dir="/usr/local/thirdreality/zigpy_tools"

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

    rm -rf /usr/local/bin/zigpy_help.sh
    rm -rf ${zigpy_dir}/ > /dev/null 2>&1

    print_info "zigpy_tools_${version}.deb clear ..."
    exit 0
fi

if [[ "$REBUILD" == true ]]; then
    print_info "zigpy_tools_${version}.deb rebuilding ..."
    rm -rf "${output_dir}" > /dev/null 2>&1
    mkdir -p "${output_dir}"

    cp ${current_dir}/DEBIAN ${output_dir}/ -R
fi

print_info "Create output directory ..."
mkdir -p "${output_dir}"

print_info "syncing DEBIAN ..."
cp ${current_dir}/DEBIAN ${output_dir}/ -R

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

if [ ! -d "${output_dir}/${zigpy_dir}" ]; then
    mkdir -p ${output_dir}/${zigpy_dir}
    chmod 755 ${output_dir}/${zigpy_dir}
fi

mkdir -p ${output_dir}/usr/local/bin/
chmod 755 ${output_dir}/usr/local/bin/
cp /usr/local/bin/zigpy_help.sh ${output_dir}/usr/local/bin/

cp ${zigpy_dir}/* ${output_dir}/${zigpy_dir}/ -R

print_info "Start to build zigpy_tools_${version}.deb ..."
dpkg-deb --build ${output_dir} ${current_dir}/zigpy_tools_${version}.deb


rm -rf ${output_dir}/usr/

print_info "Build zigpy_tools_${version}.deb finished ..."



