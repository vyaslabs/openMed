export WORK=~/work
export CD=~/cd
export FORMAT=squashfs
export FS_DIR=casper

#Copy the Hindawi customizations
cd ~/build-sushurata-cd
sudo chmod 666 *
sudo cp -vp ~/build-sushurata-cd/sushurata-logo-plymouth.png /usr/share/plymouth/themes/ubuntu-logo/ubuntu-logo16.png
sudo cp -vp ~/build-sushurata-cd/sushurata-logo-plymouth.png /usr/share/plymouth/themes/ubuntu-logo/ubuntu-logo.png
sudo cp -vp ~/build-sushurata-cd/sushurata-logo-plymouth.png /usr/share/plymouth/ubuntu-logo.png
sudo cp -vp ~/build-sushurata-cd/p*.png /usr/share/plymouth/themes/ubuntu-logo/
sudo cp -vp ~/build-sushurata-cd/ubuntu-logo.script /usr/share/plymouth/themes/ubuntu-logo/
sudo cp -vp ~/build-sushurata-cd/sushurata-splash.jpg /usr/share/backgrounds/warty-final-ubuntu.jpg
sudo cp -vp ~/build-sushurata-cd/sushurata-splash.png /usr/share/backgrounds/warty-final-ubuntu.png


sudo mkdir -p ${CD}/{${FS_DIR},boot/grub} ${WORK}/rootfs
sudo apt-get update
sudo apt-get install grub2 xorriso squashfs-tools qemu
#moved cd tools install outside of chroot to speed things up
sudo apt-get install -y gparted testdisk wipe partimage xfsprogs reiserfsprogs jfsutils ntfs-3g dosfstools mtools

sudo rsync -av --one-file-system           \
    --exclude=/proc/*                      \
    --exclude=/dev/*                       \
    --exclude=/sys/*                       \
    --exclude=/tmp/*                       \
    --exclude=/home/*                      \
    --exclude=/lost+found                  \
    --exclude=/var/tmp/*                   \
    --exclude=/boot/grub/*                 \
    --exclude=/root/*                      \
    --exclude=/var/mail/*                  \
    --exclude=/var/spool/*                 \
    --exclude=/media/*                     \
    --exclude=/etc/fstab                   \
    --exclude=/etc/mtab                    \
    --exclude=/etc/hosts                   \
    --exclude=/etc/timezone                \
    --exclude=/etc/shadow*                 \
    --exclude=/etc/gshadow*                \
    --exclude=/etc/X11/xorg.conf*          \
    --exclude=/etc/gdm/custom.conf         \
    --exclude=/etc/lightdm/lightdm.conf    \
    --exclude=${WORK}/rootfs               \
    / ${WORK}/rootfs

sudo cp -av /boot/* ${WORK}/rootfs/boot

CONFIG='.config .bashrc'
cd ~
for i in $CONFIG
do 
    sudo cp -rpv --parents $i ${WORK}/rootfs/etc/skel
done

sudo mount  --bind /dev/ ${WORK}/rootfs/dev
sudo mount -t proc proc ${WORK}/rootfs/proc
sudo mount -t sysfs sysfs ${WORK}/rootfs/sys
sudo mount -o bind /run ${WORK}/rootfs/run

#Copy the script for actions under chroot
sudo cp build-sushurata-cd/build-sushurata-cd-under-chroot.sh ${WORK}/rootfs/tmp/
sudo chroot ${WORK}/rootfs /bin/bash -c "source /tmp/build-sushurata-cd-under-chroot.sh"

#Copy the sushurata artwork to cd folder
sudo cp -vp build-sushurata-cd/*.png ${CD}/${FS_DIR}/
sudo cp -vp /usr/share/grub/unicode.pf2 ${CD}/${FS_DIR}/unicode.pf2

export kversion=`cd ${WORK}/rootfs/boot && ls -1 vmlinuz-* | tail -1 | sed 's@vmlinuz-@@'`
sudo cp -vp ${WORK}/rootfs/boot/vmlinuz-${kversion} ${CD}/${FS_DIR}/vmlinuz
sudo cp -vp ${WORK}/rootfs/boot/initrd.img-${kversion} ${CD}/${FS_DIR}/initrd.img
sudo cp -vp ${WORK}/rootfs/boot/memtest86+.bin ${CD}/boot

sudo chroot ${WORK}/rootfs dpkg-query -W --showformat='${Package} ${Version}\n' | sudo tee ${CD}/${FS_DIR}/filesystem.manifest
sudo cp -v ${CD}/${FS_DIR}/filesystem.manifest{,-desktop}

REMOVE='ubiquity casper user-setup os-prober libdebian-installer4'
for i in $REMOVE
do
    sudo sed -i "/${i}/d" ${CD}/${FS_DIR}/filesystem.manifest-desktop
done

sudo umount ${WORK}/rootfs/proc
sudo umount ${WORK}/rootfs/sys
sudo umount ${WORK}/rootfs/dev

sudo mksquashfs ${WORK}/rootfs ${CD}/${FS_DIR}/filesystem.${FORMAT} -noappend

echo -n $(sudo du -s --block-size=1 ${WORK}/rootfs | tail -1 | awk '{print $1}') | sudo tee ${CD}/${FS_DIR}/filesystem.size

find ${CD} -type f -print0 | xargs -0 md5sum | sed "s@${CD}@.@" | grep -v md5sum.txt | sudo tee -a ${CD}/md5sum.txt

#sudo gedit ${CD}/boot/grub/grub.cfg
sudo cp /home/dcch/build-sushurata-cd/grub.cfg ${CD}/boot/grub/grub.cfg

sudo grub-mkrescue -o ~/sushurata-live-cd.iso ${CD}

ls -l /home/dcch/sushurata-live-cd.iso

#sudo rm -rf ${WORK} ${CD}
