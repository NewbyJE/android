#/bin/bash
#
# Set environment for your build system
TOP=~/android/cm11-mbm_3.0; export TOP
#
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
echo "device/hp/tenderloin patch"
cd device/hp/tenderloin
# Remove all hostapd and tethering support
git apply $TOP/patches/patches/patches/device_hp_tenderloin.patch
cd $TOP
#
#==============================================================================
# Apply portrait patch
#==============================================================================
echo "device/hp/tenderloin portrait patch"
cd device/hp/tenderloin
# Setup for portrait mode
git apply $TOP/patches/patches/patches/device_hp_tenderloin_portrait.patch
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
# sync driver_cmd_nl80211 to upstream (James Sullins)
git apply $TOP/patches/patches/patches/hardware_atheros_wlan.patch
cd $TOP
#
echo "hardware/libhardware_legacy patch"
cd hardware/libhardware_legacy
# The ath6kl driver needs the interface up
git apply $TOP/patches/patches/patches/hardware_libhardware_legacy.patch
cd $TOP
#
echo "hardware/qcom/media-caf patch"
cd hardware/qcom/media-caf
git apply $TOP/patches/patches/patches/hardware_qcom_media-caf.patch
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
echo "apply vendor/mbm patch"
cd vendor/mbm
# Attemp to reset MBM on stall
git apply $TOP/patches/patches/patches/vendor_mbm.patch
cd $TOP
#
echo "apply vendor cm patch"
cd vendor/cm
# Allow non-release builds
git apply $TOP/patches/patches/patches/vendor_cm.patch
./get-prebuilts
cd $TOP
#
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
echo "Started new build"
echo `date +%Y%m%d-%H%M`
echo "brunch tenderloin"
brunch tenderloin 2>&1 | tee kk_build.log
echo "Completed new build"
echo `date +%Y%m%d-%H%M`
