#!/bin/sh

# Keep this version updated to the latest release (would be super nice
# to do this automatically with the github api!)
VERSION=0.6.0

echo "Running hugo"
hugo

echo "Removing old site"
rm -rf dist/$VERSION

echo "Copying new site"
mv public dist/$VERSION

echo "Making latest symlink"
cd dist
rm -f latest
ln -s $VERSION latest
