#!/bin/bash

/home/cloudmanager/mqttclient/mqttcli pub --conf /home/cloudmanager/mqttclient/server.json -t "cs8674/InstallStatus" -m "Installation started...."

wget http://192.168.1.42/Shell_file.txt
Hypervisor=`cat Shell_file.txt  | grep hyp_name -m 1 | grep -Po 'hyp_name=\K[^:]+'`     
Device_ID=`fdisk -l | grep Disk -m 1 | grep -Po 'Disk \K[^:]+'`

/home/cloudmanager/mqttclient/mqttcli pub --conf /home/cloudmanager/mqttclient/server.json -t "cs8674/InstallStatus" -m "$Hypervisor hypervisor was selected by user"
/home/cloudmanager/mqttclient/mqttcli pub --conf /home/cloudmanager/mqttclient/server.json -t "cs8674/InstallStatus" -m "The device id selected by user is $Device_ID"


# Check if the host has enough disk space
/home/cloudmanager/mqttclient/mqttcli pub --conf /home/cloudmanager/mqttclient/server.json -t "cs8674/InstallStatus" -m "Checking if the host has enough disk space"
	 
# Partition the disk according to value of Hypervisor
if [ "$Hypervisor" = 'XENSERVER' ]
	then

	# This creates a new GPT partition table and creates 3 partitions
	# 1st and 2nd partitions are 4GB and 3rd is an lvm partition which extends to the end of the disk
	

	/home/cloudmanager/mqttclient/mqttcli pub --conf /home/cloudmanager/mqttclient/server.json -t "cs8674/InstallStatus" -m "Creating partitions with fdisk... "

        fdisk $Device_ID < fdisk_xen.input

	/home/cloudmanager/mqttclient/mqttcli pub --conf /home/cloudmanager/mqttclient/server.json -t "cs8674/InstallStatus" -m "Done!" 
	


	# Format the first partition using ext3
	
	/home/cloudmanager/mqttclient/mqttcli pub --conf /home/cloudmanager/mqttclient/server.json -t "cs8674/InstallStatus" -m "Formatting partition with ext3..." 
	
	mkfs.ext3 ${Device_ID}1 < mkfs_xen.input


	/home/cloudmanager/mqttclient/mqttcli pub --conf /home/cloudmanager/mqttclient/server.json -t "cs8674/InstallStatus" -m "Done!"


	# Parted is used to set flags on the partitions
	# Flags for 1st partition -> legcy_boot, msftdata
	# Flags for 2nd partition -> msftdata
	# Flags for 3rd partition -> lvm

	/home/cloudmanager/mqttclient/mqttcli pub --conf /home/cloudmanager/mqttclient/server.json -t "cs8674/InstallStatus" -m "Setting appropariate flags on partitions..."

	parted $Device_ID < parted_xen.input

	/home/cloudmanager/mqttclient/mqttcli pub --conf /home/cloudmanager/mqttclient/server.json -t "cs8674/InstallStatus" -m "Done!"

	# This fetches the XenServer cloned image using ssh from the management server and restores it to the 1st partition
	# using dd
	

	/home/cloudmanager/mqttclient/mqttcli pub --conf /home/cloudmanager/mqttclient/server.json -t "cs8674/InstallStatus" -m "Fetching xenserver images and writing to disk...."	
	
	sshpass -p 'san28ket' ssh -o StrictHostKeyChecking=no cloudmanager@192.168.1.42 "dd if=/home/cloudmanager/xen.iso" | dd of=${Device_ID}1 bs=10M

	/home/cloudmanager/mqttclient/mqttcli pub --conf /home/cloudmanager/mqttclient/server.json -t "cs8674/InstallStatus" -m "Done!"

	

	# This installs the MBR on the device
	
	/home/cloudmanager/mqttclient/mqttcli pub --conf /home/cloudmanager/mqttclient/server.json -t "cs8674/InstallStatus" -m "Installing MBR...."

	dd bs=440 conv=notrunc count=1 if=/usr/lib/syslinux/mbr/gptmbr.bin of=$Device_ID
	
	/home/cloudmanager/mqttclient/mqttcli pub --conf /home/cloudmanager/mqttclient/server.json -t "cs8674/InstallStatus" -m "Done!"


