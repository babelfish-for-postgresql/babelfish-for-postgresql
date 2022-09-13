#!/bin/sh


find distros -mindepth 1 -maxdepth 1 -printf "%f\n" | while read -r DISTRO
do 
  echo "Generating doc $DISTRO"

  python doc-templater.py "$DISTRO"

done