FROM ubuntu:latest

ENV DEBIAN_FRONTEND=noninteractive

RUN useradd -rm -d /home/maoth -s /bin/bash -g root -G sudo -u 999 maoth && \
        apt update && apt upgrade -yq && \
        apt install -yq sudo file wget rsync git && \
        apt install -yq build-essential bc fakeroot libncurses5-dev libssl-dev ccache flex bison libelf-dev && \
        apt install -yq cpio unzip zstd bsdmainutils python3 kmod && \
        apt install -yq gcc g++

USER maoth
WORKDIR /home/maoth
