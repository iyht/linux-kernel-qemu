
## Run Linux Kernel with Custom init binary
### Docker
Create docker image to run the qemu:
```
make docker-create-image
```

Create create the container and run it:
```
make docker-run-bash
```

Now in side the docker, we do following to have our kernel build and run in the qemu


### Install Deps
env:
```
apt update
apt-get install libncurses-dev gawk flex bison openssl libssl-dev dkms libelf-dev libudev-dev libpci-dev libiberty-dev autoconf bc llvm cpio qemu-system-x86 xz-utils -y

// for arm64:
apt-get install libncurses-dev gawk flex bison openssl libssl-dev dkms libelf-dev libudev-dev libpci-dev libiberty-dev autoconf bc llvm cpio qemu-system-aarch64 xz-utils -y
```

### Build Kernel
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

### Build the ramfs
what is ramfs? 

After the kernel booted, it will find the `init` to execute. The init is the first user level program kernel runs(pid1). `init` is a file and it need to store to a file system. The ramfs is the first file system loaded so that kernel knows where to find the `init`. 
```
cd simple_init
gcc --static hello.c -o init     # compile the static linked init, e.g., all the library in packed into init
$ ldd init 
        not a dynamic executable # we can see there isn't any dynamic library needed in this executable
find . | cpio -o -H newc | gzip > root.cpio.gz
```

### Run in qemu
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

## Run Linux Kernel with Bash
Get the BusyBox from: https://busybox.net/ in the `busybox-1.36.1` directory.

Build the busybox
- `cd busybox-1.36.1`
- Configure the Busybox with the default config `make defconfig`.
- Manually config the `.config` file and set `CONFIG_STATIC=y` so that the binary is statically linked.
- `make -j $(nproc) && make install`, you will find the installed folder in `_install`
```
> ls _install/
bin  linuxrc  sbin  usr
```
- Create a rootfs `initrd`, and copy all the built Busybox folder into `initrd`.
```
mkdir initrd
cd initrd
cp -av ../install/* ./
mkdir -pv {bin,dev,sbin,etc,proc,sys/kernel/debug,usr/{bin,sbin},lib,lib64,mnt/root,root}
```
- `vim init`: We then create a init executable with the following command, make sure to `chmod +x init`
```
#! /bin/sh
echo "Hi, this is init"
mount -t proc none /proc
mount -t sysfs none /sys
mount -t debugfs none /sys/kernel/debug

echo -e "\nBoot took $(cut -d' ' -f1 /proc/uptime) seconds\n"
mknod /dev/ttyS0 c 4 64
setsid sh -c 'exec sh </dev/ttyS0 > /dev/ttyS0 2>&1'
```
- `find . | cpio -o -H newc | gzip > root.cpio.gz`: Pack up the rootfs directory for the kernel to load.
- Start the kernel!
```
qemu-system-x86_64 \
--nographic \
-no-reboot \
-kernel ./linux-6.3.8/arch/x86/boot/bzImage \
-initrd busybox-1.36.1/initrd/root.cpio.gz \
-append "panic=1 console=ttyS0"
```
- We should see the following that we have the bash after booting the Linux Kernel:
```
.
.
.
[    1.695771] cfg80211: failed to load regulatory.db
[    1.696994] ALSA device list:
[    1.697510]   No soundcards found.
[    1.731550] Freeing unused kernel image (initmem) memory: 2576K
[    1.733198] Write protecting the kernel read-only data: 26624k
[    1.735302] Freeing unused kernel image (rodata/data gap) memory: 1920K
[    1.886466] x86/mm: Checked W+X mappings: passed, no W+X pages found.
[    1.887826] Run /init as init process
Hi, this is init

Boot took 1.90 seconds

~ # [    1.985796] tsc: Refined TSC clocksource calibration: 1804.788 MHz
[    1.986769] clocksource: tsc: mask: 0xffffffffffffffff max_cycles: 0x1a03d4aae78, max_idle_ns: 440795229005 ns
[    1.987790] clocksource: Switched to clocksource tsc
[    2.300893] input: ImExPS/2 Generic Explorer Mouse as /devices/platform/i8042/serio1/input/input3

~ # 
~ # 
```





## Side Note: 
- Press Ctrl-a-x to exit the qemu.
- Download the kernel from https://kernel.org/ for the latest stable version.