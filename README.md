# Linux Kernel Development Setup for MacOS

This repository documents my setup for Linux kernel development, including tools, configurations, and workflows to streamline the process on MacOS.

## Table of Contents

- [Introduction](#introduction)
- [Installation](#installation)
  - [Prerequisites](#prerequisites)
  - [Setup Docker](#setup-docker)
- [Workflow](#workflow)
  - [Setup QEMU](#setup-qemu)
  - [Generate config and initrd](#generate-config-and-initrd)
  - [Build Kernel](#build-kernel)
  - [Test Build](#test-build)
- [Additional](#additional)

## Introduction

This repository serves as a guide to set up a development environment in MacOS for working on the Linux kernel.
It includes essential tools, configurations, and practices to make my workflow efficient.
My primary working machine is an M2 MacBook Air.

My username inside the Linux system is `maoth`.
You can change this inside the Dockerfile provided above by replacing all instances of `maoth` with the username you want to use.

This is the second iteration of my setup. The previous iteration had issues with tracking git files.
You can check the previous iteration on GitHub history.

## Installation

### Prerequisites

1. Install [Docker](https://www.docker.com/).

2. I want to use a shared volume between Docker and host system. The following steps help me in taking backups easily.
   It is not possible to build the kernel in the case-insensitive file system of MacOS.
   So, we need to create a new partition using Disk Utility if we wish to have a shared volume.
   - Create a new partition of atleast 90GB.
   - Set the formatting option of this partition to **Mac OS Extended (Case-sensitive, Journaled)**.
   - I gave the partition name as *Linux*. Make sure to change the symlink provided in the repo according to the partition name.

3. Install QEMU:
   ```sh
   brew install qemu
   ```

### Setup Docker

1. Build the docker image using dockerfile.
   ```sh
   docker build -t ubuntu-dev .
   ```

   **Note:** We are using `ubuntu-dev` as the image name.

2. Create container and mount home directory of username to the partition created above.
   ```sh
   docker run --name kernel-dev -it -v /Volumes/Linux:/home/maoth ubuntu-dev /bin/bash
   ```

   **Note:** I have `maoth` as the username. Make changes as required. We are using `kernel-dev` as the name for container.

3. After exiting from above, we may have to start the container (not sure):
   ```sh
   docker start kernel-dev
   ```

4. Set sudo password for the user using root:
   ```sh
   docker exec -u root -ti kernel-dev /bin/bash
   ```

   Inside linux shell, use command given below to change password:
   ```sh
   passwd maoth
   ```

5. We can exec normally now.
   ```sh
   docker exec -it kernel-dev /bin/bash
   ```

6. Clone the Linux kernel source:
   ```sh
   git clone git://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git
   ```

## Workflow

### Setup QEMU

For testing changes, we use QEMU for virtualization. First download a Linux image (I use Ubuntu Server 24.04.1 arm64).

1. We need an UEFI firmware for booting QEMU, we can use the one provided with QEMU itself: `/opt/homebrew/Cellar/qemu/9.2.0/share/qemu/edk2-aarch64-code.fd`

2. Create a disk somewhere:
   ```sh
   qemu-img create -f qcow2 ubuntu.img 50G
   ```

3. Launch the image and install it on the created disk using the QEMU graphical window:
   ```sh
   qemu-system-aarch64 \
      -monitor stdio \
      -display default,show-cursor=on \
      -M virt \
      -accel hvf \
      -cpu host \
      -smp 4 \
      -m 4G \
      -bios edk2-aarch64-code.fd \
      -device virtio-gpu-pci \
      -device qemu-xhci \
      -device usb-kbd \
      -device usb-tablet \
      -device intel-hda \
      -device hda-duplex \
      -device virtio-net-pci,netdev=net0 \
      -netdev user,id=net0,hostfwd=tcp::8022-:22 \
      -drive if=virtio,file=ubuntu.img,format=qcow2 \
      -cdrom /Volumes/Expansion/BACKUPS_Images/ubuntu-24.04.1-live-server-arm64.iso
   ```

   **Note:** Provide the correct path to images above in `file` and `-cdrom` option.

### Generate config and initrd

1. After installation is done, launch the raw disk image:
   ```sh
   qemu-system-aarch64 \
   qemu-system-aarch64 \
      -monitor stdio \
      -display default,show-cursor=on \
      -M virt \
      -accel hvf \
      -cpu host \
      -smp 4 \
      -m 4G \
      -bios edk2-aarch64-code.fd \
      -device virtio-gpu-pci \
      -device qemu-xhci \
      -device usb-kbd \
      -device usb-tablet \
      -device intel-hda \
      -device hda-duplex \
      -device virtio-net-pci,netdev=net0 \
      -netdev user,id=net0,hostfwd=tcp::8022-:22 \
      -drive if=virtio,file=ubuntu.img,format=qcow2
   ```

2. Run update:
   ```sh
   sudo apt update && sudo apt upgrade
   ```

3. Copy the config file from `/boot`:
   ```sh
   cp /boot/config* ~/.config
   ```

4. Install and start SSH for file transfer:
   ```sh
   sudo apt install openssh-server
   sudo systemctl enable ssh
   sudo systemctl start ssh
   ```

5. From MacOS shell, copy the files:
   ```sh
   scp -P 8022 maoth@localhost:{.config} .
   ```

6. Move the config file into linux source directory:
   ```sh
   mv .config /Volumes/Linux/linux/
   ```

   **Note:** `/Volumes/Linux/` is the partition I created previously in *Prerequisites* step 2.

### Build Kernel

1. Get into the Docker shell:
   ```sh
   docker exec -it kernel-dev /bin/bash
   ```

2. Navigate into the kernel source directory:
   ```sh
   cd linux
   ```

3. Build the config file:
   ```sh
   make olddefconfig
   ```

4. Run the following scripts to disbale errors regarding certificates:
   ```sh
   scripts/config --disable SYSTEM_TRUSTED_KEYS
   scripts/config --disable SYSTEM_REVOCATION_KEYS
   ```
5. Build the kernel:
   ```sh
   make -j8
   ```

6. Build the modules and copy required files:
   ```sh
   mkdir -p ~/tmp_modules
   make modules_install INSTALL_MOD_PATH=~/tmp_modules/
   cp arch/arm64/boot/Image ~/tmp_modules/
   cp .config ~/tmp_modules/config-<kernel-version>
   ```

   **Note:** Find the kernel version in `tmp_modules/lib/modules/<kernel-version>`.

7. We need to copy files to QEMU machine. First share the directory created above:
   ```sh
   qemu-system-aarch64 \      
      -monitor stdio \
      -display default,show-cursor=on \
      -M virt \
      -accel hvf \
      -cpu host \
      -smp 4 \
      -m 4G \
      -bios edk2-aarch64-code.fd \
      -device virtio-gpu-pci \
      -device qemu-xhci \
      -device usb-kbd \
      -device usb-tablet \
      -device intel-hda \
      -device hda-duplex \
      -device virtio-net-pci,netdev=net0 \
      -netdev user,id=net0,hostfwd=tcp::8022-:22 \
      -drive if=virtio,file=ubuntu.img,format=qcow2 \
      -fsdev local,id=host_share,path=tmp_modules,security_model=passthrough \
      -device virtio-9p-pci,fsdev=host_share,mount_tag=build_share
   ```

8. Mount the shared directory inside QEMU:
   ```sh
   sudo mkdir -p /mnt/host_share
   sudo mount -t 9p -o trans=virtio,version=9p2000.L build_share /mnt/host_share
   ```

9. Copy the files:
   ```sh
   sudo cp -r /mnt/host_share/lib/modules/<kernel-version> /lib/modules/
   sudo cp /mnt/host_share/Image /boot/vmlinuz-<kernel-version>
   sudo cp /mnt/host_share/config-6.8.0-dirty /boot/
   ```

10. Generate `initrd` and update GRUB:
   ```sh
   sudo update-initramfs -c -k <kernel-version>
   ```

11. Make changes to the GRUB. Comment out GRUB_TIMEOUT_STYLE and set timeout to some positive value GRUB_TIMEOUT = 5.
   ```sh
   sudo vi /etc/default/grub
   sudo update-grub
   ```

### Test Build

Launch the installed image and selet the newly installed kernel in GRUB menu:
```sh
qemu-system-aarch64 \      
   -monitor stdio \
   -display default,show-cursor=on \
   -M virt \
   -accel hvf \
   -cpu host \
   -smp 4 \
   -m 4G \
   -bios edk2-aarch64-code.fd \
   -device virtio-gpu-pci \
   -device qemu-xhci \
   -device usb-kbd \
   -device usb-tablet \
   -device intel-hda \
   -device hda-duplex \
   -device virtio-net-pci,netdev=net0 \
   -netdev user,id=net0,hostfwd=tcp::8022-:22`
```

## Additional

- [Linux Foundation - Beginner's Guide](https://trainingportal.linuxfoundation.org/courses/a-beginners-guide-to-linux-kernel-development-lfd103)
- [Kernel Newbies](https://kernelnewbies.org/FirstKernelPatch)
- [kernel.org](https://www.kernel.org/doc/html/latest/process/howto.html)
- [VMWare Fusion](https://blogs.vmware.com/teamfusion/2024/05/fusion-pro-now-available-free-for-personal-use.html) - for kernel testing.
- [Running a full arm64 system stack under QEMU](https://cdn.kernel.org/pub/linux/kernel/people/will/docs/qemu/qemu-arm64-howto.html)

---

Feel free to contribute by submitting issues or pull requests!

