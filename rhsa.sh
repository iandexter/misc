#!/bin/bash
#
# Extract CVE info from RHSA enterprise watchlist archives.

tmpdir='/var/tmp'
proxy='proxy:port'
curl_cmd="curl -x ${proxy} -skL"
rhsa_archive_url="https://www.redhat.com/archives/enterprise-watch-list"
cve_urls=''

year=''
month=''
rhsa_mails=''
cve_txt=''

popexit() { popd &>/dev/null && exit $1; }

printusage() {
    echo "Extract CVE info from RHSA enterprise watchlist archives."
    echo "Usage: $0 [-d|-e] year-month"
    echo "  -d Download and extract from mail archive"
    echo "  -e Extract from text file (in /var/tmp)"
    echo "  -s Print summary from text file (in /var/tmp)"
    popexit 2
}

printerror() {
    echo "Error downloading file. Manually download from"
    echo ${rhsa_archive_url}
    [[ -f ${rhsa_mails}.gz ]] && rm -f ${rhsa_mails}.gz &>/dev/null
    [[ -f ${rhsa_mails} ]] && rm -f ${rhsa_mails} &>/dev/null
    popexit 1
}

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
        | sed 's/\(CVE.*[0-9]\)\ \(.*:.*\)/\1\|\2/' | tr '\n' '|'
    echo ''
}

collectCVEurls() {
    echo "Collecting CVE URLs from ${rhsa_mails}..."
    for a in $(awk '/Advisory URL/ {print $NF}' ${rhsa_mails}) ; do
        for c in $(getCVEs ${a}) ; do
            cve_urls="${cve_urls} ${c}"
        done
    done
    cve_urls=$(echo ${cve_urls} | tr ' ' '\n' | sort -u)
}

listpackages() {
    grep $1 ${cve_txt} | awk -F\| '{print $(NF-1)}' \
        | sed 's/\(.*\):\ .*/\1/' | sort -u | sed 's/\(.*\):\ .*/\1/' \
        | sort -fu | tr '\n' ',' | sed 's/,/,\ /g;s/,\ $//'
}

summarize() {
    [[ ! -f ${cve_txt} ]] && echo "${cve_txt} not found" && popexit 1
    printf "%-11s: %-30s\n" 'Results' ${cve_txt}
    printf "%-11s: %-30s\n" 'Raw file' ${tmpdir}/${rhsa_mails}
    echo '---'
    printf "%-11s: %3d\n\n" 'Total CVEs' \
        $(wc -l ${cve_txt} | awk '{print $1}')
    for s in Critical Important Moderate Low ; do
        printf "%-11s: %3d %s\n" $s $(grep -c $s ${cve_txt}) \
        "($(listpackages $s))"
    done
}

saveCVEinfo() {
    [[ ! -f ${rhsa_mails} ]] && echo "${rhsa_mails} not found" && popexit 1
    collectCVEurls
    echo "Extracting CVE info..."
    for c in ${cve_urls} ; do
        extractCVEinfo ${c} >> $(basename $0 .sh)-${rhsa_mails}
    done
    echo '---'
    summarize
    popexit 0
}

getvars() {
    year=$(echo ${1} | sed 's/\(.*\)-.*/\1/')
    month=$(echo ${1} | sed 's/.*-\(.*\)/\1/' | tr [A-Z] [a-z] \
        | sed 's/.*/\u&/')
    rhsa_mails="${year}-${month}.txt"
    rhsa_archive_url="${rhsa_archive_url}/${rhsa_mails}.gz"
    cve_txt="${tmpdir}/$(basename $0 .sh)-${rhsa_mails}"
}

### main

pushd ${tmpdir} &>/dev/null
while getopts ":d:e:s:" opts ; do
    case "${opts}" in
        d)
            getvars ${OPTARG}
            echo -n "Downloading ${rhsa_mails}..."
            ${curl_cmd} -O ${rhsa_archive_url}
            [[ $? -eq 0 ]] && gunzip ${rhsa_mails}.gz &>/dev/null || printerror
            [[ $? -eq 0 ]] && saveCVEinfo || printerror
            ;;
        e)
            getvars ${OPTARG}
            saveCVEinfo
            ;;
        s)
            getvars ${OPTARG}
            summarize
            popexit 0
            ;;
        *)
            printusage
    esac
done

[[ -z ${year} && -z ${month} ]] && printusage
