# syntax=docker/dockerfile:1
#
# This source file is part of the JASS open source project
#
# SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the JASS project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
#
# SPDX-License-Identifier: MIT
#

# ARG baseimage=swift:focal

# ================================
# Build image
# ================================
FROM swiftarm/swift:5.5.1-ubuntu-20.04 as build
# FROM ghcr.io/apodini/swift@sha256:53b4295f95dc1eafcbc2e03c5dee41839e9652ca31397b9feb4d8903fe1b54ea as build
# FROM ghcr.io/apodini/swift:nightly as build
# FROM ${baseimage} as build

# Install OS updates and, if needed, sqlite3
RUN export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
    && apt-get -q update \
    && apt-get -q dist-upgrade -y \
    && apt-get install -y libsqlite3-dev libavahi-compat-libdnssd-dev \
    && rm -rf /var/lib/apt/lists/*

# Set up a build area
WORKDIR /build

# Copy all source files
COPY . .

# Build everything, with optimizations and test discovery and
RUN swift build

WORKDIR /staging

RUN cp "$(swift build --package-path /build --show-bin-path)/DemoWebService" ./

# ================================
# Run image
# ================================
#
# FROM ghcr.io/apodini/swift@sha256:53b4295f95dc1eafcbc2e03c5dee41839e9652ca31397b9feb4d8903fe1b54ea as run
FROM swiftarm/swift:5.5.1-ubuntu-20.04 as run
# FROM ghcr.io/apodini/swift:nightly as run

# Make sure all system packages are up to date.
RUN export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
    && apt-get -q update \
    && apt-get -q dist-upgrade -y \
    && rm -r /var/lib/apt/lists/*

# Create a apodini user and group with /app as its home directory
RUN useradd --user-group --create-home --system --skel /dev/null --home-dir /app apodini

WORKDIR /app

COPY --from=build --chown=apodini:apodini /staging /app

USER apodini:apodini

ENTRYPOINT ["./DemoWebService"]
