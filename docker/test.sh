#!/bin/bash

# WIP

DEFAULT_DISTRO="ubuntu"
DEFAULT_OSVERSION="focal"

function test(){
        docker run -d -i -t  \
                -e POSTGRES_PASSWORD=password -e POSTGRES_DB=postgres \
                -e POSTGRES_USER=postgres -e BABELFISH_USER=bbf \
                -e BABELFISH_PASS=password -e BABELFISH_DB=bbf \
                -e BABELFISH_MIGRATION_MODE=multi-db \
                -e POSTGRES_HOST_AUTH_METHOD=trust \
                -p 1433:1433 -p 5432:15432 \
                --name babelfishpg-${BABELFISH_VERSION}-${DISTRO}.${OSVERSION} \
                babelfishpg:${BABELFISH_VERSION}-${DISTRO}.${OSVERSION}
        
        docker stop babelfishpg-${BABELFISH_VERSION}-${DISTRO}.${OSVERSION}
        docker rm babelfishpg-${BABELFISH_VERSION}-${DISTRO}.${OSVERSION}

}


while getopts 'o:v:T:lh' OPT
do
    case "$OPT" in
        o)    export DISTRO=$OPTARG ;;
        v)    export OSVERSION=$OPTARG ;;
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

test