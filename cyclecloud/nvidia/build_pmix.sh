#!/bin/bash

cd ~/
mkdir -p /shared/apps/pmix/2.1
yum install -y libevent-devel
mkdir -p pmix/build/2.1 pmix/install/2.1
cd pmix
git clone https://github.com/openpmix/openpmix.git source
cd source/
git branch -a
git checkout v2.1
git pull
./autogen.sh
cd ../build/2.1/
../../source/configure --prefix=/opt/pmix/2.1
make -j install >/dev/null
cd ../../install/2.1/
