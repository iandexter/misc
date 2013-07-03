#!/bin/sh
#
# Perform a sweep on all partitions to check for the following:
#
#   a. World-writable directories with sticky bit set.
#   b. Unauthorized world-writable files.
#   c. SUID/GUID executables.
#   d. Files with not owners.
#   e. Users with no password.
#   f. Legacy + (NIS map inserts) entries.
#   g. UID 0 accounts.

[ $(id -u) -ne 0 ] && echo "Must be ran as root." && exit 1

PART=$(awk '($6 != "0") {print $2}' /etc/fstab | tr '\n' '\ ')

echo "----------------------------------"
echo "Findings (none means clean sweep):"
echo "----------------------------------"
echo ""

displayResults() {
        header="${1}"
        echo "${header}:"
        echo "${sweep}" | tr '\ ' '\n' | sort
        echo ""
}

sweep=$(find ${PART} -xdev -type d \( -perm -0002 -a ! -perm -1000 \) -print 2>/dev/null)
[ -n "${sweep}" ] && displayResults "World-writable directories with sticky bit set" || :

sweep=$(find ${PART} -xdev -type f \( -perm -0002 -a ! -perm -1000 \) -print 2>/dev/null)
[ -n "${sweep}" ] && displayResults "Unauthorized world-writable files" || :

sweep=$(find ${PART} -xdev -type f \( -perm -04000 -a ! -perm -02000 \) -print 2>/dev/null)
[ -n "${sweep}" ] && displayResults "SUID/GUID system executables" || :

sweep=$(find ${PART} -nouser -o -nogroup -print 2>/dev/null)
[ -n "${sweep}" ] && displayResults "Files with no owners" || :

sweep=$(awk -F: '($2 == "") { print $1 }' /etc/shadow)
[ -n "${sweep}" ] && displayResults "Users with no password" || :

sweep=$(grep ^+: /etc/passwd /etc/shadow /etc/group)
[ -n "${sweep}" ] && displayResults "Legacy + (NIS map inserts) entries" || :

sweep=$(awk -F: '($3 == 0) { print $1 }' /etc/passwd)
[ -n "${sweep}" ] && displayResults "UID 0 accounts" || :

exit 0
