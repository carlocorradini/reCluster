#!/usr/bin/env bash
# MIT License
#
# Copyright (c) 2022-2022 Carlo Corradini
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# Current directory
DIRNAME="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly DIRNAME
# Alpine version
readonly ALPINE_VERSION=v3.15
# mkimage profile
MKIMAGE_PROFILE=$(readlink -f "$DIRNAME/mkimg.recluster.sh")
readonly MKIMAGE_PROFILE
# mkimage iso directory
MKIMAGE_ISO_DIR=$(readlink -f "$DIRNAME/iso")
readonly MKIMAGE_ISO_DIR
# genapkovl
GENAPKOVL=$(readlink -f "$DIRNAME/genapkovl-recluster.sh")
readonly GENAPKOVL

if [ -d  "$MKIMAGE_ISO_DIR" ]; then
  rm -rf "$MKIMAGE_ISO_DIR"
fi
mkdir "$MKIMAGE_ISO_DIR"

CONTAINER=$(docker run --volume "$MKIMAGE_PROFILE:/home/build/aports/scripts/mkimg.recluster.sh" --volume "$GENAPKOVL:/home/build/aports/scripts/genapkovl-recluster.sh" --volume "$MKIMAGE_ISO_DIR:/home/build/iso" --detach --interactive --tty recluster/alpine:latest)
readonly CONTAINER

docker exec "$CONTAINER" chmod +x /home/build/aports/scripts/mkimg.recluster.sh /home/build/aports/scripts/genapkovl-recluster.sh

docker exec "$CONTAINER" /home/build/aports/scripts/mkimage.sh --tag "$ALPINE_VERSION" --outdir /home/build/iso --arch x86_64 --repository "http://dl-cdn.alpinelinux.org/alpine/$ALPINE_VERSION/main" --repository "http://dl-cdn.alpinelinux.org/alpine/$ALPINE_VERSION/community" --profile recluster

docker stop "$CONTAINER"

docker rm "$CONTAINER"
