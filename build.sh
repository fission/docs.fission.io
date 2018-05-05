#!/bin/bash

set -euo pipefail

source version.sh

cd docs

echo "Running hugo"
hugo

cd ..

echo "Removing old site"
rm -rf dist/$VERSION

echo "Moving new site into dist"
mv docs/public dist/$VERSION

echo "Making _redirects"
echo "# Generated from _redirects.template" > dist/_redirects
cat _redirects.template | sed -e "s/VERSION/$VERSION/g" >> dist/_redirects

echo "Making index.html"
cat index.html.template | sed -e "s/VERSION/$VERSION/g" >> dist/index.html

