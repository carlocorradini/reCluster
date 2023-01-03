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
# Arch linux version
ARG ARCH_VERSION=base
# Temporary directory
ARG TMP_DIR=/tmp/recluster

FROM archlinux:${ARCH_VERSION}
ARG TMP_DIR

# Update package list
RUN pacman -Syy

# Install packages
RUN yes | pacman -S \
  archiso

# Create directories
RUN mkdir \
  /run/shm \
  ${TMP_DIR} \
  ${TMP_DIR}/profile \
  ${TMP_DIR}/work \
  ${TMP_DIR}/out

# Copy profile
RUN cp -a /usr/share/archiso/configs/baseline/. ${TMP_DIR}/profile

# Remove files
RUN rm \
  ${TMP_DIR}/profile/profiledef.sh \
  ${TMP_DIR}/profile/packages.x86_64

# Bootstrap
ENTRYPOINT [ "/bin/sh" ]
