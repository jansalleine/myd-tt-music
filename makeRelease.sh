#!/bin/sh
rm -rf release
mkdir release
cp -v ttmusic.prg release/ttmusic-myd.prg
cp -v screenshot.png release/
cp -r -v res/sid/sid release/.
cd release/sid
zip -r ../ttmusic-myd-sids.zip ./
cd ..
rm -rf sid
cd ..
