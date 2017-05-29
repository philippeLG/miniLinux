# Build Linux
from https://github.com/MichielDerhaeg/build-linux

https://cdn.kernel.org/pub/linux/kernel/v4.x/linux-4.10.14.tar.xz
https://www.busybox.net/downloads/busybox-1.26.2.tar.bz2


# preparation de l'image

dd if=/dev/zero of=image bs=1M count=100
fdisk image
n
p
1
w
sudo losetup -P -f --show image
sudo mkfs.ext4 /dev/loop0p1
mkdir image_root
sudo mount /dev/loop0p1 image_root
cd image_root/

# preparation linux   
mkdir -p usr/{sbin,bin} bin sbin boot
mkdir -p {dev,etc,home,lib}
mkdir -p {mnt,opt,proc,srv,sys}
mkdir -p var/{lib,lock,log,run,spool}
install -d -m 0750 root
install -d -m 1777 tmp
mkdir -p usr/{include,lib,share,src}

# copie linux kernel et busybox
cp ../busybox usr/bin/busybox
cp ../linux-4.10.14/arch/x86_64/boot/bzImage boot/bzImage
for util in $(./usr/bin/busybox --list-full); do ln -s /usr/bin/busybox $util; done

cp ../filesystem/{passwd,shadow,group,issue,profile,locale.sh,hosts,fstab} etc
install -Dm755 ../filesystem/simple.script usr/share/udhcpc/default.script
install -Dm644 ../filesystem/fr-latin1.bmap usr/share/keymaps/fr-latin1.bmap

# installation et config grub
grub-install --modules=part_msdos --target=i386-pc --boot-directory="$PWD/boot" /dev/loop0

fdisk -l ../image | grep "Disk identifier" 
Disk identifier: 0x807c948e

vi boot/grub/grub.cfg 
linux /boot/bzImage quiet init=/bin/sh root=PARTUUID=807c948e-01
boot

# test 
umount image_root
qemu-system-x86_64 -enable-kvm image

# passage en azerty 
loadkmap < /usr/share/keymaps/fr-latin1.bmap

create /etc/init.d/startup 
chmod +x startup
remove init=/bin/sh from grub.cfg
create /etc/inittab

# syslogd 
mkdir -p etc/init.d/syslogd
cp ../filesystem/syslogd.run etc/init.d/syslogd/run
chmod +x etc/init.d/syslogd/run
mkdir -p etc/rc.d
ln -s etc/init.d/syslogd etc/rc.d
cp ../filesystem/syslog.conf etc/.
mkdir -p etc/init.d/klogd
cp ../filesystem/klogd.run etc/init.d/klogd/run
chmod +x etc/init.d/klogd/run 
ln -s etc/init.d/klogd etc/rc.d
mkdir -p etc/init.d/udhcpc
cp ../filesystem/udhcpc.run etc/init.d/udhcpc/run
chmod +x etc/init.d/udhcpc/run 
ln -s etc/init.d/udhcpc etc/rc.d

