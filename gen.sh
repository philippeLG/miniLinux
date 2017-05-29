#!/bin/bash

if [[ $(id -u) -ne 0 ]]; then
  echo "run as root"
  exit 1
fi

# preparation de l'image
image=image

rm $image

dd if=/dev/zero of=$image bs=1M count=100

echo -e "o\nn\n\n\n\n\nw\n" | fdisk $image
loopdevice="$(losetup -P --show -f $image)"
looppart=${loopdevice}p1
mkfs.ext4 $looppart

mkdir -p image_root
mount $looppart image_root
cd image_root/

# preparation linux   
mkdir -p usr/{sbin,bin} bin sbin boot
mkdir -p {dev,etc,home,lib}
mkdir -p {mnt,opt,proc,srv,sys}
mkdir -p var/{lib,lock,log,run,spool}
install -d -m555 proc
install -d -m555 sys
install -d -m 0750 root
install -d -m 1777 tmp
mkdir -p usr/{include,lib,share,src}

# copie linux kernel et busybox
cp ../busybox usr/bin/busybox
cp ../bzImage boot/bzImage
for util in $(./usr/bin/busybox --list-full); do ln -s /usr/bin/busybox $util; done

# copy etc 
tar -xf ../filesystem/etc.tar
# 
install -Dm755 ../filesystem/simple.script usr/share/udhcpc/default.script
install -Dm644 ../filesystem/fr-latin1.bmap usr/share/keymaps/fr-latin1.bmap

# installation et config grub
grub-install --modules=part_msdos --target=i386-pc --boot-directory="$PWD/boot" $loopdevice
cd ..
uuid=$(fdisk -l $image | grep "Disk identifier" | cut -d " " -f 3 | cut --complement -c 1,2)-01
echo -e "linux /boot/bzImage quiet root=PARTUUID=$uuid\nboot" > "image_root/boot/grub/grub.cfg"

# demontage 
umount image_root
sync
losetup -d $loopdevice
rm -rf image_root
