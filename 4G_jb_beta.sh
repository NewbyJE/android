#/bin/bash
#
# Set environment for your build system
TOP=~/android/cm10jb; export TOP
#
echo "Started new build"
echo `date +%Y%m%d-%H%M`
echo "setup android"
cd $TOP
source build/envsetup.sh
ccache --max-size=50G
export USE_CCACHE=1
#
echo "resync git pointers"
repo forall -c git reset --hard
# repo forall -c git reset --hard HEAD
echo "repo sync"
repo sync -j16
#
echo "remove old patches and check status"
rm vendor/mbm/patches_jb/*
repo status
#
echo "copy the most recent HP TP proprietary files"
rm -r vendor/hp/tenderloin/proprietary/*
cp -R device/hp/tenderloin/Proprietary/* vendor/hp/tenderloin/proprietary/
#
echo "apply external/tinyalsa cherrypicks"
pushd external/tinyalsa
# WIP: properly support multivalued controls (James Sullins)
git fetch http://review.cyanogenmod.org/CyanogenMod/android_external_tinyalsa refs/changes/46/33646/1 && git cherry-pick -n FETCH_HEAD
git reset HEAD
popd
#
echo "apply frameworks/base cherrypicks"
pushd frameworks/base
# telephony: Fix MMS for when operator has different APNs for Data and MMS (John Newby)
git fetch http://review.cyanogenmod.com/CyanogenMod/android_frameworks_base refs/changes/83/24883/1 && git cherry-pick -n FETCH_HEAD
git reset HEAD
popd
#
# echo "copy in modified tenderloin makefiles"
# cp ~/Android_Builds/cm10jb/BETA/2014_02_01/makefiles/* device/hp/tenderloin/
#
echo "copy newer CDC files"
cd kernel/hp/tenderloin
# cp ~/Android_Builds/cm10jb/BETA/2014_02_14/cdc_files/kconfig.h include/linux/kconfig.h
cp ~/Android_Builds/cm10jb/BETA/2014_02_14/cdc_files/cdc.h include/linux/usb/cdc.h
cp ~/Android_Builds/cm10jb/BETA/2014_02_14/cdc_files/cdc-acm.c drivers/usb/class/cdc-acm.c
cp ~/Android_Builds/cm10jb/BETA/2014_02_14/cdc_files/cdc-acm.h drivers/usb/class/cdc-acm.h
# cp ~/Android_Builds/cm10jb/BETA/2014_02_14/cdc_files/cdc_ncm.h include/linux/usb/cdc_ncm.h
cp ~/Android_Builds/cm10jb/BETA/2014_02_14/cdc_files/cdc_ncm.c drivers/net/usb/cdc_ncm.c
cp ~/Android_Builds/cm10jb/BETA/2014_02_14/cdc_files/cdc-wdm.h include/linux/usb/cdc-wdm.h
cp ~/Android_Builds/cm10jb/BETA/2014_02_14/cdc_files/cdc-wdm.c drivers/usb/class/cdc-wdm.c
cp ~/Android_Builds/cm10jb/BETA/2014_02_14/cdc_files/usbnet.h include/linux/usb/usbnet.h
cp ~/Android_Builds/cm10jb/BETA/2014_02_14/cdc_files/usbnet.c drivers/net/usb/usbnet.c
cd $TOP
#
echo "copy latest build script and patches"
cd vendor/mbm
mkdir patches_jb
cp ~/Android_Builds/cm10jb/BETA/2014_02_14/4G_jb_beta.sh patches_jb/
cp ~/Android_Builds/cm10jb/BETA/2014_02_14/patches_jb/*.patch patches_jb/
cd $TOP
#
echo "development patch"
cd development
# Add package name providing network location support.
git apply $TOP/vendor/mbm/patches_jb/development.patch
cd $TOP
#
echo "device_hp_tenderloin patches"
cd device/hp/tenderloin
# Debug flags for wpa_supplicant and hostapd.
git apply $TOP/vendor/mbm/patches_jb/device_hp_tenderloin+debug.patch
# Change to portrait mode.
# git apply $TOP/vendor/mbm/patches_jb/device_hp_tenderloin_portrait.patch
cd $TOP
#
echo "external_backports-wireless patch"
cd external/backports-wireless
# Turn on ATH / ATH6KL debugging.
git apply $TOP/vendor/mbm/patches_jb/external_backports-wireless+debug.patch
cd $TOP
#
echo "external_wpa_supplicant_8 patch"
cd external/wpa_supplicant_8
# Incorporate nl80211 driver from hardware/atheros/wlan/ath6kl/wpa_supplicant_8_lib
git apply $TOP/vendor/mbm/patches_jb/external_wpa_supplicant_8.patch
cd $TOP
#
echo "hardware_libhardware_legacy patch"
cd hardware/libhardware_legacy
# Fix wlan0 loading and fw path directory (+debug option).
git apply $TOP/vendor/mbm/patches_jb/hardware_libhardware_legacy+debug.patch
cd $TOP
#
echo "kernel cleanup patch"
cd kernel/hp/tenderloin
# Fix miscellaneous kernel compile errors
# git apply $TOP/vendor/mbm/patches_jb/01b_hp_kernel_cleanup.patch
# Hub race fix
git apply $TOP/vendor/mbm/patches_jb/drivers_usb_core_hub.race_fix.patch
# HCD debug messages
git apply $TOP/vendor/mbm/patches_jb/drivers_usb_core_hcd.debug.patch
# Fix light sensor crash
# git apply $TOP/vendor/mbm/patches_jb/02 hp_kernel_light_sensor.patch
cd $TOP
#
echo "system_core patch"
cd system/core
# Proper radio buffer sizes and increased size for dmesg dump
git apply $TOP/vendor/mbm/patches_jb/system_core.patch
cd $TOP
#
echo "system_netd patch"
cd system/netd
# Start up wlan0 interface earlier (+debug option).
git apply $TOP/vendor/mbm/patches_jb/system_netd+debug.patch
cd $TOP
#
echo "apply vendor cm patch"
cd vendor/cm
# Non-release builds
git apply $TOP/vendor/mbm/patches_jb/vendor_cm.patch
./get-prebuilts
cd $TOP
#
echo "setup make files"
cd device/hp/tenderloin/
./setup-makefiles.sh
cd $TOP
#
echo "clean build and set name"
make clean
export CM_BUILDTYPE=MBM_L
export CM_EXTRAVERSION_DATESTAMP=1
export CM_EXTRAVERSION_TAG="4g_beta5"
#
echo "brunch tenderloin"
ccache --max-size=50G
brunch tenderloin 2>&1 | tee jb_build.log
echo "Completed new build"
echo `date +%Y%m%d-%H%M`

