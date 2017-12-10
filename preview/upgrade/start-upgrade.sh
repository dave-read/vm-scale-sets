#!/usr/bin/env bash

VMSS_NAME=dr
VMSS_RG=dr-vmss-upgrade

IMAGE_NAME=CentosCustom7.3
IMAGE_RG=dr-custom-images
IMAGE_NEW_VERSION=v2

SUB=$(az account show --query id 2>&1)
if [ ! $? -eq 0 ]; then
   echo "Error getting subscription:$SUB"
   exit 1
fi
SUB=$(echo -n $SUB | tr -d '"')

echo "Using subscription:$SUB"
NEW_IMAGE="/subscriptions/$SUB/resourceGroups/$IMAGE_RG/providers/Microsoft.Compute/images/${IMAGE_NAME}_${IMAGE_NEW_VERSION}"

echo "starting rolling upgrade to image: $NEW_IMAGE"
az vmss update \
--name $VMSS_NAME \
--resource-group $VMSS_RG \
--set virtualMachineProfile.storageProfile.imageReference.id=$NEW_IMAGE \
--no-wait

if [[ $? -ne 0 ]];then
   echo "Error starting upgrade"
   exit
fi

while true
do
   az vmss rolling-upgrade get-latest --name $VMSS_NAME --resource-group $VMSS_RG
   echo "status $?"
   sleep 1
done
