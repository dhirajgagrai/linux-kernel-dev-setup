# Linux Kernel Development Setup for Docker

This repository documents my setup for Linux kernel development, including tools, configurations, and workflows to streamline the process.

## Table of Contents

- [Introduction](#introduction)
- [Installation](#installation)
  - [Prerequisites](#prerequisites)
  - [Building the Docker Image](#building-the-docker-image)
- [Workflow](#workflow)
  - [Cloning the Kernel Source](#cloning-the-kernel-source)
  - [Building the Kernel](#building-the-kernel)
  - [Building File System Image](#building-file-system-image)

## Introduction

This repository serves as a guide to set up a development environment in MacOS for working on the Linux kernel.
It includes essential tools, configurations, and best practices to make the workflow efficient.
My primary working machine is a M2 MacBook Air.

My username inside the Linux system is `maoth`. You can change this inside the Dockerfile provided above by replacing all instances of `maoth` word with the username you want to use.

## Installation

### Prerequisites

1. Install [Docker](https://www.docker.com/).
    - There is a regression in some Docker versions (*I am using 27.5.1, build 9f9e405*). So, Ubuntu crashes during the build process.
    - To deal with the above, goto `Docker Settings > General > Virtual Machine Options > Choose file sharing implementation for your containers` and set to `osxfs (Legacy)`.

2. It is not possible to build the kernel in the case-insensitive file system of MacOS. So, you need to create a new partition using Disk Utility.
   - Create a new partition of atleast 30GB.
   - Set the formatting option of this partition to **Mac OS Extended (Case-sensitive, Journaled)**.
   - *I gave the partition name as **Linux***. Make sure to change the symlink provided above according to the partition name.

### Building the Docker Image

1. Build the image using dockerfile.
   ```sh
   docker build -t ubuntu-dev .
   ```

   **Note:** We are using `ubuntu-dev` as the image name.

2. Create container and mount home directory of username to the partition created above.
   ```sh
   docker run -it -v /Volumes/Linux:/home/maoth ubuntu-dev /bin/bash
   ```

   **Note:** I have `maoth` as the username. Make changes as required.

3. Rename the container to something memorable.
   ```sh
   docker rename old-name new-name
   ```

   **Note:** We are using `kernel` as the new-name.

4. Exec.
   ```sh
   docker start kernel
   docker exec -it kernel /bin/bash
   ```

5. Set sudo password for the user:
   ```sh
   docker exec -u root -ti kernel /bin/bash
   ```

   Inside linux shell, use command given below to change password:
   ```sh
   passwd maoth
   ```

## Workflow

### Cloning the Kernel Source

1. Clone the Linux kernel source:
   ```sh
   git clone git://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git
   ```

2. Navigate into the kernel source directory:
   ```sh
   cd linux
   ```

3. Configure the kernel:
   ```sh
   make ARCH=x86_64 menuconfig
   ```

   - Enable required options (**I use defaults*) and `Save`.

### Building the Kernel

Build the kernel:
```sh
make ARCH=x86_64 CROSS_COMPILE=x86_64-linux-gnu- -j8
```

For testing changes, use QEMU for virtualization:
```sh
qemu-system-x86_64 -kernel arch/x86/boot/bzImage -hda /dev/zero -append "root=/dev/zero console=ttyS0" -serial stdio -display none
```

There will be an kernel panic - unable to mount root file system.

### Building File System Image

Use buildroot to generate a file system image. Download it into separate folder.
```sh
wget https://buildroot.org/downloads/buildroot-2024.02.10.tar.gz
tar xvf buildroot-2024.02.10.tar.gz
mv buildroot-2024.02.10 buildroot
cd buildroot
sudo make menuconfig
```

**Note:** I have downloaded the buildroot in the home directory.

Set `Target Options > Target Architecture > x86_64` also `Filesystem images > ext2/3/4 root file system > ext4` and `Save`.

We can generate filesystem image:
```sh
make ARCH=x86_64 -j8
```

**Note:** Go take a nap during the build process for above.

Now navigate to Linux repo and provide the filesystem path when launching qemu:
```sh
sudo qemu-system-x86_64 -s -kernel arch/x86/boot/bzImage -boot c -m 2049M -hda ~/buildroot/output/images/rootfs.ext4 -append "root=/dev/sda rw console=ttyS0,115200 acpi=off nokaslr" -serial stdio -display none
```

---

Feel free to contribute by submitting issues or pull requests!

