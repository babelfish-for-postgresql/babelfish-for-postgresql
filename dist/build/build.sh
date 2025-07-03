#!/bin/bash

SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"
OUTDIR=/tmp/build
ENG_URL="https://github.com/babelfish-for-postgresql/postgresql_modified_for_babelfish.git"
EXT_URL="https://github.com/babelfish-for-postgresql/babelfish_extensions.git"

function help(){
  echo "
    Export the following environment variables: TAG, EXTTAG, RELEASE_NOTES_LINK
    Then, execute: ./build.sh
  "
  exit 0
}

if [ ! -v TAG ]
then
    printf "TAG is a mandatory environment variable.\n"
    exit 2
fi

if [ ! -v EXTTAG ]
then
    printf "EXTTAG is a  environment variable.\n"
    exit 2
fi

if [ ! -v RELEASE_NOTES_LINK ]
then
    printf "RELEASE_NOTES_LINK is a  environment variable with the raw release notes content.\n"
    exit 2
fi

VERSION=$(echo $TAG | sed -r -e 's/BABEL_([0-9a-z_]*)__PG.*/\1/' -e 's/_/./g')

function helper() {
  sed -r -e 's/\{\{VERSION\}\}/'''$VERSION'''/'  $1
}

rm -rf ${OUTDIR}
mkdir -p $OUTDIR 2> /dev/null


cd ${OUTDIR}

git clone --single-branch -b ${TAG}     ${ENG_URL} ${TAG}
git clone --single-branch -b ${EXTTAG}  ${EXT_URL} ${TAG}-babelfish-extensions

cp -r ${TAG}-babelfish-extensions/test ${TAG}/contrib 
cp -r ${TAG}-babelfish-extensions/contrib/babelfishpg_* ${TAG}/contrib 

cd ${TAG}
rm -rf .git/

if [ -v RELEASE_NOTES_LINK ]; then
  wget -O RELEASE_NOTES.md ${RELEASE_NOTES_LINK}
fi

helper ${SCRIPTPATH}/INSTALLING.md.tmpl > INSTALLING.md

cd ${OUTDIR}

zip -qr ${TAG}.zip ${TAG}/
tar cfz ${TAG}.tar.gz ${TAG}/

echo "Output files in: "
ls $OUTDIR/*.{zip,tar.gz}