#!/bin/bash


SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"
OUTDIR=/tmp/build

TAG=${TAG:-BABEL_2_1_0__PG_14_3}
EXTTAG=${EXTAG:-BABEL_2_1_0}

VERSION=$(echo $TAG | sed -r -e 's/BABEL_([0-9a-z_]*)__PG.*/\1/' -e 's/_/./g')


function helper() {
  sed -r -e 's/\{\{VERSION\}\}/'''$VERSION'''/'  $1
}

rm -rf ${OUTDIR}
mkdir -p $OUTDIR 2> /dev/null


cd ${OUTDIR}

git clone https://github.com/babelfish-for-postgresql/postgresql_modified_for_babelfish.git ${TAG}
git clone https://github.com/babelfish-for-postgresql/babelfish_extensions.git ${TAG}-babelfish-extensions


cd ${TAG}
git remote add ${TAG}_remote git@github.com:ongres/${TAG}.git
git checkout tags/${TAG}
cd ${OUTDIR} 

cd ${TAG}-babelfish-extensions
git checkout tags/${EXTTAG}
cd ${OUTDIR}

cp -r ${TAG}-babelfish-extensions/test ${TAG}/contrib 
cp -r ${TAG}-babelfish-extensions/contrib/babelfishpg_* ${TAG}/contrib 

cd ${TAG}
rm -rf .git/

if [ -n RELEASE_NOTES_LINK ]; then
  wget -O RELEASE_NOTES.md ${RELEASE_NOTES_LINK}
fi

helper ${SCRIPTPATH}/INSTALLING.md.tmpl > INSTALLING.md

cd ${OUTDIR}

zip -qr ${TAG}.zip ${TAG}/
tar cfz ${TAG}.tar.gz ${TAG}/

echo "Output files in: "
ls $OUTDIR/*.{zip,tar.gz}