#!/usr/bin/env python26
# -*- coding: utf-8 -*-

"""
Roll custom ISO with Kickstart. Requires network directives in the KS file.
"""

import os
import distutils.dir_util
import distutils.file_util
import re

bootiso = '/path/to/boot/iso'
customiso = '/path/to/custom/iso'
bootmnt = '/mnt/boot'
custommnt = '/mnt/custom'
isolabel = 'RHEL VER ARCH Custom ISO'
isolinux = custommnt + '/isolinux/isolinux.cfg'
ks = '/path/to/kickstart/file'

cmd = "grep -q ^network %s" % ks
if os.system(cmd):
    os._exit(os.EX_DATAERR)

if not os.path.exists(bootmnt):
    os.makedirs(bootmnt)

cmd = "mount -o loop %s %s" % (bootiso, bootmnt)
os.system(cmd)
print "Mounted %s" % bootiso

distutils.dir_util.copy_tree(bootmnt, custommnt, preserve_mode=1)
distutils.file_util.copy_file(ks, "%s/isolinux/ks.cfg" % custommnt)
print "Copied %s" % ks

with open(isolinux, 'r') as cfg:
    lines = cfg.readlines();
with open(isolinux, 'w') as cfg:
    for line in lines:
        cfg.write(re.sub(r'(.*append.*initrd=initrd.img)$', \
        r'\1 ks=cdrom://isolinux/ks.cfg ksdevice=link', line))

cmd = "cd %s && mkisofs -q -o %s -b isolinux/isolinux.bin \
       -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 \ 
       -boot-info-table -J -R -V \"%s\" ." % (custommnt, customiso, isolabel)
os.system(cmd)
cmd="sha256sum %s > %s.sha256" % (customiso, os.path.splitext(customiso)[0])
os.system(cmd)
print "Created ISO:"
cmd = "cat %s.sha256" % os.path.splitext(customiso)[0]
os.system(cmd)

cmd = "umount %s" % bootiso
os.system(cmd)
distutils.dir_util.remove_tree(custommnt)
distutils.dir_util.remove_tree(bootmnt)
