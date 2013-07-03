#!/bin/sh
#
# Nagios plugin for checking expired passwords.

[[ $(id -u) -ne 0 ]] && echo "Must be ran as root. Exiting." && exit 1

THIS_HOST=$(hostname -f)
TODAY=$(($(date +%s)/60/60/24))

UID_LIMIT=1000
PASS_MAX_DAYS=90
PASS_WARN_AGE=10

EXCEPTIONS="nobody"

NAGIOS_STATUS=0
REPORT="Accounts in ${THIS_HOST}:\n"
EXPIRING=0
EXPIRED=0

### Get only non-system accounts
for u in $(awk -F: -v x=${UID_LIMIT} '( $3 >= x ) { print $3,$1}' /etc/passwd | sort -n | awk '{print $2}' | grep -v "${EXCEPTIONS}") ; do
    passwd_crypt=$(awk -F: -v x=${u} '( $1 == x ) {print $2}' /etc/shadow)
    last_changed=$(awk -F: -v x=${u} '( $1 == x ) {print $3}' /etc/shadow)
    must_change=$(awk -F: -v x=${u} '( $1 == x ) {print $5}' /etc/shadow)
    passwd_age=$((${PASS_MAX_DAYS}-$((${TODAY}-${last_changed}))))

    if [[ ${passwd_crypt} =~ "^\!.*$" ]] ; then
        ### Locked -- nothing to do
        REPORT="${REPORT}\n${u}\t\tLocked"
    elif [[ ${must_change} -eq 99999 ]] ; then
        ### Enforce password expiration policy
        ### /usr/bin/passwd -x ${PASS_MAX_DAYS} -w ${PASS_WARN_AGE} ${u} &>/dev/null
        ### /usr/bin/passwd -e ${u} &>/dev/null
        REPORT="${REPORT}\n${u}\t\tEnforced"
    elif [[ ${passwd_age} -ge 0 && ${passwd_age} -le ${PASS_WARN_AGE} ]] ; then
        ### About to expire
        REPORT="${REPORT}\n${u}\t\tExpiring (${passwd_age})"
        (( EXPIRING +=1 ))
    elif [[ ${passwd_age} -lt 0 && ${passwd_age} -gt -90 ]] ; then
        ### Already expired
        REPORT="${REPORT}\n${u}\t\tExpired"
        (( EXPIRED +=1 ))
    elif [[ ${passwd_age} -lt -90 ]] ; then
        ### Expired for more than 90 days
        ### /usr/bin/passwd -e ${u} &>/dev/null
        REPORT="${REPORT}\n${u}\t\tExpired"
        (( EXPIRED +=1 ))
    else
        ### Still valid -- nothing to do
        REPORT="${REPORT}\n${u}\t\tValid"
    fi
done

REPORT="${REPORT}\n\nEXPIRING:\t${EXPIRING}\nEXPIRED:\t${EXPIRED}"
[[ $1 = "-v" ]] && echo -e ${REPORT} && exit 3

if [[ ${EXPIRING} -gt 0 && ${EXPIRED} -eq 0 ]] ; then
    [[ ${EXPIRING} -gt 1 ]] && S='s' || S=''
    echo "WARNING: ${EXPIRING} expiring account${S} found. Rerun with '-v' to print a report." && NAGIOS_STATUS=1
elif [[ ${EXPIRED} -gt 0 ]] ; then
    [[ ${EXPIRED} -gt 1 ]] && S='s' || S=''
    echo "CRITICAL: ${EXPIRED} expired account${S} found. Rerun with '-v' to print a report." && NAGIOS_STATUS=2
else
    echo "OK: No expired accounts." && NAGIOS_STATUS=0
fi

exit ${NAGIOS_STATUS}
