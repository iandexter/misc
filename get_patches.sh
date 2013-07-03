#!/bin/sh
#
# Gather updates and patches daily. Online updates must be enabled. (For SLES only.)

[[ $(id -u) -ne 0 ]] && echo "Must be ran as root. Exiting." && exit $EXIT_ERR

EXIT_OK=0
EXIT_ERR=1

LOG_FILE="/var/log/$(basename $0 .sh).log"
TMP_FILE=/root/tmp/$(basename $0 .sh).$(date +'%F')
SUBJECT="$(hostname): Updates for $(date +'%F')"
RCPT=admin@somecompany.com

cleanup() {
    exit_code=$1
    rm -f $TMP_FILE
    logMessage echo "Cleaning up. Return code: $exit_code" >> $LOG_FILE
    exit $exit_code
}

logMessage() {
    COMMAND="$*"

    sh -c "${COMMAND} | awk '{
        \"echo \\\"$(date +%b\ %e\ %T) $(hostname) $(basename $0)[$$]:\\\"\"|getline timestamp;
        close(\"echo \\\"$(date +%b\ %e\ %T) $(hostname) $(basename $0)[$$]:\\\"\");
        printf(\"%s %s\n\", timestamp, \$0)
    }'"
}
[ ! -e $LOG_FILE ] && touch $LOG_FILE && logMessage echo "Starting $(basename $0)." > $LOG_FILE


logMessage echo "Searching for latest updates." >> $LOG_FILE
echo "${SUBJECT}" >> $TMP_FILE
/usr/bin/zypper lu >> $TMP_FILE 2>/dev/null
zypper_exit=$?

if [[ $zypper_exit -eq 141 ]] ; then
    logMessage echo "Updates found. Sending mail." >> $LOG_FILE
    cat $TMP_FILE | mail -s "[LINUX PATCH NOTICE] ${SUBJECT}" -r $RCPT
    [[ $? -ne 0 ]] && logMessage echo "Something went wrong. Please check." >> $LOG_FILE && cleanup $EXIT_ERR
    cleanup $EXIT_OK
elif [[ $zypper_exit -eq 0 ]] ; then
    logMessage echo "No updates found." >> $LOG_FILE
    cleanup $EXIT_OK
else
    logMessage echo "Something went wrong. Please check." >> $LOG_FILE && cleanup $EXIT_ERR
fi
