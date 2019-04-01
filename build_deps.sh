#!/usr/bin/env bash

DEPS_LOCATION=_build/deps

if [ -d "$DEPS_LOCATION" ]; then
    echo "cpp-driver fork already exist. delete $DEPS_LOCATION for a fresh checkout."
    exit 0
fi

OS=$(uname -s)
KERNEL=$(echo $(lsb_release -ds 2>/dev/null || cat /etc/*release 2>/dev/null | head -n1 | awk '{print $1;}') | awk '{print $1;}')

##echo $OS
##echo $KERNEL

CPP_DRIVER_REPO=https://github.com/datastax/cpp-driver.git
CPP_DRIVER_REV=$1

case $OS in
    Linux)
        case $KERNEL in
            CentOS)

                echo "Linux, CentOS"
                sudo yum -y install automake cmake gcc-c++ git libtool openssl-devel wget
                OUTPUT=`ldconfig -p | grep libuv`
                if [[ $(echo $OUTPUT) != "" ]]
                    then echo "libuv has already been installed"
                else
                    pushd /tmp
                    wget http://dist.libuv.org/dist/v1.8.0/libuv-v1.8.0.tar.gz
                    tar xzf libuv-v1.8.0.tar.gz
                    pushd libuv-v1.8.0
                    sh autogen.sh
                    ./configure
                    sudo make install
                    popd
                    popd

                    sudo grep -q -F '/usr/local/lib' /etc/ld.so.conf.d/usrlocal.conf || echo '/usr/local/lib' | sudo tee --append /etc/ld.so.conf.d/usrlocal.conf > /dev/null
                    sudo ldconfig -v

                fi
            ;;

            Ubuntu)

                echo "Linux, Ubuntu"

                sudo apt-add-repository -y ppa:linuxjedi/ppa
                sudo apt-get -y update
                sudo apt-get -y install g++ make cmake libuv-dev libssl-dev
            ;;

            *) echo "Your system $KERNEL is not supported"
        esac
    ;;

    Darwin)
        brew install libuv cmake openssl
        export OPENSSL_ROOT_DIR=$(brew --prefix openssl)
        export OPENSSL_INCLUDE_DIR=$OPENSSL_ROOT_DIR/include/
        export OPENSSL_LIBRARIES=$OPENSSL_ROOT_DIR/lib
        ;;

    *) echo "Your system $OS is not supported"
esac

mkdir -p $DEPS_LOCATION

#checkout repo

pushd $DEPS_LOCATION
git clone ${CPP_DRIVER_REPO}
pushd cpp-driver
git checkout ${CPP_DRIVER_REV}
popd
popd

#build

mkdir -p $DEPS_LOCATION/cpp-driver/build
pushd $DEPS_LOCATION/cpp-driver/build
cmake ..  -DCASS_BUILD_STATIC=ON  -DCASS_BUILD_SHARED=OFF -DCMAKE_CXX_FLAGS="-fPIC -Wno-class-memaccess -Wno-implicit-fallthrough" -DCMAKE_C_FLAGS="-fPIC"
make -j 12
popd