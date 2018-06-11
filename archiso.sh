#Author: Daniel Hawthorne

#Distro: Arch Linux | Release: 2018.05.01 | Kernel: 4.16.5
#Media: SanDisk Cruzer Blade CZ50 8 GB USB 2.0
#Config: ArchISO x86_64

#Description: This document contains the steps used to modify the live
  #ArchISO to include the packages and scripts necessary for use in this
  #research.

#References:
  #https://wiki.archlinux.org/index.php/Archiso
  #https://wiki.archlinux.org/index.php/Remastering_the_Install_ISO

#Note: These instructions are from an Arch Linux-based Distro.  They are
  #written as a bash script, but are not tested in that form.  Rather they
  #are designed to be executed sequentially.

#Step 1: Confirm required packages synced
  sudo pacman -S --needed cdrtools squashfs-tools arch-install-scripts \
    libisoburn syslinux

#Step 2: Get the ISO
  #Download and verify the ISO from you choice of mirrors at:
  #https://archlinux.org/download/
  #will move to below when a new verrsion is released:
  #https://archive.archlinux.org/iso/

#Step 3: Mount the ISO, copy ISO contents, unmount the ISO, clean up mnt

  sudo mkdir /mnt/archiso
  sudo mount -t iso9660 -o loop \
    ~/Downloads/archlinux-2018.05.01-x86_64.iso /mnt/archiso
  #make sure ~/customiso does not already exist:
    sudo rm -r ~/customiso
  sudo cp -a /mnt/archiso ~/customiso
  sudo umount /mnt/archiso
  sudo rm -r /mnt/archiso

#Step 4: Unpack the file system
  cd ~/customiso/arch/x86_64
  sudo unsquashfs airootfs.sfs

#Step 5: Move the benchmark script to the target filesystem
  sudo cp ~/Downloads/bench.sh \
    ~/customiso/arch/x86_64/squashfs-root/etc/profile.d

#Step 6: Modify the custom ISO as root
  #enter ISO filesystem as root
  sudo arch-chroot squashfs-root /bin/bash

  #update the permissions of the benchmark script
  chmod +x /etc/profile.d/bench.sh

  #add a root password so pkgbuild will work
  passwd root #root

  #prepare the package manager
  pacman-key --init
  pacman-key --populate archlinux

  #add repo for yaourt
  echo -e "\n[archlinuxfr]\nSigLevel = Never\n" >> /etc/pacman.conf
  echo -e "Server = http://repo.archlinux.fr/\$arch" >> /etc/pacman.conf

  #sync package database
  pacman -Sy

  #may need to remove checkspace if error when getting packages
  nano /etc/pacman.conf
  #comment out CheckSpace

  #get packages
  pacman -S dmidecode binutils yaourt fakeroot make patch
  sudo -u nobody yaourt -S hpl #follow prompts to build/install

  #update the package list
  LANG=C pacman -Sl | \
    awk '/\[installed\]$/ {print $1 "/" $2 "-" $3}' > /pkglist.txt

  #clean package database
  pacman -Scc

  #clean bash history and exit chroot
  cat /dev/null > ~/.bash_history && history -c && exit

#Step 7: Create New filesystem
  #move package list
  sudo mv squashfs-root/pkglist.txt ~/customiso/arch/pkglist.x86_64.txt

  #remove old, make new, clean up
  sudo rm airootfs.sfs
  sudo mksquashfs squashfs-root/ airootfs.sfs
  sudo rm -r squashfs-root/
  sudo sha512sum airootfs.sfs | sudo tee airootfs.sha512

#Step 8: Make the new ISO
  cd ~
  #get iso label
  iso_label=$(isoinfo -i ~/Downloads/archlinux-2018.05.01-x86_64.iso -d \
    | grep 'Volume id:' | cut -d' ' -f3)

  #make the image (USB ready)
  sudo xorriso -as mkisofs \
    -iso-level 3 \
    -full-iso9660-filenames \
    -volid "${iso_label}" \
    -eltorito-boot /isolinux/isolinux.bin \
    -eltorito-catalog /isolinux/boot.cat \
    -no-emul-boot -boot-load-size 4 -boot-info-table \
    -isohybrid-mbr ~/customiso/isolinux/isohdpfx.bin \
    -output ~/arch-custom.iso \
    ~/customiso

  #test with virtual machine, if desired

#Step 9: Write the custom ISO (repeat as necessary):
  sudo fdisk -l #determine usb disk label
  sudo dd bs=4M if=~/arch-custom.iso of=/dev/sdb status=progress
