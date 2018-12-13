# aws-iot-raspian-provisioner

Provisions an AWS IoT Thing, Certificate, and Policy using the `templates/iot-policy.template` file. 

Downloads the latest Raspbian Stretch Lite image, copies your certificates onto the image, as well as a convenience script to use the aws-iot-device-sdk-python samples to get you started.

Finally, enables ssh on the Raspbian image, and copies a wpa_supplicant.conf file onto the image to allow a headless setup of Wifi connectivity on your Raspberry Pi.

By default, this repo provides a `wpa_supplicant.conf.template` file, which you will need to copy to `templates/wpa_supplicant.conf` with your credentials, prior to running the provisioning script. 

This process will not work from OSX due to lack of support for the EXT4 Linux Filesystem. As a result, this entire process was built using AWS Cloud9.

When ready, simply run `./provision.sh`

After the process successfully completes, you can download the *-raspbian-stretch-lite.img file from the raspbian directory, and flash it onto an SD card.

When the Raspberry Pi boots up, simply navigate to the `/home/pi/aws-iot` directory, and execute `./start.sh`