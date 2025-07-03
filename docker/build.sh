#!/bin/bash


DEFAULT_DISTRO="ubuntu"
DEFAULT_OSVERSION="focal"

function build() {
    cd ${BABELFISH_VERSION}/$DISTRO/$OSVERSION
    docker build $BUILD_ARG_MAX_JOBS $LATEST \
        -t babelfishpg:${BABELFISH_VERSION}-${DISTRO}.${OSVERSION} \
        -t babelfishpg:$(uname -m) .

}

function help() { 
    echo "
        -T Babelfish tag, in the form of BABEL_2_1_1__PG_14_3 as eg. Mandatory.
        -o Operating System. Default: ubuntu
        -v Operating System version (eg. focal, bullseye, 8, etc.). Default: focal
        -M MAX_JOBS (number of parallel build). Default: 2
    "
}

while getopts 'o:v:T:M:hl' OPT
do
    case "$OPT" in
        o)    DISTRO=$OPTARG ;;
        v)    OSVERSION=$OPTARG ;;
        T)    export TAG="$OPTARG" ;;
        M)    export BUILD_ARG_MAX_JOBS=" --build-arg MAX_JOBS=$OPTARG" ;;
        h|--help) help ;;
        l)    LATEST=" -t babelfishpg:latest " ;;
        *)    help ; exit 1 ;;
    esac
done

if [ ! -v TAG ]
then
    printf "TAG is a mandatory argument (-T).\n"
    help
    exit 2
fi

export DISTRO=${DISTRO:DEFAULT_DISTRO}
export OSVERSION=${OSVERSION:DEFAULT_OSVERSION}

export BABELFISH_VERSION=$(echo $TAG | sed -r -e 's/BABEL_([0-9a-z_]*)__PG.*/\1/' -e 's/_/./g')

if [ ! -f $BABELFISH_VERSION/$DISTRO/$OSVERSION/Dockerfile ]
then
    printf "Dockerfile for that set of arguments does not exists, \n see ./render.sh"
    exit 3
fi

build