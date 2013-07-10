#!/usr/bin/env python26
# -*- coding: utf-8 -*-

"""
Print LDAP schema (including objectClasses and attributeTypes) in LDIF.
"""

import ldap
import ldif
import sys

host = 'ldap_host'
port = 389
uri = "ldap://%s:%d" % (host, port)

dn = 'cn=dirman,ou=company,ou=com'
pw = 'password'

def bind():
    """Initialize and bind to server."""
    try:
        conn.simple_bind_s(dn, pw)
    except ldap.LDAPError, e:
        print e
        sys.exit(-1)

def search(base_dn, scope, filter, attrs):
    """Search and output to LDIF."""
    try:
        results = conn.search_s(base_dn, scope, filter, attrs)
        ldif_output = ldif.LDIFWriter(sys.stdout)
        for dn, entry in results:
            ldif_output.unparse(dn, entry)
    except ldap.LDAPError, e:
        print e
        sys.exit(-1)

base_dn = 'cn=Subschema'
scope = ldap.SCOPE_BASE
filter = '(objectclass=subschema)'
attrs = ['objectclasses', 'attributes', '*', '+']

if __name__ == '__main__':
    conn = ldap.initialize(uri)
    bind()
    search(base_dn, scope, filter, attrs)
