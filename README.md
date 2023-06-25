
Create image:
```
sudo docker build . -t lke
```

Create container:
```
sudo docker create -t lke \
-it \
lke
```

## Download Kernel
Download the kernel from https://kernel.org/ for the latest stable version.

## Build Deps
env:
```
sudo apt-get install libncurses-dev gawk flex bison openssl libssl-dev dkms libelf-dev libudev-dev libpci-dev libiberty-dev autoconf llvm cpio
```

## Build Kernel
Let's generate the `.config` file for the default x86_64 architecture.
```
cd  linux-6.3.8
make ARCH=x86_64 defconfig
```
You can checkout `make help` for more features. 

Compile it!
```
make -j$(nproc)
```

## Build the ramfs
```
cd simple_init
find . | cpio -o -H newc | gzip > root.cpio.gz
```

## Run in qemu
```
qemu-system-x86_64 \
--nographic \
-no-reboot \
-kernel ./linux-6.3.8/arch/x86/boot/bzImage \
-initrd simple_init/root.cpio.gz \
-append "panic=1 console=ttyS0"
```

`-append`: The qemu why to add the linux kernel argument 