#!/bin/sh
#
# Renew FTP SSL certificate.

OPENSSL=$(which openssl)
[[ ! -e ${OPENSSL} ]] && echo "OpenSSL is not in the expected path: ${OPENSSL}. Exiting." && exit 1

CERT_PATH=/etc/vsftpd/vsftpd.pem
[[ ! -e ${CERT_PATH} ]] && echo "Certificate file is not in the expected path: ${CERT_PATH}. Exiting." && exit 1

CERT_SUBJ="/C=PH/ST=State/L=City/O=Company/OU=Department/CN=$(hostname -f)/emailAddress=admin@company.com"
CERT_AGE=365 ### More if required

cp ${CERT_PATH}{,.$(date +%s)}
${OPENSSL} req -x509 -nodes -days ${CERT_AGE} -newkey rsa:2048 -subj "${CERT_SUBJ}" \
    -keyout ${CERT_PATH} -out ${CERT_PATH}
echo "Verify the following certificate:"
${OPENSSL} x509 -text -in ${CERT_PATH}
echo "Once verified, copy the following and send to Mainframe:"
cat ${CERT_PATH}
