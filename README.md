# mkTinyRootFs
Create a tiny rootfs directly from your standard desktop config

  Generation d'une version RamOnly 
-----------------------------------

Author: Fulup Ar Foll (fulup@fridu.bzh)
Date:   March 2006

Object: genere une version RIM directement depuis votre
        distribution, aucune recompilation n'est necessaire.

Usage: Generation d'un initramfs
--------------------------------
 - editer  votre fichier config (cf: TargetSample.conf)
 - generer votre initramfs avec "./mkDiskless.sh TargetSample"
 - copier  le TargetSample-initramfs.gz sur votre target

  Nota: le initramfs est basé sur votre kernel courant 'uname -a'
  vous devez donc ajouter votre kernel courrant a votre distribution.

  Une fois booter vous avez un Linux de base avec un clavier francais
  et le reseau (dhcp) qui est operationnel.

Have fun.

Fulup

Network: boot via pxes
---------------------- 
 - configurer votre DHCP && TFTP pour netbooter pxelinux.0
 - configurer pxelinux.cfg/default
   >default 1
   >prompt 5
   >timeout 6
   >label 1
   >  kernel diskless/default-vmlinuz
   >  append initrd=diskless/default-initramfs.gz rw root=/dev/null
 - copier le kernel courrant "/boot/vmlinux" dans "/yourTFTPdir/diskless"
 - copier TargetSample-initramfs.gz dans "/yourTFTPdir/diskless"

 Nota: pour que la target puisse voir le reseau apres le boot, vous devez
 avoir chargé le bon module reseau (e100 dans l'example)


Xen: Le mieux pour les tests
----------------------------
 - installer XEN (pas forcement ce qu'il y a de plus simple !!!)
 - copy du kernel "cp /boot/vmlinuz /var/lib/xen/image/TargetSample-vmlinuz"
 - copy du ramfs  "cp TargetSample-initramfs.gz /var/lib/xen/image/TargetSample-vmlinuz"
 - creation d'un fichier de config VM (i.e. /etc/xen/TargetSample-xen)
   > name     = "xen-rim"
   > memory   = 256
   > kernel   = "/var/lib/xen/images/Fulup-vmlinuz"
   > ramdisk  = "/var/lib/xen/images/Fulup-initramfs.gz"
   > root     = "/dev/null"
   > vif      = [ 'mac=aa:cc:00:00:00:02, bridge=xenbr0' ]
   > dhcp     = "dhcp"
   > hostname = "xen-rim"
 - start de la VM "xm create -c /etc/xen/TargetSample-xen"


Travail a faire !!!
-------------------

# Syslogd
  plante sur creation du socket /dev/log

# DHCP
  -trouve la bonne adresse
  -ne met pas a jour le fichier /etc/resolv.conf
  -a priori le resolv via DNS ne fonctionne pas.
  *** faire un strace -f -o /tmp/strace pour comprendre le PB

# SSH hug !!!
  -ssh  plante (you don't exist)
  -sshd user sshd n'existe pas
  *** mettre un passwd a root et verifier le loggin au niveau du shell
  *** installer "su" pour tester les user

- X pas de config

cf:  http://www.intra2net.com/opensource/diskless-howto/howto.html

Fulup


