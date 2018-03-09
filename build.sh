#!/bin/bash

set -eu

source version.sh

cd docs

echo "Running hugo"
hugo

cd ..

echo "Removing old site"
rm -rf dist/$VERSION

echo "Moving new site into dist"
mv docs/public dist/$VERSION

echo "Making latest symlink"
cd dist
rm -f latest
ln -s $VERSION latest
