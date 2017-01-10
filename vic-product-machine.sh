#!/bin/bash

# Massimo Re Ferre' mreferre@vmware.com

###########################################################
###########              USER INPUTS            ###########
###########################################################

#The following parameters need to map your existing infrastructure details
export VCENTERSERVER="192.168.8.211"
export VCENTERDATACENTER="DTC1"
export VCENTERCLUSTER="Cluster1"
export VSPHEREUSER="user1@vsphere.local"
export VSPHEREPASSWORD="Vmware123!"
export VSPHEREDATASTORE="sharedstorage"
export PUBLICNETWORK="VM Network"
export VCHINTERNALNETWORK="PG1"

#The following parameters are used to set the parameters of the objects you are deploying
export VCHTLS=0 # 0=no tls, 1=tls enabled
export VCHNAME="VCH1"
export VCHIP="192.168.8.231"
export VCHGATEWAY="192.168.8.253/24"
export HARBORVMIP="192.168.8.221"
export HARBORVMNAME="Harbor1"
export HARBORVMDOMAIN="vsphere.local"
export HARBORVMSEARCHPATH="vsphere.local"
export HARBORVMDNS="8.8.8.8"
export HARBORVMMASK="255.255.255.0"
export HARBORVMGATEWAY="192.168.8.253"
export HARBORROOTPASSWORD="Vmware123!" #this is the value to be set when deploying Harbor
export HARBORADMINPASSWORD="Vmware123!" #this is the value to be set when deploying Harbor
export HARBORDBPASSWORD="Vmware123!" #this is the value to be set when deploying Harbor
export HARBORAUTHMODE="db_auth"
###########################################################
###########           END OF USER INPUTS        ###########
###########################################################



###########################################################
## DO NOT TOUCH THESE UNLESS YOU KNOW WHAT YOU ARE DOING ##
###########################################################
export HARBORURL="https://github.com/vmware/harbor/releases/download/0.5.0/"
export HARBORFILE="harbor_0.5.0-9e4c90e"
export VICURL="https://bintray.com/vmware/vic/download_file?file_path="
export VICVERSION="vic_0.8.0"
export DOCKER_API_VERSION="1.23"
export ADMIRALEXTERNALPORT="8282"
export ADMIRALCLIURL="https://bintray.com/vmware/admiral/download_file?file_path=com/vmware/admiral/admiral-cli/0.9.1/"
export ADMIRALCLIFILE="admiral-cli-0.9.1-dist.zip"
export ADMIRALCLIEXTRACTDIR="admiral-cli-0.9.1"
export LOG_OUTPUT="vic-product-machine.log"
###########################################################
###########                                     ###########
###########################################################



logger() {
  LOG_TYPE=$1
  MSG=$2

  COLOR_OFF="\x1b[39;49;00m"
  case "${LOG_TYPE}" in
      green)
          # Green
          COLOR_ON="\x1b[32;01m";;
      blue)
          # Blue
          COLOR_ON="\x1b[36;01m";;
      yellow)
          # Yellow
          COLOR_ON="\x1b[33;01m";;
      red)
          # Red
          COLOR_ON="\x1b[31;01m";;
      default)
          # Default
          COLOR_ON="${COLOR_OFF}";;
      *)
          # Default
          COLOR_ON="${COLOR_OFF}";;
  esac

  TIME=$(date +%F" "%H:%M:%S)
  echo -e "${COLOR_ON} ${TIME} -- ${MSG} ${COLOR_OFF}"
  echo -e "${TIME} -- ${MSG}" >> "${LOG_OUTPUT}"
}

errorcheck() {
   if [ $? != 0 ]; then
          logger "red" "Unrecoverable generic error found in function: [$1]. Check the log. Exiting."
      exit 1
   fi
}

checkrequirements() {
   hash $1 >> /dev/null  2>&1
   if [ $? != 0 ]; then
          logger "red" "Ops. Utility <$1> is not available on the system or it's not 'in path'. Please install it and re-launch the script"
      exit 1
   else
          logger "default" "Utility <$1>        has been found in the system and is 'in path'. Proceeding."
   fi
}