elif [ "$Hypervisor" = 'KVM' ] || [ "$Hypervisor" = 'KVM-CLOUDSTACK' ]
	then

	# This creates a new DOS partition table and creates 1 partition of 6GB
	
	/home/cloudmanager/mqttclient/mqttcli pub --conf /home/cloudmanager/mqttclient/server.json -t "cs8674/InstallStatus" -m "Creating partitions with fdisk...."	

	fdisk $Device_ID < fdisk_kvm.input

	/home/cloudmanager/mqttclient/mqttcli pub --conf /home/cloudmanager/mqttclient/server.json -t "cs8674/InstallStatus" -m "Done!"
	
	# This formats the 1st partition using ext4
	
	/home/cloudmanager/mqttclient/mqttcli pub --conf /home/cloudmanager/mqttclient/server.json -t "cs8674/InstallStatus" -m "Formatting the parition to ext4...."	

	mkfs.ext4 ${Device_ID}1 < mkfs_kvm.input

	/home/cloudmanager/mqttclient/mqttcli pub --conf /home/cloudmanager/mqttclient/server.json -t "cs8674/InstallStatus" -m "Done!"

	# This block of code fetches the kvm or kvm with cloudstack cloned images from the manegenment server and
	# restores them to the 1st partition using dd
	

	/home/cloudmanager/mqttclient/mqttcli pub --conf /home/cloudmanager/mqttclient/server.json -t "cs8674/InstallStatus" -m "Fetching KVM image from server and writing to disk...."

	if [ "$Hypervisor" = 'KVM' ]
		then
		sshpass -p 'san28ket' ssh -o StrictHostKeyChecking=no cloudmanager@192.168.1.42 "dd if=/home/cloudmanager/ubuntu-kvm.iso" | dd of=${Device_ID}1 bs=10M
	elif [ "$Hypervisor" = 'KVM-CLOUDSTACK' ]
		then
		sshpass -p 'san28ket' ssh -o StrictHostKeyChecking=no cloudmanager@192.168.1.42 "dd if=/home/cloudmanager/ubuntu-kvm-cloudstack.iso" | dd of=${Device_ID}1 bs=10M
	fi

	/home/cloudmanager/mqttclient/mqttcli pub --conf /home/cloudmanager/mqttclient/server.json -t "cs8674/InstallStatus" -m "Done!" 
	
	# This deletes the 1st partition and creates a new one of 100GB
	# It then creates a swap partition of 5GB

	/home/cloudmanager/mqttclient/mqttcli pub --conf /home/cloudmanager/mqttclient/server.json -t "cs8674/InstallStatus" -m "Paritioning disks with fdisk..."

	fdisk $Device_ID < fdisk_kvm_extend.input


	/home/cloudmanager/mqttclient/mqttcli pub --conf /home/cloudmanager/mqttclient/server.json -t "cs8674/InstallStatus" -m "Done!"

	

	# This sets the boot flag on the first partition

	/home/cloudmanager/mqttclient/mqttcli pub --conf /home/cloudmanager/mqttclient/server.json -t "cs8674/InstallStatus" -m "Setting appropariate flags on partitions.."

	parted $Device_ID < parted_kvm.input

	/home/cloudmanager/mqttclient/mqttcli pub --conf /home/cloudmanager/mqttclient/server.json -t "cs8674/InstallStatus" -m "Done!"
	

	# Checks the first partition


	/home/cloudmanager/mqttclient/mqttcli pub --conf /home/cloudmanager/mqttclient/server.json -t "cs8674/InstallStatus" -m "Checking the parition for resize operation...."	
	
	e2fsck -f ${Device_ID}1

	/home/cloudmanager/mqttclient/mqttcli pub --conf /home/cloudmanager/mqttclient/server.json -t "cs8674/InstallStatus" -m "Done!"



	# Resizes the 1st partition to 100 GB so the dd restored clone of 6 GB can use all of the 100 GB
	
	/home/cloudmanager/mqttclient/mqttcli pub --conf /home/cloudmanager/mqttclient/server.json -t "cs8674/InstallStatus" -m "Resizing the partition...."	
	
	resize2fs /dev/sda1

	/home/cloudmanager/mqttclient/mqttcli pub --conf /home/cloudmanager/mqttclient/server.json -t "cs8674/InstallStatus" -m "Done!"


	# Install the MBR


	/home/cloudmanager/mqttclient/mqttcli pub --conf /home/cloudmanager/mqttclient/server.json -t "cs8674/InstallStatus" -m "Installing the MBR....."	

	sshpass -p 'san28ket' ssh -o StrictHostKeyChecking=no cloudmanager@192.168.1.42 "dd if=/home/cloudmanager/ubuntu-kvm-mbr.iso" | dd of=$Device_ID bs=512 count=1

	/home/cloudmanager/mqttclient/mqttcli pub --conf /home/cloudmanager/mqttclient/server.json -t "cs8674/InstallStatus" -m "Done!"
	
	# Make partition number 5 as swap and store its UUID in the UUID variable
	

	/home/cloudmanager/mqttclient/mqttcli pub --conf /home/cloudmanager/mqttclient/server.json -t "cs8674/InstallStatus" -m "Setting swap and updating fstab entries..."

	UUID=`mkswap ${Device_ID}5 | grep UUID= | cut -d '=' -f2` 

	mkdir /mnt/device

	# We will now mount the first partition to update the swap UUID in fstab
	mount ${Device_ID}1 /mnt/device

	# Update UUID of swap partition
	sed -i -e ':a;N;$!ba;s/UUID=[A-Fa-f0-9-]*/UUID=$UUID/3' /mnt/device/etc/fstab

	# Unmount the 1st partition
	umount ${Device_ID}1
fi

/home/cloudmanager/mqttclient/mqttcli pub --conf /home/cloudmanager/mqttclient/server.json -t "cs8674/InstallStatus" -m "Done!"
 
/home/cloudmanager/mqttclient/mqttcli pub --conf /home/cloudmanager/mqttclient/server.json -t "cs8674/InstallStatus" -m "Congrats ! The process was completed successfully.The system will now reboot."


echo "Rebooting in"
sleep 1
echo "3"
sleep 1
echo "2"
sleep 1
echo "1"

reboot
 
