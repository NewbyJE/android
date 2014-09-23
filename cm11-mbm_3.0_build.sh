#/bin/bash
#
# Set environment for your build system
TOP=~/android/cm11-mbm_3.0; export TOP
#
echo "Started new build"
echo `date +%Y%m%d-%H%M`
echo "setup android"
cd $TOP
source build/envsetup.sh
ccache --max-size=50G
export USE_CCACHE=1
#==============================================================================
# Resync all files
#==============================================================================
echo "resync git pointers"
repo forall -c git reset --hard
# repo forall -c git reset --hard HEAD
echo "repo sync"
repo sync -j16
repo status
#==============================================================================
# Apply test patches
#==============================================================================
echo "bootable/recovery-cm patch"
cd bootable/recovery-cm
# Different graphics_overlay from jcsullins build
git apply $TOP/patches/patches/patches/bootable_recovery-cm.patch
cd $TOP
#
echo "device/hp/tenderloin patch"
cd device/hp/tenderloin
# Remove all hostapd and tethering support for now
git apply $TOP/patches/patches/patches/device_hp_tenderloin.patch
cd $TOP
#
echo "kernel/hp/tenderloin patch"
cd kernel/hp/tenderloin
# Restore old key mapping for testing
git apply $TOP/patches/patches/patches/kernel_hp_tenderloin.patch
cd $TOP
#
echo "apply vendor/mbm patch"
# Eperimental reboot of module on HP Touchpad 4G
cd vendor/mbm
git apply $TOP/patches/patches/patches/vendor_mbm.patch
cd $TOP
#
#==============================================================================
# Apply standard patches
#==============================================================================
echo "bootable/recovery patch"
cd bootable/recovery
# Set up for no rainbows
git apply $TOP/patches/patches/patches/bootable_recovery.patch
cd $TOP
#
echo "hardware/atheros/wlan"
cd hardware/atheros/wlan
# driver_cmd_nl80211 patch from jcsullins build
git apply $TOP/patches/patches/patches/hardware_atheros_wlan.patch
cd $TOP
#
echo "hardware/libhardware_legacy patch"
cd hardware/libhardware_legacy
# The ath6kl driver needs the interface up
git apply $TOP/patches/patches/patches/hardware_libhardware_legacy.patch
cd $TOP
#
echo "apply hardware/ril patch"
cd hardware/ril
# add BOARD_USES_MBM_RIL condition
git apply $TOP/patches/patches/patches/hardware_ril.patch
cd $TOP
#
echo "packages_apps_email patch"
cd packages/apps/Email
# Allow email download of compressed files
git apply $TOP/patches/patches/patches/packages_apps_Email.patch
cd $TOP
#
echo "packages/providers/DownloadProvider patch"
cd packages/providers/DownloadProvider
# Fix secondary storage support
git apply $TOP/patches/patches/patches/packages_providers_DownloadProvider.patch
cd $TOP
#
echo "apply vendor cm patch"
cd vendor/cm
# Allow non-release builds
git apply $TOP/patches/patches/patches/vendor_cm.patch
./get-prebuilts
cd $TOP
#==============================================================================
# Make clean build, set name, and build the ROM
#==============================================================================
echo "clean build and set name"
make clean
export CM_BUILDTYPE=MBM_L
export CM_EXTRAVERSION_DATESTAMP=1
export CM_EXTRAVERSION_TAG="4g_beta6_3.0"
#
repo diff > build.diff
#
echo "brunch tenderloin"
brunch tenderloin 2>&1 | tee kk_build.log
echo "Completed new build"
echo `date +%Y%m%d-%H%M`