checkOsType() {
   logger "default" "Checking OS Type ..."
   case ${OSTYPE} in
   darwin*)
       export OS="darwin"
   ;;
   linux*)
       export OS="linux"
   ;;
   windows*)
       export OS="windows" #Note: most likely it won't work yet on Windows
   ;;
   esac
   logger "default" "OS Type detected: $OS"
}

setTlsOptions() {
   logger "default" "Determining desired TLS settings ..."
   case ${VCHTLS} in
   0)
       export VCHPORT="2375"
       export VICMACHINETLSFLAG="--no-tls"
       export DOCKERCLITLSFLAG=""
       logger "default" "TLS is NOT going to be enabled for the Virtual Container Host ..."
   ;;
   1)
       export VCHPORT="2376"
       export VICMACHINETLSFLAG="--tls-cname ${VCHIP}"
       export DOCKERCLITLSFLAG="--tlsverify --tlscacert="${VCHNAME}/ca.pem" --tlscert="${VCHNAME}/cert.pem" --tlskey="${VCHNAME}/key.pem""
       logger "default" "TLS is going to be enabled for the Virtual Container Host ..."
   ;;
   *)
       logger "red" "VCHTLS variable set to something wrong (valid values are either 0 or 1). Exiting"
       exit 1   ;;
   esac
}

clearanceToGo() {
  # advise users about the deployment task and request a GO
  logger "yellow" "Warning: this script will deploy VIC onto your vSphere infrastructure"
  logger "yellow" "If you haven't set the proper parameters yet, stop the script, edit it and enter the information required"
  logger "yellow" "FYI this is how the infrastructure context is configured"
  logger "green" "VCENTERSERVER= ${VCENTERSERVER}"
  logger "green" "VCENTERDATACENTER= ${VCENTERDATACENTER}"
  logger "green" "VCENTERCLUSTER= ${VCENTERCLUSTER}"
  logger "green" "VSPHEREUSER= ${VSPHEREUSER}"
  logger "green" "VSPHEREPASSWORD= <see file, not printing it here>"
  logger "green" "VSPHEREDATASTORE= ${VSPHEREDATASTORE}"
  logger "green" "PUBLICNETWORK= ${PUBLICNETWORK}"
  logger "green" "VCHINTERNALNETWORK= ${VCHINTERNALNETWORK}"
  logger "green" "VCHTLS= ${VCHTLS} (0=no tls, 1=tls enabled)"
  logger "green" "VCHNAME= ${VCHNAME}"
  logger "green" "VCHIP=${VCHIP}"
  logger "green" "VCHGATEWAY=${VCHGATEWAY}"
  logger "green" "HARBORVMIP= ${HARBORVMIP}"
  logger "green" "HARBORVMNAME= ${HARBORVMNAME}"
  logger "green" "HARBORVMDOMAIN= ${HARBORVMDOMAIN}"
  logger "green" "HARBORVMSEARCHPATH= ${HARBORVMSEARCHPATH}"
  logger "green" "HARBORVMDNS= ${HARBORVMDNS}"
  logger "green" "HARBORVMMASK= ${HARBORVMMASK}"
  logger "green" "HARBORVMGATEWAY= ${HARBORVMGATEWAY}"
  logger "green" "HARBORROOTPASSWORD= ${HARBORROOTPASSWORD}"
  logger "green" "HARBORADMINPASSWORD= ${HARBORADMINPASSWORD}"
  logger "green" "HARBORDBPASSWORD= ${HARBORDBPASSWORD}"
  logger "green" "HARBORAUTHMODE= ${HARBORAUTHMODE}"
  logger "blue" "If you decide to proceed, now it is a good time to tail -f ${LOG_OUTPUT} in another terminal"
  logger "yellow" "Do you want to proceed (yes/no)?"
  read ANSWER
  if [ "${ANSWER}" = "yes" ]; then
    logger "default" "Proceeding..."
  else
    logger "red" "Exiting"
    exit 1
  fi
}

checkHarborOva() {
  logger "default" "Checking for Harbor OVA ..."
  if [ ! -e ${HARBORFILE}.ova ]; then
    logger "default" "Downloading Harbor OVA, this may take a tiny bit..."
    curl -O -L "${HARBORURL}${HARBORFILE}.ova" >> "${LOG_OUTPUT}" 2>&1
    errorcheck ${FUNCNAME}
  else
    logger "default" "Harbor OVA already available! Skipping download ..."
  fi
}

