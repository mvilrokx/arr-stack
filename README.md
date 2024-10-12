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

After you run the script, run the following commands to change permissions:

```shell
sudo chown -R docker:users /volume1/data /volume1/docker
sudo chmod -R a=,a+rX,u+w,g+w /volume1/data /volume1/docker
```

> You will have to run these 2 commands every time you add a folder (e.g. when you add a new *arr app)

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

Make sure you setup categories:
https://trash-guides.info/Downloaders/qBittorrent/How-to-add-categories/

## Configure Prowlarr

1. Add indexes (see https://www.synoforum.com/resources/ultimate-starter-page-2-jellyfin-jellyseerr-nzbget-torrents-and-arr-media-library-stack.185/
)
1. Add Applications (Radarr, Sonarr ...)

## Configure Radarr, Sonarr. Readarr and Lidarr

1. Add Download Client (qBittorent) in Settings
1. Add the "Root Folder" in [Media Management](http://192.168.19.69:7878/settings/mediamanagement) in Settings

## Configure Bazarr (Subtitles)

https://wiki.bazarr.media/Getting-Started/Setup-Guide/

## Plex

Go to plex.tv/claim and login with your account, copy the claim code and add it "claim-xxxxxxxxxxxxxxxxxxxx". When starting the new plex server for the first time, the server will be added to your account.

## Homepage

In order for Homepage's auto-discovery to work I had to make a few changes.

First I had to add (or uncomment) the following in Homepage's `docker.yaml` file:

```yaml
my-docker:
  socket: /var/run/docker.sock
```

I also had to comment everything else out in  Homepage's `services.yaml` file.

Finally, make sure you have the correct labels and `- /var/run/docker.sock:/var/run/docker.sock:ro` in volumes for Homepage.

See [here](https://gethomepage.dev/configs/docker/#using-docker-socket-proxy) for more details.

## Start

```shell
sudo docker-compose up -d
```

This Docker-compose command helps builds the image, then creates and starts Docker containers. The containers are from the services specified in the compose file. If the containers are already running and you run docker-compose up, it recreates the container.

## Stop

```shell
sudo docker-compose down
``` 

This Docker-compose down command also stops Docker containers like the stop command does. But it goes the extra mile. Docker-compose down, doesn’t just stop the containers, it also removes them.

## Clean

```shell
sudo docker system prune -a --volumes --force
``` 

Remove all unused containers, networks, images (both dangling and unreferenced), and optionally, volumes.

## Setup Domain Names for LAN

You'll need to point all requests for your domain names you want to use, to the synology's IP address. This will hit synology's reverse proxy, which you then need to configure to foreward these requests to the proper service. Since I have a Firewalla, the first part is done on there, as Custom DNS Rules in Services, but it can be done of course on any DNS service (PiHole, AdGuard Home ...). The second part you do on the Synology NAS, in the Control Panel, go to the Login Portal, select the Advanced tab and then the Reverse Proxy button. Create an entry for each service, using the domain name you entered in your DNS, and point it to the port on which your dockerized service is available. Assuming the default ports for your Services and an IP address of `192.168.0.10` for your Synology, it would look like this:

```plaintext
   ┌──Firewalla─────────────────────────────────────────┐      ┌──Synology──────────────────────────────────────────────────────────┐                 
   │                                                    │      │                                                                    │                 
   │                                                    │      │                                                                    │                 
   │  ┌──Custom─DNS─Rules────────────────────────────┐  │      │  ┌──Reverse─Proxy────────────────────────────┐     ┌──Docker────┐  │                 
   │  │                                              │  │      │  │                                           │     │            │  │                 
   │  │                                              │  │      │  │                                           │     │            │  │                 
   │  │  https://plex.nas.lan      ──► 192.168.0.10  │  │      │  │ plex.nas.lan:443      ──► localhost:32400 ├─────► Plex       │  │                 
   │  │                                              │  │      │  │                                           │     │            │  │                 
   │  │  https://portainer.nas.lan ──► 192.168.0.10  │  │ ───► │  │ portainer.nas.lan:443 ──► localhost:9000  ├─────► Portainer  │  │                 
   │  │                                              │  │      │  │                                           │     │            │  │                 
   │  │  https://homepage.nas.lan  ──► 192.168.0.10  │  │      │  │ homepage.nas.lan:443  ──► localhost:3000  ├─────► Homepage   │  │                 
   │  │                                              │  │      │  │                                           │     │            │  │                 
   │  └──────────────────────────────────────────────┘  │      │  └───────────────────────────────────────────┘     └────────────┘  │                 
   │                                                    │      │                                                                    │                 
   └────────────────────────────────────────────────────┘      └────────────────────────────────────────────────────────────────────┘                 
```

Just keep adding entries as you extend your Services.

> I could not find a way to do this in bulk so each entry was made manually, in both the Firewalla software as in the Synology one.

## Enable SSL

In order to enable ssl (https) for all services, we are going to get a wildcard certificate for our domain (`*.vilrokx.com`), which we can then use on Synology for all our subdomains that use `vilrokx.com`

> Note that this requires that you have a public domain name that you need to register at a registrar, but we are not going to make anything publically available nor are we going to open up any ports. We are going to use [Let's Encrypt's DNS-01 challenge](https://letsencrypt.org/docs/challenge-types/#dns-01-challenge) and the APIs from our registrar.

We are going to use a script called [acme.sh](https://github.com/acmesh-official/acme.sh), which was specially developed to do this DNS-01 challenge and then we are going to use a 3rd party deploy plugin for Synology DSM from that same repo to deploy the certificates. Finally we will create a Task in the DSM Tadk Scheduler to retrieve and deploy a new certificate at a regular interval in order to avoid issues with expired certificates (Let's Encrypt certificates are only valid for 3 months)

Create a user in Synology DSM.

Log into your Synology device, click Control Panel, click User & Group, and click Create. I used `certadmin` as the username and give the user a good description. Make sure the user is a member of the `administrators` group and the `http` group. The `certadmin` user only needs Read/Write access to the `homes` folder and you can deny access to all applications. Once the user has been created go back to the Control Panel home and click Terminal & SNMP. Check Enable SSH service and click apply.

Now ssh into your Synology with this user:

```shell
ssh certadmin@YOURHOSTorIPADDRESS
```

Follow the [git installation steps for acme.sh](https://github.com/acmesh-official/acme.sh?tab=readme-ov-file#2-or-install-from-git). Since my synology box did not come with crontab setup, I got an error which can be circumvented (as per the error message) by adding the `--force` flag, so the command for me was `./acme.sh --install --force -m mvilrokx@gmail.com`

Once installed, you need an API Token from your registrar that this script will use to update your DNS entries (for the DNS-01 challenge). You also need to know the Zone ID of your domain, which you shuold be able to find on your domain dashboard at your registrar. Since I am using Cloudflare as my registrar, I basically just follow [this guide](https://github.com/acmesh-official/acme.sh/wiki/dnsapi#dns_cf). However, this page has insteructions for many many more registrars, so just follow your's instructions to [get your first certificate](https://github.com/acmesh-official/acme.sh/wiki/dnsapi#getting-a-certificate). One change I had to make to this command was pick Let's Encrypt as the certificate server since acme.sh uses another provider as default, so my command looked like this:

```shell
./acme.sh --server letsencrypt --issue --dns dns_cf -d '*.vilrokx.com'
```

[This blog post](https://dr-b.io/post/Synology-DSM-7-with-Lets-Encrypt-and-DNS-Challenge) was very helpful in getting this all to work properly.

Now that we have a certificate, we need to deploy it to our Synology to start using it. This is performed by a 3rd party plugin specifically for Synology, which you can find [here](https://github.com/acmesh-official/acme.sh/blob/master/deploy/synology_dsm.sh). From the comments in this script you can see that this requires some additional environment variables to be set:

```shell
export SYNO_USERNAME="certadmin"
export SYNO_PASSWORD="YOUR CERTADMIN PASSWORD"
export SYNO_CERTIFICATE="Let's Encrypt"
export SYNO_CREATE=1
```

We are now ready to deploy our certificate:

```shell
./acme.sh -d '*.vilrokx.com' --deploy --deploy-hook synology_dsm
```

> If you have 2FA enabled (which I think is the default for admin users, which certadmin is), you might first have to enable this in UI, and then add an additional environment variable `export SYNO_DEVICE_NAME="CertRenewal"`. Just make sure that you can login to the DSM UI with `certadmin`. This will force you to setup 2FA for that user. Once I did this, I was able to run the deploy hook without it asking for 2FA again.

Finally, you need to enable this certificate for all your applications, so go to Control Panel -> Security -> Certificate and select your newly added Let's Encrypt certificate. Then click on Settings and add the certificate to all your Services (that end with `vilrokx.com`).

Now we can create a Task that will run regularly to update the certificate (you do not have to set the certificate again against each Services, these settings are persisted when renewing the cert)

> Note that you only have to "renew" the certificate, this will automatically run the deploy-hook you created earlier as well and deploy the new certificate to DSM.

Go to the Control Panel and Task Scheduler. Click Create and select Scheduled Task and User-defined Script. Give the task a descriptive name and make sure `certadmin` is the selected user. Schedule the task to occur every day (Let's Encrypt is smart enough to not issue a new certificate if not required) and enter the user-defined script in the Task Settings tab. In my case I used the following:

```shell
/var/services/homes/certadmin/acme.sh/acme.sh --renew -d "*.vilrokx.com" --server letsencrypt
```

## Enable Tailscale DNS Splitting

In order to be able to access all devices on your network without having to install tailscale on all of those devices, you need to enable the Subnet Router on Tailscale on the device on which you did install Tailscale. In my case, that device is the Synology NAS. 

Make sure you are connected to your Tailscale network, then open Tailscale on your Synology. It should show your Devices and Settings. Under settings you can Advertise new routes. Enter a subnet in CIDR notation to make all those IP addresses available on the Tailscale network. In my case, my IP addresses are 192.168.19.x, which I can represent as a CIDR block with 192.168.19.0/24. After advertising these, you will need to _approve_ this range in the Tailscale Admin Webpage. Go to your [list of machines](https://login.tailscale.com/admin/machines), and you should see a "subnet" tag under your synology (or whichever devices is advertising your IP range). Go to the 3 dots and select "Edit route settings...". You should see subnet and you should be able to approve it (Select the checkbox). 

Now we need to make some changes to the tailscale DNS, so go to your [tailscale DNS settings](https://login.tailscale.com/admin/dns). First we will add a Global nameserver, pick Cloudflare Public DNS (I am actually not 100% sure this is required). This guarantees that all devices on the tailscale network will use this as their DNS. Then you want to set "Override local DNS". Finally you need to add a Custom Nameserver. Add your local DNS server's IP address as the nameserver. For me, this is my Firewalla, so I set it to `192.168.19.1`.  Then you need to enable Split DNS by enabling Restrict to domain, and set the domain to your local domain name, in my case `nas.lan`. This will route all request to `nas.lan` through the local DNS server (`192.168.19.1`), and since this was setup earlier to forward e.g. `plex.nas.lan` to my synology reverse proxy, that is what will happen. the reverse proxy will then forward this to the correct service and port (also setup earlier). So this now allows you to access your services with the same domain name from Tailscale or on your LAN locally.


This [video](https://www.youtube.com/watch?v=Uzcs97XcxiE&ab_channel=KTZSystems) was very helpful.

## Adding Users

Tell your users to install Tailscale and Plex
Invite users to your Plex and Tailscale network
Tell users to accept the Plex and Tailscale invite and finish creating their account

When users login to their Tailscale account, the should be presented with (at least) 2 network options: their own tailscale network and the one you invited them to (mvilrokx@gmail.com tailscale), tell them to pick the latter.

Go to Overseerr's [Users](https://overseerr.nas.lan/users) and Import Plex Users


## Resources
* https://www.synoforum.com/resources/ultimate-starter-page-2-jellyfin-jellyseerr-nzbget-torrents-and-arr-media-library-stack.185/
* https://github.com/TechHutTV/homelab/blob/main/media/arr-compose.yaml
* https://github.com/qdm12/gluetun-wiki/blob/main/setup/providers/mullvad.md
* https://trash-guides.info/Hardlinks/How-to-setup-for/Synology/
* https://yams.media/
* https://mullvad.net/en/account/wireguard-config
* https://dr-b.io/post/Synology-DSM-7-with-Lets-Encrypt-and-DNS-Challenge