#!/bin/bash

# WIP 
# This would take the releases.json, parse and iterate and build accordingly
# to the host architecture
#   jq -r '.releases[].tag' releases.json


function help(){
    echo "
    ./build-wrapper [-b] [-r]
        -b Do the build
        -r Do the render
    "
}

while getopts 'brh' OPT
do
    case "$OPT" in
        b|--build)    export BUILD=1 ;;
        r|--render)   export RENDER=1 ;;
        h|--help) help ;;
        *)    help ; exit 1 ;;
    esac
done

if [ -v RENDER ]
then
    ./render.sh -o ubuntu -v focal -T BABEL_2_1_1__PG_14_3
    ./render.sh -o amazonlinux -v 2 -T BABEL_2_1_1__PG_14_3
    ./render.sh -o ubuntu -v focal -T BABEL_1_3_1__PG_13_7
fi

if [ -v BUILD ]
then
    echo "Build started."
    ./build.sh -o ubuntu -v focal -l -T BABEL_2_1_1__PG_14_3
    ./build.sh -o amazonlinux -v 2 -T BABEL_2_1_1__PG_14_3
    ./build.sh -o ubuntu -v focal -T BABEL_1_3_1__PG_13_7
fi