extractHarborOva() {
  logger "default" "Checking for Harbor OVF ..."
  if [ ! -e ${HARBORFILE}.ovf ]; then
    logger "default" "Extracting Harbor OVF. This will take a few minutes ..."
    ovftool "${HARBORFILE}.ova" "${HARBORFILE}.ovf" >> "${LOG_OUTPUT}" 2>&1
  else
    logger "default" "Harbor OVF already available! Skipping extract ..."
  fi
    errorcheck ${FUNCNAME}
}

importHarborOva() {
  logger "default" "Importing Harbor OVF into vSphere ..."
  if [ ! -e "${HARBORFILE}.ovf" ]; then
    logger "red" "Harbor OVF does not exist! There is something wrong here. Exiting."
    exit 1
  else
  ovftool --datastore=${VSPHEREDATASTORE} \
               --noSSLVerify \
               --acceptAllEulas \
               --name=${HARBORVMNAME} \
               --net:"Network 1"="${PUBLICNETWORK}" \
               --diskMode=thin \
               --powerOn \
               --X:waitForIp \
               --X:injectOvfEnv \
               --X:enableHiddenProperties \
               --prop:auth_mode="${HARBORAUTHMODE}" \
               --prop:root_pwd="${HARBORROOTPASSWORD}" \
               --prop:harbor_admin_password="${HARBORADMINPASSWORD}" \
               --prop:db_password="${HARBORDBPASSWORD}" \
               --prop:vami.domain.Harbor="${HARBORVMDOMAIN}" \
               --prop:vami.searchpath.Harbor="${HARBORVMSEARCHPATH}" \
               --prop:vami.DNS.Harbor="${HARBORVMDNS}" \
               --prop:vami.ip0.Harbor="${HARBORVMIP}" \
               --prop:vami.netmask0.Harbor="${HARBORVMMASK}" \
               --prop:vami.gateway.Harbor="${HARBORVMGATEWAY}" \
               --prop:vm.vmname=Harbor \
               "${HARBORFILE}.ovf" \
               vi://"${VSPHEREUSER}":"${VSPHEREPASSWORD}"@${VCENTERSERVER}/${VCENTERDATACENTER}/host/${VCENTERCLUSTER} >> "${LOG_OUTPUT}" 2>&1
  errorcheck ${FUNCNAME}
  logger "default" "Harbor OVF imported successfully"
  fi
}

getVicBinaries() {
  logger "default" "Checking for VIC binaries ..."
  if [ ! -e ${VICVERSION}.tar.gz ]; then
    logger "default" "Downloading VIC binaries version ${VICVERSION}, this may take a tiny bit..."
    curl -k -L -o ${VICVERSION}.tar.gz "${VICURL}${VICVERSION}.tar.gz" >> "${LOG_OUTPUT}" 2>&1
    errorcheck ${FUNCNAME}
  else
    logger "default" "VIC binaries version ${VICVERSION} already available! Skipping download ..."
  fi
}

extractVicBinaries() {
  logger "default" "Checking for VIC binaries extraction ..."
  if [ ! -d ./vic ]; then
    logger "default" "Extracting VIC binaries version ${VICVERSION} ..."
    tar -zxvf ${VICVERSION}.tar.gz >> "${LOG_OUTPUT}" 2>&1
    errorcheck ${FUNCNAME}
  else
    logger "default" "a vic directory is already present. Skipping extraction (it is recommended that you check if the VIC version in there is ${VICVERSION} ..."
  fi
}

