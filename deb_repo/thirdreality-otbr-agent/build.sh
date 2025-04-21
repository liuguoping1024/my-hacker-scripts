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

INFRA_IF_NAME="${INFRA_IF_NAME:-wlan0}"
readonly INFRA_IF_NAME

SYSCTL_ACCEPT_RA_FILE="/etc/sysctl.d/60-otbr-accept-ra.conf"
readonly SYSCTL_ACCEPT_RA_FILE

DHCPCD_CONF_FILE="/etc/dhcpcd.conf"
readonly DHCPCD_CONF_FILE

DHCPCD_CONF_BACKUP_FILE="$DHCPCD_CONF_FILE.orig"
readonly DHCPCD_CONF_BACKUP_FILE

otbr_uninstall()
{
    if have systemctl; then
        sudo systemctl stop otbr-web || true
        sudo systemctl stop otbr-agent || true
        sudo systemctl disable otbr-web || true
        sudo systemctl disable otbr-agent || true
        ! sudo systemctl is-enabled otbr-web
        ! sudo systemctl is-enabled otbr-agent
    fi
    sudo killall otbr-web otbr-agent || true

    (
        if cd "${OTBR_TOP_BUILDDIR}"; then
            # shellcheck disable=SC2024
            sudo xargs rm <install_manifests.txt || true
        fi
    )
    if have systemctl; then
        sudo systemctl daemon-reload
    fi
}

accept_ra_uninstall()
{
    test ! -f $SYSCTL_ACCEPT_RA_FILE || sudo rm -v $SYSCTL_ACCEPT_RA_FILE
}

dhcpcd_enable_ipv6rs()
{
    if [ -f $DHCPCD_CONF_BACKUP_FILE ]; then
        sudo cp $DHCPCD_CONF_BACKUP_FILE $DHCPCD_CONF_FILE
    fi
}

rt_tables_uninstall()
{
    sudo sed -i.bak '/88\s\+openthread/d' /etc/iproute2/rt_tables
}

FIREWALL_SERVICE=/etc/init.d/otbr-firewall

firewall_uninstall()
{
    if have systemctl; then
        sudo systemctl stop otbr-firewall || true
        sudo systemctl disable otbr-firewall || true
    fi
    # systemctl disable doesn't remove sym-links
    if have update-rc.d; then
        sudo update-rc.d otbr-firewall remove || true
    fi
    test ! -f $FIREWALL_SERVICE || sudo rm $FIREWALL_SERVICE
}

remove_current_otbr_agent()
{
    otbr_uninstall
    accept_ra_uninstall
    rt_tables_uninstall
    firewall_uninstall
    dhcpcd_enable_ipv6rs
}

if [[ "$CLEAN" == true ]]; then
    rm -rf "${output_dir}" > /dev/null 2>&1
    rm -rf ${current_dir}/*.deb > /dev/null 2>&1

    rm -rf "${current_dir}/ot-br-posix"

    remove_current_otbr_agent

    exit 0
fi

if [[ "$REBUILD" == true ]]; then
    print_info "obtr_agent_${version}.deb rebuilding ..."
    rm -rf "${output_dir}" > /dev/null 2>&1
    mkdir -p "${output_dir}"

    rm -rf "${current_dir}/ot-br-posix"

    cp ${current_dir}/DEBIAN ${output_dir}/ -R
fi

print_info "Create output directory ..."
mkdir -p "${output_dir}"

print_info "syncing DEBIAN ..."
cp ${current_dir}/DEBIAN ${output_dir}/ -R

if [ ! -d "${current_dir}/ot-br-posix" ]; then
    /usr/bin/git --version
    /usr/bin/git clone git@github.com:openthread/ot-br-posix.git

    # OTBR_VENDOR_NAME="Home Assistant" OTBR_PRODUCT_NAME="OpenThread Border Router"
    cd "${current_dir}/ot-br-posix"; WEB_GUI=0 ./script/bootstrap
    cd "${current_dir}/ot-br-posix"; INFRA_IF_NAME=wlan0 WEB_GUI=0 ./script/setup

    cp ${current_dir}/otbr-agent /etc/default/
fi

# Copy MDNS files
# find /usr -type f -newermt $(date +'%Y-%m-%d') ! -newermt $(date -d '1 day' +'%Y-%m-%d')

print_info "Copy openthread files ..."

mkdir -p ${output_dir}/etc/default/
mkdir -p ${output_dir}/etc/init.d/
mkdir -p ${output_dir}/etc/dbus-1/system.d/
mkdir -p ${output_dir}/etc/sysctl.d/

mkdir -p ${output_dir}/usr/sbin/
mkdir -p ${output_dir}/usr/bin/
mkdir -p ${output_dir}/usr/lib/systemd/system/
mkdir -p ${output_dir}/usr/include/

cp /usr/lib/libdns_sd.so.1 ${output_dir}/usr/lib/
cp /usr/lib/systemd/system/otbr-agent.service ${output_dir}/usr/lib/systemd/system/
cp /usr/lib/libnss_mdns-0.2.so ${output_dir}/usr/lib/
cp /usr/sbin/ot-ctl ${output_dir}/usr/sbin/
cp /usr/sbin/mdnsd ${output_dir}/usr/sbin/
cp /usr/sbin/otbr-agent ${output_dir}/usr/sbin/
cp /usr/bin/dns-sd ${output_dir}/usr/sbin/

cp /etc/dbus-1/system.d/otbr-agent.conf ${output_dir}/etc/dbus-1/system.d/

cp /etc/init.d/otbr-firewall ${output_dir}/etc/init.d/
cp /etc/init.d/mdns ${output_dir}/etc/init.d/
cp /etc/default/otbr-agent ${output_dir}/etc/default/
cp /etc/sysctl.d/60-otbr-ip-forward.conf ${output_dir}/etc/sysctl.d
cp /etc/sysctl.d/60-otbr-accept-ra.conf ${output_dir}/etc/sysctl.d

# ---------------------

# cp /etc/init.d/otbr-firewall ${output_dir}/etc/init.d/
# #chmod a+x /etc/init.d/otbr-firewall
# #systemctl enable otbr-firewall

# # sudo sh -c 'echo "88 openthread" >>/etc/iproute2/rt_tables'

print_info "Start to build obtr_agent_${version}.deb ..."
dpkg-deb --build ${output_dir} ${current_dir}/obtr_agent_${version}.deb


rm -rf ${output_dir}/usr > /dev/null 2>&1
rm -rf ${output_dir}/etcc > /dev/null 2>&1

print_info "Build obtr_agent_${version}.deb finished ..."



