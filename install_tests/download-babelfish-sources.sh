#!/bin/sh

rm -rf postgresql_modified_for_babelfish
rm -rf babelfish_extensions
rm BABEL_1_X_DEV__13_4.zip
rm BABEL_1_X_DEV.zip

wget https://github.com/babelfish-for-postgresql/postgresql_modified_for_babelfish/archive/refs/heads/BABEL_1_X_DEV__13_4.zip

unzip BABEL_1_X_DEV__13_4.zip

mv postgresql_modified_for_babelfish-BABEL_1_X_DEV__13_4 postgresql_modified_for_babelfish

wget https://github.com/babelfish-for-postgresql/babelfish_extensions/archive/refs/heads/BABEL_1_X_DEV.zip

unzip BABEL_1_X_DEV.zip

mv babelfish_extensions-BABEL_1_X_DEV babelfish_extensions

rm BABEL_1_X_DEV__13_4.zip
rm BABEL_1_X_DEV.zip
