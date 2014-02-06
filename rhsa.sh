#!/bin/bash
#
# Extract CVE info from RHSA enterprise watchlist archives.

proxy='proxy:port"
curl_cmd="curl -x ${proxy} -skL"
rhsa_archive_url='https://www.redhat.com/archives/enterprise-watch-list/2014-January.txt.gz'

getCVEs() {
    url=$1
        ${curl_cmd} ${url} | grep -E "security/data/cve.*https" \
        | sed 's/<br \/>/|/g' | tr '|' '\n' | sed 's/^\s\+//;/^$/d' \
        | sed 's/<[^>]\+>//g;' | grep https
}

extractCVEinfo() {
    url=$1
    echo -n "${url}|"
        ${curl_cmd} ${url} | grep -EA 1 "/classification/#|bugzilla" \
    | sed 's/^\s\+//;s/<[^>]\+>//g;/^$/d;/^--/d;/^[0-9]/d' \
    | sed 's/\(.*\)\ \(.*:.*\)/\1\|\2/' | tr '\n' '|'
    echo ''
}

${curl_cmd} -O ${rhsa_archive_url}
rhsa_mails='2014-January.txt'

for a in $(awk '/Advisory URL/ {print $NF}' ${rhsa_mails}) ; do
    for c in $(getCVEs ${a}) ; do
        extractCVEinfo ${c}
    done
done | tee -a $(basename $0 .sh).txt
