#/bin/bash
#
# Set environment for your build system
TOP=~/android/cm11-mbm; export TOP
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
repo status
#
echo "apply hardware/atheros/wlan cherrypicks"
pushd hardware/atheros/wlan
# sync driver_cmd_nl80211 to upstream (James Sullins)
git fetch http://review.cyanogenmod.org/CyanogenMod/android_hardware_atheros_wlan refs/changes/04/58704/1 && git cherry-pick -n FETCH_HEAD
git reset HEAD
popd
#
echo "apply packages/apps/Bluetooth cherrypicks"
pushd packages/apps/Bluetooth
# btservice/AdaperState: handle ENABLED_READY in OffState (James Sullins)
git fetch http://review.cyanogenmod.org/CyanogenMod/android_packages_apps_Bluetooth refs/changes/80/54380/1 && git cherry-pick -n FETCH_HEAD
git reset HEAD
popd
#
echo "apply hardware/ril patch"
cd hardware/ril
# add BOARD_USES_MBM_RIL condition
git apply $TOP/patches/patches/hardware_ril.patch
cd $TOP
#
echo "system_core patch"
cd system/core
# Increased size for dmesg dump
git apply $TOP/patches/patches/system_core.patch
cd $TOP
#
echo "apply vendor cm patch"
cd vendor/cm
# Allow non-release builds
git apply $TOP/patches/patches/vendor_cm.patch
./get-prebuilts
cd $TOP
#
echo "clean build and set name"
make clean
export CM_BUILDTYPE=MBM_L
export CM_EXTRAVERSION_DATESTAMP=1
export CM_EXTRAVERSION_TAG="4g_beta6"
#
echo "brunch tenderloin"
brunch tenderloin 2>&1 | tee jb_build.log
echo "Completed new build"
echo `date +%Y%m%d-%H%M`