deployVch() {
  logger "default" "Checking if VCH ${VCHNAME} has already been deployed ..."
  #the following check will not work. It used to originally work but then the latest vic-machine versions added the need to verify the vCenter you are connecting to.
  #since "ls" doesn't support the "--force" flag, I can't force accept the vCenter certificate (and I didn't bother to automate a workaround). More here: https://github.com/vmware/vic/issues/3117
  ./vic/vic-machine-"${OS}" ls \
    --target "${VCENTERSERVER}" \
    --user "${VSPHEREUSER}" \
    --password "${VSPHEREPASSWORD}" \
    | grep ${VCHNAME} >> "${LOG_OUTPUT}" 2>&1
  if [ $? == 0 ]; then
       logger "default" "${VCHNAME} has already been deployed on vSphere. Skipping the deployment of ${VCHNAME}"
  else
       logger "default" "${VCHNAME} has not been deployed yet. Deploying VCH ${VCHNAME} on vSphere ..."
       ./vic/vic-machine-"${OS}" create --name ${VCHNAME} \
           --target "${VCENTERSERVER}" \
           --user "${VSPHEREUSER}" \
           --password "${VSPHEREPASSWORD}" \
           --compute-resource "${VCENTERCLUSTER}" \
           --bridge-network "${VCHINTERNALNETWORK}" \
           --public-network "${PUBLICNETWORK}" \
           --public-network-ip "${VCHIP}" \
           --public-network-gateway "${VCHGATEWAY}" \
           --image-store "${VSPHEREDATASTORE}"  \
           --insecure-registry "${HARBORVMIP}":80 \
           --volume-store "${VSPHEREDATASTORE}"/"${VCHNAME}"volumes:default \
           --timeout 10m0s \
           --force \
           ${VICMACHINETLSFLAG} >> "${LOG_OUTPUT}" 2>&1
       errorcheck ${FUNCNAME}
       logger "default" "${VCHNAME} has been deployed ..."
  fi
}

#This function is redundant because I am using a fixed IP so I know what it is (but it may come handy if/when using DCHP for the VCH should I leverage that option in the future)
grabVchIp() {
  logger "default" "Grabbing the ${VCHNAME} IP address ..."
  #DOCKER_HOST_VALUE=$(grep DOCKER_HOST= vic-product-machine.log | tail -1 | sed 's/^.*DOCKER_HOST/DOCKER_HOST/' | xargs) >> "${LOG_OUTPUT}" 2>&1 ## to get "DOCKER_HOST=<ip>:${VCHPORT}"
  DOCKER_HOST_VALUE=$(grep DOCKER_HOST= vic-product-machine.log | tail -1 | sed 's/^.*DOCKER_HOST=//' | sed 's/:'$VCHPORT'//' | xargs) >> "${LOG_OUTPUT}" 2>&1 ## to get "<ip>"
  errorcheck ${FUNCNAME}
  logger "default" "${VCHNAME} has IP address ${DOCKER_HOST_VALUE}"
}

pullImage() {
  logger "default" "Pulling docker image $1 on VCH $2"
  docker ${DOCKERCLITLSFLAG} -H $2:${VCHPORT} pull $1 >> "${LOG_OUTPUT}" 2>&1
  errorcheck ${FUNCNAME}
  logger "default" "Docker image $1 pulled correctly on VCH $2"
}

instantiateNetMappingImage() {
  logger "default" "Checking if instance $5 is already present on VCH ${VCHNAME} ..."
  docker ${DOCKERCLITLSFLAG} -H $2:${VCHPORT} ps -a | grep $5 >> "${LOG_OUTPUT}" 2>&1
  if [ $? == 0 ]; then
       logger "default" "$5 seems to be already present on VCH ${VCHNAME}. Skipping its instantiation"
  else
       logger "default" "$5 is not present on ${VCHNAME}. Instantiating it ..."
       docker ${DOCKERCLITLSFLAG} -H $2:${VCHPORT} run -d -p $3:$4 --name $5 $1 >> "${LOG_OUTPUT}" 2>&1
       errorcheck ${FUNCNAME}
       logger "default" "$5 has been instantiated correctly on VCH ${VCHNAME}"
  fi
}

getAdmiralCli() {
logger "default" "Downloading the admiral CLI and putting it into /usr/local/bin"
    curl -k -L -o ${ADMIRALCLIFILE} "${ADMIRALCLIURL}${ADMIRALCLIFILE}" >> "${LOG_OUTPUT}" 2>&1
    errorcheck ${FUNCNAME}
    unzip -o ${ADMIRALCLIFILE} >> "${LOG_OUTPUT}" 2>&1
    errorcheck ${FUNCNAME}
    cp -f ./${ADMIRALCLIEXTRACTDIR}/bin/${OS}-amd64/admiral . >> "${LOG_OUTPUT}" 2>&1
    errorcheck ${FUNCNAME}
    chmod +x admiral >> "${LOG_OUTPUT}" 2>&1
    errorcheck ${FUNCNAME}
}

