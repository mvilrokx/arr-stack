# Setup *arr stack

## Install VS Code Server

https://code.visualstudio.com/docs/remote/ssh

This makes it easier to edit files on your Synology in VS Code

> In order to get this to work I had to set `AllowTcpForwarding` in `/etc/ssh/sshd_config` on the Synology to `yes` (it is set to `no` by default) for my user (`mvilrokx`)

```shell
vi /etc/ssh/sshd_config
```

Add the following to the bottom of this file (replace `mvilrokx` with your username):

```
Match User mvilrokx
	AllowTcpForwarding yes
```

Safe the file and restart SSH (disable in DSM, and then re-enable)

## Prepare Synology
I basically followed [this guide](https://trash-guides.info/Hardlinks/How-to-setup-for/Synology/), specifically:

* [Install Docker](https://trash-guides.info/Hardlinks/How-to-setup-for/Synology/#install-docker)
* [Create the main share](https://trash-guides.info/Hardlinks/How-to-setup-for/Synology/#create-the-main-share)
* [Create a user](https://trash-guides.info/Hardlinks/How-to-setup-for/Synology/#create-a-user)
* [SSH](https://trash-guides.info/Hardlinks/How-to-setup-for/Synology/#ssh)
* [Create Folder Structure](https://trash-guides.info/Hardlinks/How-to-setup-for/Synology/#create-folder-structure)

For the last step, I created a shell script called `directories.sh` that you can run.

### Enable Wireguard
From https://www.blackvoid.club/wireguard-spk-for-your-synology-nas/

run the following commands (for DSM 7.2):

```
mkdir /volume1/docker/synowirespk72
sudo docker run --rm --privileged --env PACKAGE_ARCH=geminilake --env DSM_VER=7.2 -v /volume1/docker/synowirespk72:/result_spk blackvoidclub/synobuild72
```

Then follow the rest of the guide ("Install and start the Wireguard SPK")

## Start

```shell
sudo docker-compose up -d
```

## Verify your VPN
```shell
sudo docker run --rm --network=container:gluetun alpine:3.20 sh -c "apk add wget && wget -qO- https://ipinfo.io"
```

+

https://ipleak.net/

## Configure qBittorent
Change download installation to `/data/torrents` (or whatever folders you created earlier in the setup)

Tools -> Options -> Downloads -> Default Save Path: /data/torrents
Tools -> Options -> Downloads -> Monitored Folder: /data/watch