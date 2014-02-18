#!/usr/bin/env python26
# -*- coding: utf-8 -*-

"""
Get package versions from Ansible-managed hosts.
"""

import ansible
import ansible.runner
import sys

def dict_packages(rpm_output):
    package_list = rpm_output
    package_dict = dict(i.split('=') for i in package_list.split('\n'))
    return package_dict

if len(sys.argv) < 2:
    print 'Get package versions from Ansible-managed hosts.'
    print "\nUsage: %s targethost_or_pattern" % sys.argv[0]
    sys.exit(1)
hostpattern = sys.argv[1]

runner = ansible.runner.Runner(
    module_name = 'command',
    module_args = 'rpm -qa --qf "%{n}=%{v}-%{r}\n"',
    pattern = hostpattern,
    forks = 10
)
hosts = runner.run()

if len(hosts['contacted']) == 1:
    print >> sys.stderr, 'Only one host is defined -- nothing to show'
    sys.exit(1)

all_packages = {}

for h in hosts['contacted']:
    host_packages = dict_packages(hosts['contacted'][h]['stdout'])
    for p in host_packages:
        if p not in all_packages:
            all_packages[p] = {}
        all_packages[p][h] = host_packages[p]


output = 'Package,' + ','.join(hosts['contacted']) + "\n"
for p in all_packages:
    rowlist = []
    rowlist.append(p)
    for h in hosts['contacted']:
        if h in all_packages[p]:
            rowlist.append(all_packages[p][h])
        else:
            rowlist.append('-')
    output += ','.join(rowlist) + "\n";
print output
