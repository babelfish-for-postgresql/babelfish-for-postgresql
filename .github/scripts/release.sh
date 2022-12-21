#!/bin/bash

function help(){
  echo "
    Export the following environment variables: TAG, LOC
    Then, execute: ./release.sh
  "
  exit 0
}

if [ ! -v TAG ]
then
    printf "TAG is a mandatory environment variable.\n"
    exit 2
fi

if [ ! -v LOC ]
then
    printf "LOC is a mandatory environment variable.\n"
    exit 2
fi

# extract babelfish and engine version
VERSION=$(echo $TAG | sed -r -e 's/BABEL_([0-9a-z_]*)__PG.*/\1/' -e 's/_/./g')
ENGINE=$(echo $TAG | sed -r -e 's/BABEL_([0-9_]*)__PG_([0-9]+_)/\2/' -e 's/_/./g')

title="Babelfish ${VERSION} for PostgreSQL ${ENGINE}"

# change babelfish version format to major-minor-patch
VERSION=$(echo $TAG | sed -r -e 's/BABEL_([0-9a-z_]*)__PG.*/\1/' -e 's/_/-/g')

release=$title". The release notes are [here](https://babelfishpg.org/docs/versions/babelfish-${VERSION}.html)."

echo "
Releasing
Tag: $TAG
Title: $title
Attachments: ${LOC}${TAG}.*
Release Notes: $release
"

gh release create --draft $TAG ${LOC}${TAG}.* -d -t "$title" -n "$release"
