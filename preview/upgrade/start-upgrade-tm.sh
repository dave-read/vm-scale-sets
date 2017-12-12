#!/usr/bin/env bash

RG=$1
BASE=$2
IMAGE_RG=$3
IMAGE_NEW_VERSION=$4
VMSS1=$BASE-vmss1
VMSS2=$BASE-vmss2

if ! [ $RG ] || ! [ $BASE ] || ! [ $IMAGE_RG ] || ! [ $IMAGE_NEW_VERSION ]; then 
  echo "USAGE: script <rg> <base> <image_rg> <image_new_version>"
  exit
fi

TM=$BASE-tm
delay=125
IMAGE_NAME=CentosCustom74-CI

SUB=$(az account show --query id 2>&1)
if [ ! $? -eq 0 ]; then
   echo "Error getting subscription:$SUB"
   exit 1
fi
SUB=$(echo -n $SUB | tr -d '"')

echo "Using subscription:$SUB"
NEW_IMAGE="/subscriptions/$SUB/resourceGroups/$IMAGE_RG/providers/Microsoft.Compute/images/${IMAGE_NAME}_${IMAGE_NEW_VERSION}"

echo "About to update $VMSS1 and $VMSS2 to $NEW_IMAGE via traffic manager $TM"

# disable endpoint1 in TM
echo "Disabling Endpoin1 in $TM"
az network traffic-manager endpoint update --resource-group $RG --name Endpoint1 --profile-name $TM --type azureEndpoints --set endpointStatus="Disabled"
echo "Wait for $delay seconds"
sleep $delay

echo "starting rolling upgrade to image: $NEW_IMAGE in $VMSS1"
az vmss update \
--name $VMSS1 \
--resource-group $RG \
--set virtualMachineProfile.storageProfile.imageReference.id=$NEW_IMAGE \
--no-wait

code="In progress"
while [ "$code" != "\"Completed\"" ]
do
   code=$(az vmss rolling-upgrade get-latest --name $VMSS1 --resource-group $RG | jq '.runningStatus.code')
   #echo "code is $code"
   sleep 5   
done

echo "rolling upgrade to image $NEW_IMAGE in $VMSS1 complete"

echo "Enabling Endpoin1 in $TM"
az network traffic-manager endpoint update --resource-group $RG --name Endpoint1 --profile-name $TM --type azureEndpoints --set endpointStatus="Enabled"

#  disable endpoint2 in TM
echo "Disabling Endpoin2 in $TM"
az network traffic-manager endpoint update --resource-group $RG --name Endpoint2 --profile-name $TM --type azureEndpoints --set endpointStatus="Disabled"
echo "Wait for $delay seconds"
sleep $delay

echo "starting rolling upgrade to image: $NEW_IMAGE in $VMSS2"
az vmss update \
--name $VMSS2 \
--resource-group $RG \
--set virtualMachineProfile.storageProfile.imageReference.id=$NEW_IMAGE \
--no-wait

code="In progress"
while [ "$code" != "\"Completed\"" ]
do
   code=$(az vmss rolling-upgrade get-latest --name $VMSS1 --resource-group $RG | jq '.runningStatus.code')
   #echo "status $?"
   sleep 5
done
echo "rolling upgrade to image $NEW_IMAGE in $VMSS2 complete"

echo "Enabling Endpoin2 in $TM"
az network traffic-manager endpoint update --resource-group $RG --name Endpoint2 --profile-name $TM --type azureEndpoints --set endpointStatus="Enabled"
