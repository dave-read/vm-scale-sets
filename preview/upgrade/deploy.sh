#!/usr/bin/env bash

RG=$1
imageResourceGroup=$2
if ! [ $RG ] || ! [ $imageResourceGroup ]; then 
  echo "Specify RG to deploy and RG with custom images"
  exit
fi

LOCATION=centralus
TEMPLATE=custom-image-manualrolling-tm.json

#imageResourceGroup="sk-custom-images"
imageName="CentosCustom74-CI_v1"
cloudInit=$(<cloud-init.txt)
sshKeyData=$(<~/.ssh/id_rsa.pub)

az group create -n $RG -l $LOCATION
az group deployment create \
  --name $RG \
  --resource-group $RG \
  --template-file $TEMPLATE \
  --parameters \
  cloudInit="$cloudInit" \
  sshKeyData="$sshKeyData" \
  imageResourceGroup="$imageResourceGroup" \
  imageName="$imageName" \
  dnsPrefix="$RG" \
  vmssNamePrefix=dr \
  instanceCount=3 \
  adminUsername="az${USER}"