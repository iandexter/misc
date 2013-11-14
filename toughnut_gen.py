#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Generate ``tough nut'' passwords and passphrases by padding and using
permutations of common words, then calculate the bit entropy for each generated
password.

Usage: python toughnut_gen.py n file1 file2 ... filen

       n     Number of passwords to generate (default: 10)
       file  List of common words to use
             (default: internal seed list)
"""

import random
import string
import sys
from math import log

### Seed list for passphrases and common words
seed = [
'My grace is sufficient for you, for my power is made perfect in weakness.',
'A generous man will prosper; he who refreshes others will himself be \
refreshed.',
'password',
'random',
]

### Variables for password generation
k = 3  # Random range for padding
tmin = 12 # Minimum for random range of password length
tmax = 32 # Maximum for random range of password length

### Functions

def readfiles(filenames):
    """ Provide seed list for generation """
    seed_list = []
    if len(filenames) > 0:
        for f in filenames:
            lines = open(f, "r").readlines()
            for l in lines:
                seed_list.extend(l.split())
    else:
        seed_list.extend(seed)
    return seed_list

def tolower(c): return c.lower()
def toupper(c): return c.upper()

def camel(word = None):
    """ Randomly use upper- or lower-case """
    o = []
    for c in word:
        random_func = random.choice([tolower, toupper])
        o.append(random_func(c))
    return ''.join(o)

def obfuscate(word = None):
    """ Transform characters individually """
    trans_table = {
        'a': 'Aa@2', 'e': 'Ee3',
        'g': 'Gg69', 'i': 'Ii1!',
        'o': 'Oo0', 's': 'Ss$45',
        't': 'Tt7'
    }
    o = []
    for c in word:
        if c.lower() in trans_table:
            t = trans_table[c.lower()]
            o.append(random.choice(t))
        else:
            o.append(camel(c))
    return ''.join(o)

def pad(r = False, n = 0, s = None):
    """ Add padding """
    p = []
    if r:
        rng = random.randrange(n)
    else:
        rng = n
    for i in range(rng):
        p.append(random.choice(s))
    return ''.join(p)

def generate(str = None, k = 0, tmin = 0, tmax = 0):
    """ Pad words with random characters """
    n = []
    t = random.randint(tmin,tmax)
    for s in str.split():
        n.append(pad(True, k, string.punctuation))
        random_func = random.choice([obfuscate, camel])
        n.append(random_func(s))
    n.append(pad(True, k, string.ascii_letters))
    if len(''.join(n)) < t:
        d = t - len(''.join(n))
        n.append(pad(False, d, string.punctuation + string.digits))
    return ''.join(n)

def xkcd_gen(word_list = []):
    """ Generate passphrase based on xkcd/936 """
    random.shuffle(word_list)
    return ' '.join(w.strip() for w in word_list[:random.randrange(3,5)])

def entropy(str = None, word_list = []):
    N = 0
    if str.isalpha():
        N += len(string.ascii_lowercase)
    elif str.isalnum():
        N += len(string.ascii_lowercase + string.digits)
    else:
        N += len(string.ascii_letters + string.digits + string.punctuation)
    return len(str) * log(N,2)

### Main

if __name__ == '__main__':

    if len(sys.argv) > 1:
        r = int(sys.argv[1])
    else:
        r = 10

    seed_files = sys.argv[2:]
    seed_list = readfiles(seed_files)


    password_list = []
    for i in range(int(r/3)):
        password_list.append(random.choice(seed_list))
    for i in range(int(r/3)):
        s = random.choice(seed_list)
        if len(s) < tmax:
            d = random.randint(tmin,tmax)
            s += pad(False, d, string.digits)
        password_list.append(s)
    for i in range(int(r/3)):
        s = generate(random.choice(seed_list), k, tmin, tmax)
        password_list.append(s)
    for i in range(int(r/3)):
        password_list.append(xkcd_gen(seed_list))

    max_width = len(max(password_list, key=len))
    for p in password_list:
        print "%-*s %4d %8.2f" % (max_width, p, len(p), entropy(p, seed_list))
