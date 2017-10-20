#!/bin/bash 
#bdereims@vmware.com

. ./env

[ "${1}" == "" ] && echo "usage: ${0} <deploy_env or cPod Name>" && exit 1


if [ -f "${1}" ]; then
	. ./${COMPUTE_DIR}/"${1}"
else
	SUBNET=$( ./${COMPUTE_DIR}/cpod_ip.sh ${1} )

	[ $? -ne 0 ] && echo "error: file or env '${1}' does not exist" && exit 1

	CPOD=${1}
	. ./${COMPUTE_DIR}/cpod-xxx_env
fi

### PSC vars ####

HOSTNAME=${HOSTNAME_PSC}
NAME=${NAME_PSC}
IP=${IP_PSC}
OVA=${OVA_VCSA}
TARGET=${TARGET_VCSA}
DATASTORE=${DATASTORE_VCSA}
PORTGROUP=${PORTGROUP_VCSA}

###################

umount /mnt
mount -o loop $OVA /mnt

SEDCMD="s/###PASSWORD###/${PASSWORD}/;s!###TARGET###!${TARGET}!;s/###PORTGROUP###/${PORTGROUP}/;s/###DATASTORE###/${DATASTORE}/;s/###IP###/${IP}/;s/###DNS###/${DNS}/;s/###GATEWAY###/${GATEWAY}/;s/###HOSTNAME###/${HOSTNAME}/;s/###NAME###/${NAME}/;s/###SITE###/${SITE}/;s/###DOMAIN###/${DOMAIN}/"
cat ${COMPUTE_DIR}/psc-65.json
cat ${COMPUTE_DIR}/psc-65.json | sed "${SEDCMD}"  > /tmp/psc-65.json

pushd /mnt/vcsa-cli-installer/lin64
./vcsa-deploy install --no-esx-ssl-verify --accept-eula --acknowledge-ceip /tmp/psc-65.json
popd

sleep 60

### update vCSA vars ####

HOSTNAME=${HOSTNAME_VCSA}
NAME=${NAME_VCSA}
IP=${IP_VCSA}

###################

SEDCMD="s/###PASSWORD###/${PASSWORD}/;s!###TARGET###!${TARGET}!;s/###PORTGROUP###/${PORTGROUP}/;s/###DATASTORE###/${DATASTORE}/;s/###IP###/${IP}/;s/###DNS###/${DNS}/;s/###GATEWAY###/${GATEWAY}/;s/###HOSTNAME###/${HOSTNAME}/;s/###NAME###/${NAME}/;s/###PSC###/${HOSTNAME_PSC}/;s/###DOMAIN###/${DOMAIN}/"
cat ${COMPUTE_DIR}/vcsa-65.json | sed "${SEDCMD}"  > /tmp/vcsa-65.json

pushd /mnt/vcsa-cli-installer/lin64
./vcsa-deploy install --no-esx-ssl-verify --accept-eula --acknowledge-ceip /tmp/vcsa-65.json
popd

sleep 60 

./compute/prep_vcsa.sh ${CPOD}
