#!/bin/sh

CDIR=`pwd`
SRCDIR="${CDIR}/src"

rm -rf src
mkdir -p src
cd src

NUMCORE=$(cat /proc/cpuinfo | grep -c cores)
export NUMCORE

if [ ! -d "incubator-pagespeed-mod" ]; then
    echo "cloning.."
    git clone -c advice.detachedHead=false --recursive https://github.com/apache/incubator-pagespeed-mod.git
    cd incubator-pagespeed-mod
else
    echo "pulling.."
    cd incubator-pagespeed-mod
    git pull --recurse-submodules
fi

# Do a hard reset to the last working commit (before bazel got introduced)
git reset --hard 409bd76

git submodule update --init --recursive --jobs=${NUMCORE} --force


# Apply some handpicked PR's from https://github.com/apache/incubator-pagespeed-mod/
for PR in `ls ${CDIR}/pr`
do
    patch -p1 < ${CDIR}/pr/${PR}
done

cd ${CDIR}
for DIST in trusty xenial bionic focal jammy
do
    cp docker/Dockerfile-template docker/Dockerfile
    sed -i s/OS/ubuntu-base/ docker/Dockerfile
    sed -i s/DIST/${DIST}/ docker/Dockerfile
    cd docker
    docker build --no-cache -t eilandert/psol:${DIST} .
    docker run --volume ${SRCDIR}:/usr/src eilandert/psol:${DIST}
    cd ..
done
