#!/bin/bash

set -euo pipefail

pushd docs
npm install -D --save autoprefixer@9.7.6 postcss-cli@7.1.0

echo "Running hugo"
hugo

popd

echo "Removing old site"
rm -rf dist/public

mkdir -p dist
echo "Moving new site into dist"
mv docs/public dist/public

### Keepting this for future refence, not in use ATM
#echo "Making _redirects"
#echo "# Generated from _redirects.template" > dist/_redirects
#cat _redirects.template | sed -e "s/VERSION/$VERSION/g" >> dist/_redirects

#echo "Making index.html"
#cat index.html.template | sed -e "s/VERSION/$VERSION/g" > dist/index.html
