FROM ubuntu:latest

RUN useradd -rm -d /home/maoth -s /bin/bash -g root -G sudo -u 999 maoth && \
        apt update && apt upgrade -yq && \
        apt install -yq sudo file wget cpio unzip rsync && \
        apt install -yq git build-essential bc fakeroot libncurses5-dev libssl-dev ccache flex bison libelf-dev zstd bsdmainutils && \
        apt install -yq gcc-x86-64-linux-gnu g++-x86-64-linux-gnu

USER maoth
WORKDIR /home/maoth