configAdmiralCli() {
  logger "default" "Configuring Admiral CLI to point to ${DOCKER_HOST_VALUE}:${ADMIRALEXTERNALPORT}"
  ./admiral config set -k "url" -v "http://$1:$2" >> "${LOG_OUTPUT}" 2>&1
  errorcheck ${FUNCNAME}
  logger "default" "Admiral CLI properly configured to point to $1:$2"
}

addUsernameCredentialsAdmiral() {
  logger "default" "Adding credentials of type 'Username' to Admiral"
  ./admiral credentials add --name $1 --username $2 --password $3 >> "${LOG_OUTPUT}" 2>&1
  errorcheck ${FUNCNAME}
  ADMIRALCREDENTIALSID=$(tail -1 ${LOG_OUTPUT} | sed 's/.* //g')
  logger "default" "Credentials of type 'Username' succesffully added to Admiral"
}

addCertificateCredentialsAdmiral() {
  logger "default" "Adding credentials of type 'Certificate' to Admiral"
  ./admiral credentials add --name $1 --public $2 --private $3 >> "${LOG_OUTPUT}" 2>&1
  errorcheck ${FUNCNAME}
  ADMIRALCREDENTIALSID=$(tail -1 ${LOG_OUTPUT} | sed 's/.* //g')
  logger "default" "Credentials of type 'Certificate' succesffully added to Admiral"
}

addHostAdmiral() {
  logger "default" "Adding VCH $1 to Admiral"
  if [ ${VCHTLS} == 0 ]; then
       ./admiral host add --placement-zone=default-placement-zone --address="http://"${DOCKER_HOST_VALUE}:${VCHPORT} >> "${LOG_OUTPUT}" 2>&1
       errorcheck ${FUNCNAME}
       logger "default" "VCH $1 succesfully added to Admiral without any credentials"
  else
       addCertificateCredentialsAdmiral ${VCHNAME} ./${VCHNAME}/cert.pem ./${VCHNAME}/key.pem #this should be used only when the VCH has been deployed with TLS.
       ./admiral host add --placement-zone=default-placement-zone --address="https://"${DOCKER_HOST_VALUE}:${VCHPORT} --credentials=${ADMIRALCREDENTIALSID} --accept >> "${LOG_OUTPUT}" 2>&1
       errorcheck ${FUNCNAME}
       logger "default" "VCH $1 succesfully added to Admiral with certificates credentials"
  fi
}

congratulations() {
  # advise users about changes and request a GO
  logger "green" "Congratulations! It took a little bit to download all the pieces but you made it!"
  logger "green" "Your environment is ready to be used now"
  logger "green" "You can connect to *VIC Engine* by pointing your docker client to -H ${DOCKER_HOST_VALUE}:${VCHPORT}"
  logger "green" "You can connect to *Admiral* by pointing your browser to http://${DOCKER_HOST_VALUE}:${ADMIRALEXTERNALPORT}"
  logger "green" "You can connect to *Harbor* by pointing your browser to http://${HARBORVMIP}"
  logger "green" "Enjoy!"
}

main() {
  clearanceToGo

  checkrequirements curl
  checkrequirements grep
  checkrequirements sed
  checkrequirements tar
  checkrequirements unzip
  checkrequirements docker
  checkrequirements ovftool

  checkOsType
  setTlsOptions

  checkHarborOva
  extractHarborOva
  importHarborOva # <- Note: this function is not idempotent

  getVicBinaries
  extractVicBinaries
  deployVch # <- Note: this function is not idempotent (there is no --force option to accept the thumbprint and the current function fails to "ls" as-is)
  grabVchIp

  pullImage nginx ${DOCKER_HOST_VALUE}
  instantiateNetMappingImage nginx ${DOCKER_HOST_VALUE} 80 80 mynginx

  pullImage vmware/admiral ${DOCKER_HOST_VALUE}
  instantiateNetMappingImage vmware/admiral ${DOCKER_HOST_VALUE} ${ADMIRALEXTERNALPORT} 8282 admiral
  sleep 20 #admiral takes a few seconds to come up (sleeping for 20)

  getAdmiralCli
  configAdmiralCli ${DOCKER_HOST_VALUE} ${ADMIRALEXTERNALPORT}
  addHostAdmiral ${VCHNAME} ${DOCKER_HOST_VALUE} ${VCHPORT}

  congratulations
  }

main
