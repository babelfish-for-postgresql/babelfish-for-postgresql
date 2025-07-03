#!/bin/bash
# WIP
# XXX: push images matching labels in releases.json

## Requires the following variables declared:
# DOCKER_DOMAIN=docker.io
# DOCKER_REPOSITORY=${DOCKER_DOMAIN}/<user>/babelfishpg

. .env

DEFAULT_DISTRO="ubuntu"
DEFAULT_OSVERSION="focal"

function push() {
    docker tag babelfishpg:${BABELFISH_VERSION}-${DISTRO}.${OSVERSION} ${DOCKER_REPOSITORY}
    docker push ${DOCKER_REPOSITORY}
}

function help() { 
    echo "
        -T Babelfish tag, in the form of BABEL_2_1_1__PG_14_3 as eg. Mandatory.
        -o Operating System. Default: ubuntu
        -v Operating System version (eg. focal, bullseye, 8, etc.). Default: focal
    "
}

while getopts 'o:v:T:M:hl' OPT
do
    case "$OPT" in
        o)    DISTRO=$OPTARG ;;
        v)    OSVERSION=$OPTARG ;;
        T)    export TAG="$OPTARG" ;;
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

docker login
push
