#!/usr/bin/env bash

CWD="${pwd}"
NU_VERSION="0.66.2"
NU_DIR=./nushell
NU_ARCHIVE="nu-${NU_VERSION}-x86_64-unknown-linux-musl.tar.gz"
BASE_URL="https://github.com/nushell/nushell/releases/download"

## Fetch a temporary bootstrap Nushell
if [[ ! -f $NU_DIR/$NU_ARCHIVE ]] ; then
    echo "Downloading bootstrap Nushell"
    mkdir -p $NU_DIR
    cd $NU_DIR
    wget $BASE_URL/$NU_VERSION/$NU_ARCHIVE
    tar -xf $NU_ARCHIVE
    cd ..
else
    echo "Bootstrap Nushell already downloaded"
fi

## Fetch the tools and store them in  ~/.cargo/bin
nushell/nu ./fetch-tools.nu

## Configure the ZO.N.Z.A. stack

# TODO



## Cleanup

# TODO: ask user
# rm -rf $NU_DIR
