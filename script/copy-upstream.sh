#!/bin/bash

# Copy the upstream msgstream C library into sources
# These files are intended to be committed to version control
# despite being automatically generated. This is because it's
# a source release of msgstream instead of the source repo's
# content.

set -e
set -x

if [ ! -d Sources ]; then
	echo "Please run $0 from the MsgStream.swift root directory"
	exit 1
fi

VERSION="0.3.2"
TGZ="msgstream-$VERSION.tgz"
curl -LO "https://github.com/gulachek/msgstream/releases/download/v$VERSION/$TGZ"

DIR="Sources/CMsgStream"
if [ -d "$DIR" ]; then
	rm -rf "$DIR"
fi

mkdir "$DIR"
tar xzf "$TGZ" --strip-components 1 -C "$DIR"
rm "$TGZ"

rm -rf "$DIR/pkgconfig"
rm -rf "$DIR/cmake"
rm -f "$DIR/CMakeLists.txt"
