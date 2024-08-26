#!/bin/bash

echo
echo "--------------------------------------"
echo "     Modified AOSP 14.0 Buildbot      "
echo "                  by                  "
echo "                ponces                "
echo "  (modified for single build + patch) "
echo "--------------------------------------"
echo

set -e

BL=$PWD/treble_aosp
BD=$HOME/builds

setupEnv() {
    echo "--> Setting up build environment"
    source build/envsetup.sh &>/dev/null
    mkdir -p $BD
    echo
}

buildTrebleApp() {
    echo "--> Building treble_app"
    cd treble_app
    bash build.sh release
    cp TrebleApp.apk ../vendor/hardware_overlay/TrebleApp/app.apk
    cd ..
    echo
}

buildVariant() {
    echo "--> Building treble_arm64_bvN"
    lunch treble_arm64_bvN-userdebug
    make -j$(nproc --all) installclean
    make -j$(nproc --all) systemimage
    make -j$(nproc --all) target-files-package otatools
    bash $BL/sign.sh "vendor/ponces-priv/keys" $OUT/signed-target_files.zip
    unzip -jo $OUT/signed-target_files.zip IMAGES/system.img -d $OUT
    mv $OUT/system.img $BD/system-treble_arm64_bvN.img
    echo
}

generatePackages() {
    echo "--> Generating package"
    buildDate="$(date +%Y%m%d)"
    file="$BD/system-treble_arm64_bvN.img"
    name="aosp-arm64-ab-vanilla-14.0-$buildDate"
    xz -cv "$file" -T0 > $BD/"$name".img.xz
    rm -rf $file
    echo
}

START=$(date +%s)

setupEnv
buildTrebleApp
buildVariant
generatePackages

END=$(date +%s)
ELAPSEDM=$(($(($END-$START))/60))
ELAPSEDS=$(($(($END-$START))-$ELAPSEDM*60))

echo "--> Modified buildbot completed in $ELAPSEDM minutes and $ELAPSEDS seconds"
echo
