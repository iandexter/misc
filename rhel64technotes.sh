#!/bin/bash
#
# Extract CVE info from RHEL 6.4 tech notes

proxy="proxy:port"
curl_cmd="curl -x ${proxy} -skL "

url="https://access.redhat.com/site/documentation/en-US/Red_Hat_Enterprise_Linux/6/html-single/6.4_Technical_Notes/"

getCVEs() {
    url=$1
    ${curl_cmd} ${url} | grep CVE- | grep href \
        | sed 's/.*href=\"\(.*\)\">C.*/\1/'
}

extractCVEinfo() {
    url=$(echo ${1} | sed 's/www/access/;s/\/data//')
	echo -n "${url}|"
	${curl_cmd} ${url} | grep -EA 1 "/classification/#|bugzilla" \
        | sed 's/^\s\+//;s/<[^>]\+>//g;/^$/d;/^--/d;/^[0-9]/d' \
        | sed 's/\(.*\)\ \(.*:.*\)/\1\|\2/' | tr '\n' '|'
    echo ""
}
for u in $(getCVEs ${url}) ; do
    extractCVEinfo ${u}
    sleep 1
done | tee -a $(basename $0 .sh).txt
