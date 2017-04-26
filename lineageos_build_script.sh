#!/bin/bash

### Global variables ###
ACTION=$1
BASEDIR=`pwd`
ROMDIR=$BASEDIR/lineage
OUTDIR=/var/www/html
CCACHEDIR=$BASEDIR/.ccache
BUILDATE=`date '+%Y%m%d'`
CORES=`cat /proc/cpuinfo | grep "processor" | wc -l`


### System checking ###
echo "---------- Checking system ----------"
IFUBUNTU=$(cat /proc/version | grep ubuntu)


### Main ###
if [ "$IFUBUNTU" != "" ]; then
    ### Install dependencies ###
    if [ "$ACTION" == "build" ]; then
        echo "---------- Installing dependencies ----------"
        apt-get -y update
        apt-get -y install bison build-essential curl flex git gnupg gperf libesd0-dev libncurses5-dev libsdl1.2-dev libwxgtk3.0-dev libxml2 libxml2-utils lzop openjdk-8-jdk openjdk-8-jre pngcrush schedtool squashfs-tools xsltproc zip zlib1g-dev g++-multilib gcc-multilib lib32ncurses5-dev lib32readline-dev lib32z1-dev python2.7 python2.7-dev python-pip liblzma-dev bc unzip maven imagemagick

        # read -p "Install additional tools [y/n]: " add
        # if [[ "$add" == "y" ]] || [[ "$add" == "Y" ]]; then
        #     echo "---------- Installing additional tools ----------"
        #     apt-get -y install -y nginx screen vim htop
        # fi
        echo "---------- Installing additional tools ----------"
        apt-get -y install -y nginx screen vim htop
    
    
        ### Setup repo ###
        echo "---------- Setting up repo ----------"
        curl https://storage.googleapis.com/git-repo-downloads/repo > repo
        chmod a+x repo
        mv repo /usr/bin


        ### Setup work tree ###
        echo "---------- Setting up work tree ----------"
        mkdir $ROMDIR $CCACHEDIR
        cd $ROMDIR


        ### Setup git ###
        echo "---------- Setting up git ----------"
        git config --global user.name "YumeMichi"
        git config --global user.email "do4suki@gmail.com"


        ### Sync source code ###
        echo "---------- Syncing source code ----------"
        echo "y" | repo init -u git://github.com/LineageOS/android.git -b cm-14.1
        mkdir $ROMDIR/.repo/local_manifests
        wget -q https://raw.githubusercontent.com/Lineage-onyx/local_manifests/master/local_manifests.xml -O $ROMDIR/.repo/local_manifests/roomservice.xml
        repo sync -c -f -j8 --force-sync --no-clone-bundle --no-tags
    elif [ "$ACTION" == "update" ]; then
        ### Updating ###
        echo "---------- Cleaning up work tree ----------"
        cd $ROMDIR
        ./patcher/unpatcher.sh
        wget -q https://raw.githubusercontent.com/Lineage-onyx/local_manifests/master/local_manifests.xml -O $ROMDIR/.repo/local_manifests/roomservice.xml
        repo sync -c -f -j8 --force-sync --no-clone-bundle --no-tags
    else
        echo "---------- Nothing to do ----------"
        exit 1
    fi
else
    echo "Not support the system except Ubuntu for now!"
    exit 1
fi


### Cleanup patch ###
echo "---------- Patching ----------"
cd $ROMDIR
./patcher/unpatcher.sh
./patcher/patcher.sh


### Setup CCACHE ###
echo "---------- Setting up CCACHE ----------"
export USE_CCACHE=1
export CCACHE_DIR=$CCACHEDIR
./prebuilts/misc/linux-x86/ccache/ccache -M 10G


### Start building ###
echo "---------- Starting building ----------"
. build/envsetup.sh
lunch cm_onyx-userdebug
make bacon -j$CORES | tee $BUILDATE.log


### Copy zip to nginx dir ###
echo "---------- Copying zip to nginx dir ----------"
cp $ROMDIR/out/target/product/onyx/lineage-OMS-14.1-$BUILDATE-UNOFFICIAL-YumeMichi-onyx.zip $OUTDIR

### Finished ###
echo "---------- Finished ----------"
