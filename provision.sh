#!/bin/bash

set -x

sudo yum install -y epel-release jq

mkdir raspbian
mkdir cli-output
mkdir certificates

ACCOUNT_ID=$(aws sts get-caller-identity | jq -r '.Account')
THING_NAME=another-test-thing
IOT_ENDPOINT=$(aws iot describe-endpoint --endpoint-type iot:Data-ATS | jq -r '.endpointAddress')

aws iot create-thing --thing-name $THING_NAME > cli-output/create-thing-result.json

aws iot create-keys-and-certificate --set-as-active \
  --certificate-pem-outfile "certificates/${THING_NAME}.cert.pem" \
  --public-key-outfile "certificates/${THING_NAME}.public.key" \
  --private-key-outfile "certificates/${THING_NAME}.private.key" \
  > cli-output/create-keys-and-certificate-result.json


sed 's/{{account-id}}/'"$ACCOUNT_ID"'/g' templates/iot-policy.template > templates/iot-policy.json
aws iot create-policy \
  --policy-name "${THING_NAME}-Policy" \
  --policy-document file://templates/iot-policy.json \
  > cli-output/create-policy-result.json

  
aws iot attach-policy \
  --policy-name "${THING_NAME}-Policy" \
  --target $(cat cli-output/create-keys-and-certificate-result.json | jq -r '.certificateArn') \
  > cli-output/attach-policy-result.json

  
aws iot attach-thing-principal \
  --thing-name $THING_NAME \
  --principal $(cat cli-output/create-keys-and-certificate-result.json | jq -r '.certificateArn') \
  > cli-output/attach-thing-principal-result.json



curl -o raspbian/raspbian_lite_latest.zip -L https://downloads.raspberrypi.org/raspbian_lite_latest  
unzip raspbian/raspbian_lite_latest.zip -d ./raspbian


sudo losetup -P /dev/loop0 raspbian/*-raspbian-stretch-lite.img
sudo mount /dev/loop0p2 /mnt
sudo mount /dev/loop0p1 /mnt/boot

sudo mkdir -p /mnt/home/pi/aws-iot/
sudo cp certificates/"${THING_NAME}.cert.pem" /mnt/home/pi/aws-iot/
sudo cp certificates/"${THING_NAME}.public.key" /mnt/home/pi/aws-iot/
sudo cp certificates/"${THING_NAME}.private.key" /mnt/home/pi/aws-iot/

sed 's/{{aws-iot-endpoint}}/'"$IOT_ENDPOINT"'/g' templates/start.sh.template > templates/start.sh
sed -i 's/{{thing-name}}/'"$THING_NAME"'/g' templates/start.sh
sudo cp templates/start.sh /mnt/home/pi/aws-iot/

sudo cp templates/aws-iot.service /mnt/etc/systemd/system/

sudo chmod +x /mnt/home/pi/aws-iot/start.sh
sudo chown -R 1000:1000 /mnt/home/pi/aws-iot/  
sudo chown -R 1000 /mnt/usr/local/lib/python2.7
sudo chown root:root /mnt/etc/systemd/system/aws-iot.service 

sudo touch /mnt/boot/ssh
sudo cp templates/wpa_supplicant.conf /mnt/boot/wpa_supplicant.conf

sudo umount /mnt
sudo umount /mnt/boot

set +x