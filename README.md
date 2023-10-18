
## Docker
Create docker image to run the qemu:
```
make docker-create-image
```

Create create the container and run it:
```
make docker-run-bash
```

Now in side the docker, we do following to have our kernel build and run in the qemu


## Install Deps
env:
```
apt update
apt-get install libncurses-dev gawk flex bison openssl libssl-dev dkms libelf-dev libudev-dev libpci-dev libiberty-dev autoconf bc llvm cpio qemu-system-x86 xz-utils -y

// for arm64:
apt-get install libncurses-dev gawk flex bison openssl libssl-dev dkms libelf-dev libudev-dev libpci-dev libiberty-dev autoconf bc llvm cpio qemu-system-aarch64 xz-utils -y
```

## Build Kernel
Config the kernel: Let's generate the `.config` file for the default x86_64 architecture.
```
cd  linux-6.3.8
make ARCH=x86_64 defconfig 
// use arm
make ARCH=arm64 defconfig 
```
You can checkout `make help` for more features. 

Compile it!
```
make -j$(nproc)
```

## Build the ramfs
what is ramfs? 

After the kernel booted, it will find the `init` to execute. The init is the first user level program kernel runs(pid1). `init` is a file and it need to store to a file system. The ramfs is the first file system loaded so that kernel knows where to find the `init`. 
```
cd simple_init
gcc --static hello.c -o init     # compile the static linked init, e.g., all the library in packed into init
$ ldd init 
        not a dynamic executable # we can see there isn't any dynamic library needed in this executable
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
`--nographic`: don't pop out the console, instead give the serial console on stdio and stdout.

`-no-reboot`: exit the qemu when the system in here try to reboot the hardware.

`-kernel`: denote where the kernel image is we just built.

`-initrd`: specify the initial RAM disk (initrd) image file. 

`-append`: The qemu why to add the linux kernel argument. You can find more info about this [linux kernel parameters](https://www.kernel.org/doc/Documentation/admin-guide/kernel-parameters.txt).

ARM:
```
qemu-system-aarch64 \
-M virt \
-cpu cortex-a53 \
--nographic \
-kernel ./linux-4.19.287/arch/arm64/boot/Image \
-initrd simple_init/root.cpio.gz \
-append "panic=1"
```

Now you should see below as the kernel successfully booted.
```
.
.
.
[    1.748783] kworker/u2:0 (44) used greatest stack depth: 14792 bytes left
[    1.756581] Loaded X.509 cert 'sforshee: 00b28ddf47aef9cea7'
[    1.757809] platform regulatory.0: Direct firmware load for regulatory.db failed with error -2
[    1.758185] cfg80211: failed to load regulatory.db
[    1.759176] ALSA device list:
[    1.759403]   No soundcards found.
[    1.792939] Freeing unused kernel image (initmem) memory: 2552K
[    1.793451] Write protecting the kernel read-only data: 26624k
[    1.795453] Freeing unused kernel image (rodata/data gap) memory: 1824K
[    1.936691] x86/mm: Checked W+X mappings: passed, no W+X pages found.
[    1.938074] Run /init as init process
hello kernel!!!!
```

## Side Note: 
- Press Ctrl-a-x to exit the qemu.
- Download the kernel from https://kernel.org/ for the latest stable version.