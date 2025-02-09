# Linux Kernel Development Setup for Docker

This repository documents my setup for Linux kernel development, including tools, configurations, and workflows to streamline the process on MacOS.

## Table of Contents

- [Introduction](#introduction)
- [Installation](#installation)
  - [Prerequisites](#prerequisites)
  - [Building the Docker Image](#building-the-docker-image)
- [Workflow](#workflow)
  - [Cloning the Kernel Source](#cloning-the-kernel-source)
  - [Building the Kernel](#building-the-kernel)
  - [Building File System Image](#building-file-system-image)
  - [QEMU virtualization](#qemu-virtualization)
- [Additional](#additional)

## Introduction

This repository serves as a guide to set up a development environment in MacOS for working on the Linux kernel.
It includes essential tools, configurations, and best practices to make the workflow efficient.
Please note that my primary working machine is an M2 MacBook Air and we building for `x86-64` target.

My username inside the Linux system is `maoth`. You can change this inside the Dockerfile provided above by replacing all instances of `maoth` with the username you want to use.

## Installation

### Prerequisites

1. Install [Docker](https://www.docker.com/).
    - There is a regression in some versions of Docker (*I am using 27.5.1, build 9f9e405*). So, Ubuntu crashes during the build process.
    - To deal with the above, goto `Docker Settings > General > Virtual Machine Options` and set the following two:
    - `Choose Virtual Machine Manager (VMM) > Apple Virtualization Framework` and `Choose file sharing implementation for your containers > osxfs (Legacy)`.

2. It is not possible to build the kernel in the case-insensitive file system of MacOS. So, you need to create a new partition using Disk Utility.
   - Create a new partition of atleast 30GB.
   - Set the formatting option of this partition to **Mac OS Extended (Case-sensitive, Journaled)**.
   - I gave the partition name as *Linux*. Make sure to change the symlink provided in the repo according to the partition name.

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


4. Set sudo password for the user using root:
   ```sh
   docker exec -u root -ti kernel /bin/bash
   ```

   Inside linux shell, use command given below to change password:
   ```sh
   passwd maoth
   ```

5. We can exec normally now.
   ```sh
   docker start kernel
   docker exec -it kernel /bin/bash
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

   - Enable required options (*I am using defaults*) and `Save`.

### Building the Kernel

Build the kernel:
```sh
make ARCH=x86_64 CROSS_COMPILE=x86_64-linux-gnu- -j8
```

If you errors regarding certificates, execute the following and run `make` again.
```sh
scripts/config --disable SYSTEM_TRUSTED_KEYS
scripts/config --disable SYSTEM_REVOCATION_KEYS
```

For testing changes, use QEMU for virtualization:
```sh
qemu-system-x86_64 -kernel arch/x86/boot/bzImage -hda /dev/zero -append "root=/dev/zero console=ttyS0" -serial stdio -display none
```

Kernel will panic - unable to mount root file system.

### Building File System Image

Use buildroot to generate a file system image. Download it into separate folder.
```sh
wget https://buildroot.org/downloads/buildroot-2024.02.10.tar.gz
tar xvf buildroot-2024.02.10.tar.gz
mv buildroot-2024.02.10 buildroot
cd buildroot
```

Generate the config file:
```sh
sudo make menuconfig
```

**Note:** I have downloaded the buildroot in the home directory.

Set `Target Options > Target Architecture > x86_64` also `Filesystem images > ext2/3/4 root file system > ext4` and `Save`.

We can generate filesystem image:
```sh
make ARCH=x86_64 -j8
```

**Note:** Go take a nap during the build process for above.

### QEMU Virtualization

Now navigate to the Linux repo and provide the filesystem image path when launching qemu:
```sh
sudo qemu-system-x86_64 -s -kernel arch/x86/boot/bzImage -boot c -m 2049M -hda ~/buildroot/output/images/rootfs.ext4 -append "root=/dev/sda rw console=ttyS0,115200 acpi=off nokaslr" -serial stdio -display none
```

**Note:** buildroot login username is `root` and password is empty.

## Additional

- [Linux Foundation - Beginner's Guide](https://trainingportal.linuxfoundation.org/courses/a-beginners-guide-to-linux-kernel-development-lfd103)
- [Kernel Newbies](https://kernelnewbies.org/FirstKernelPatch)
- [kernel.org](https://www.kernel.org/doc/html/latest/process/howto.html)
- [VMWare Fusion](https://blogs.vmware.com/teamfusion/2024/05/fusion-pro-now-available-free-for-personal-use.html) - for kernel testing.

This will come as a surprise but I use VMWare Fusion heavily for testing purposes. I am still getting familiar with QEMU and hope to replace VMWare with it. My workflow with VMWare Fusion can probably be its own guide, so I am not including it here.
Following the Linux Foundation guide with VMWare can probably be sufficient for MacOS development setup. However, it does not provide the flexibility of having my own developer UX and environment.

---

Feel free to contribute by submitting issues or pull requests!

