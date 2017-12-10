#!/usr/bin/env bash
# Copyright (c) Microsoft.  All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#--------------------------------------------------------------------------
VMSS_NAME=dr
VMSS_RG=dr-vmss-upgrade

IMAGE_NAME=CentosCustom74-CI
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
