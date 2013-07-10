#!/bin/sh
#
# Sync cron files from the central repository. Run from root's crontab.
#
# This project was accepted in the LOPSA Mentorship Program 
# (https://lopsa.org/mentor).
#
# Overall design
# --------------
#
# 1. Cron jobs are organized one file per server. Standard jobs
#    applicable for a set of servers are in global files (for ERP, DB, 
#    web, etc.).
#
# 2. These files are under Subversion. The repository layout is as follows:
#
#    . branches
#    |--+ dev
#    |  |--- hostname_00
#    |  |--- ...
#    |  |--- hostname_nn
#    |  |--- web
#    |  |--- erp
#    |  |--- db
#    |  |--- ...
#    |--+ test ...
#    |--+ prod ...
#
#    (Global files should also fall under the respective environments.)
#
# 3. An updated working copy is served via HTTP. The update to this
#    working copy is done through hook scripts.
#
# 4. System administrators edit cron jobs per service or change request
#    and commit these to the repository.
#
# 5. Each server polls for changes (once daily) and retrieves the latest
#    update via `curl`. The file(s) are added to crontab. Ad-hoc
#    or on-demand changes can be done this way as well.


ENVIRONMENT=$(echo $1 | tr '[:upper:]' '[:lower:]')
SRC="http://172.23.13.136/config/cron/${ENVIRONMENT}"
CRON_FILE=$(hostname)
TMP_FILE="/root/tmp/${CRON_FILE}.cron"
CUR_FILE="/root/tmp/${CRON_FILE}.cur"
TMP_DIR=$(dirname ${TMP_FILE})

EXIT_USAGE=64
EXPECTED_ARGS=1
displayHelp() {
    echo ""
    echo "$(basename $0) - Sync cron files."
    echo ""
    echo "Usage: $(basename $0) dev|test|prod"
    echo ""
    exit $EXIT_USAGE
}

# Command-line sanity checks
[[ $(id -u) -ne 0 ]] && { echo "Must be ran as root."; displayHelp; } && exit 1
[[ $# -ne $EXPECTED_ARGS ]] && displayHelp
case ${ENVIRONMENT} in
    dev)
        ;;
    test)
        ;;
    prod)
        ;;
    *)
        displayHelp
esac

LOG_FILE="/var/log/$(basename $0 .sh).log"
logMessage() {
    COMMAND="$*"

    sh -c "${COMMAND} | awk '{
        \"echo \\\"$(date +%b\ %e\ %T) $(hostname) $(basename $0)[$$]:\\\"\"|getline timestamp;
        close(\"echo \\\"$(date +%b\ %e\ %T) $(hostname) $(basename $0)[$$]:\\\"\");
        printf(\"%s %s\n\", timestamp, \$0)
    }'"
}
[[ ! -e ${LOG_FILE} ]] && touch ${LOG_FILE} && logMessage echo "Starting $(basename $0)..." > ${LOG_FILE}

cleanUp() {
    rm ${TMP_FILE} ${CUR_FILE}
    exit $1
}

installCron() {
    /usr/bin/crontab ${TMP_FILE} 1>/dev/null 2>&1
    if [[ $? -eq 0 ]] ; then
        logMessage echo "Cron file synced." >> ${LOG_FILE}
        cleanUp 0
    else
        logMessage echo "Error syncing cron file." >> ${LOG_FILE}
        cleanUp 1
    fi
}


[[ ! -d ${TMP_DIR} ]] && mkdir -p ${TMP_DIR}

logMessage echo "Downloading from ${SRC}/${CRON_FILE}" >> ${LOG_FILE}
/usr/bin/curl -s "${SRC}/${CRON_FILE}" -o "${TMP_FILE}"

if [[ $? -eq 0 ]] ; then
    /usr/bin/crontab -l > ${CUR_FILE} 2>/dev/null

    # No crontab, install one
    if [[ $? -eq 1 ]] ; then
        installCron
    else
        sed -i '1,3d' ${CUR_FILE}
    fi

    # Check freshness
    SHA1=$(/usr/bin/sha1sum ${TMP_FILE} ${CUR_FILE})
    if [[ $(echo ${SHA1} | awk '{print $1}') = $(echo ${SHA1} | awk '{print $3}') ]] ; then
        logMessage echo "Cron tab is current. Nothing to sync." >> ${LOG_FILE}
        cleanUp 0
    else
        installCron
    fi
else
    logMessage echo "Error syncing cron file." >> ${LOG_FILE}
    cleanUp 1
fi
