#
# CODENVY CONFIDENTIAL
# ________________
#
# [2012] - [2014] Codenvy, S.A.
# All Rights Reserved.
# NOTICE: All information contained herein is, and remains
# the property of Codenvy S.A. and its suppliers,
# if any. The intellectual and technical concepts contained
# herein are proprietary to Codenvy S.A.
# and its suppliers and may be covered by U.S. and Foreign Patents,
# patents in process, and are protected by trade secret or copyright law.
# Dissemination of this information or reproduction of this material
# is strictly forbidden unless prior written permission is obtained
# from Codenvy S.A..
#

#!/bin/bash
if [ -z "$1" ] || [ "$1" == "prod" ]; then
    SSH_KEY_NAME=cl-server-prod-20130219
    SSH_AS_USER_NAME=codenvy
    AS_IP=update.codenvycorp.com
    echo "=========> Uploading on production"
elif [ "$1" == "stg" ]; then
    SSH_KEY_NAME=as1-cldide_cl-server.skey
    SSH_KEY_NAME=git_nopass.key # TODO [AB]
    SSH_AS_USER_NAME=codenvy
    AS_IP=syslog.codenvy-stg.com
    echo "=========> Uploading on staging"
else
    echo "Unknown server destination"
    exit 1
fi

uploadArtifactInstallationManager() {
    ARTIFACT=installation-manager

    FILENAME=`ls ${ARTIFACT}-cli-assembly/target | grep -G ${ARTIFACT}-.*-binary[.]tar.gz`
    VERSION=`ls ${ARTIFACT}-cli-assembly/target | grep -G ${ARTIFACT}-.*[.]jar | grep -vE 'sources|original' | sed 's/'${ARTIFACT}'-//' | sed 's/.jar//'`
    SOURCE=${ARTIFACT}-cli-assembly/target/${FILENAME}
    MD5=`md5sum ${SOURCE} | cut -d ' ' -f 1`
    SIZE=`du -b ${SOURCE} | cut -f1`

    doUpload
}

uploadCodenvySingleServerInstallScript() {
    ARTIFACT=install-codenvy-single-server
    FILENAME=install-codenvy-single-server.sh
    VERSION=$1
    SOURCE=installation-manager-resources/src/main/resources/${VERSION}/${FILENAME}
    doUpload

    if [ "${AS_IP}" == "syslog.codenvy-stg.com" ]; then
        ssh -i ~/.ssh/${SSH_KEY_NAME} ${SSH_AS_USER_NAME}@${AS_IP} "sed -i 's/codenvy.com/codenvy-stg.com/g' ${DESTINATION}/${FILENAME}"
    fi
}

uploadCodenvySingleServerInstallProperties() {
    ARTIFACT=codenvy-single-server-properties
    FILENAME=codenvy-single-server.properties
    VERSION=$1
    SOURCE=installation-manager-resources/src/main/resources/${VERSION}/${FILENAME}
    doUpload
}

doUpload() {
    DESTINATION=update-server-repository/${ARTIFACT}/${VERSION}

    echo "file=${FILENAME}" > .properties
    echo "artifact=${ARTIFACT}" >> .properties
    echo "version=${VERSION}" >> .properties
    echo "authentication-required=false" >> .properties
    buildTime=`stat -c %y ${SOURCE}`
    buildTime=${buildTime:0:19}

    echo "build-time="${buildTime} >> .properties
    echo "md5=${MD5}" >> .properties
    echo "size=${SIZE}" >> .properties
    ssh -i ~/.ssh/${SSH_KEY_NAME} ${SSH_AS_USER_NAME}@${AS_IP} "mkdir -p /home/${SSH_AS_USER_NAME}/${DESTINATION}"
    scp -o StrictHostKeyChecking=no -i ~/.ssh/${SSH_KEY_NAME} ${SOURCE} ${SSH_AS_USER_NAME}@${AS_IP}:${DESTINATION}/${FILENAME}
    scp -o StrictHostKeyChecking=no -i ~/.ssh/${SSH_KEY_NAME} .properties ${SSH_AS_USER_NAME}@${AS_IP}:${DESTINATION}/.properties

    rm .properties
}

uploadArtifactInstallationManager
uploadCodenvySingleServerInstallScript 3.1.0
uploadCodenvySingleServerInstallProperties 3.1.0

