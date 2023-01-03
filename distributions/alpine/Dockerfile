# MIT License
#
# Copyright (c) 2022-2023 Carlo Corradini
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

# ================
# CONFIGURATION
# ================
# Alpine linux version
ARG ALPINE_VERSION=3.17

FROM alpine:${ALPINE_VERSION}

# Update package list
RUN apk update

# Install packages
RUN apk add \
  alpine-sdk \
  build-base \
  apk-tools \
  alpine-conf \
  busybox \
  fakeroot \
  syslinux \
  xorriso \
  squashfs-tools \
  sudo \
  mtools \
  dosfstools \
  grub-efi

# Create user
RUN adduser \
  --disabled-password \
  --home /home/build \
  --ingroup abuild \
  build

# Give administrative access to abuild group
RUN printf '%s\n' "%abuild ALL=(ALL) ALL" > /etc/sudoers.d/abuild

# Create signing keys
RUN abuild-keygen -n --install --append

# Clone aports repository
RUN git clone --depth=1 https://gitlab.alpinelinux.org/alpine/aports.git /home/build/aports

# Bootstrap
ENTRYPOINT [ "/bin/sh" ]
