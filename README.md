# Setup *arr stack

## Install VS Code Server

<https://code.visualstudio.com/docs/remote/ssh>

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

Save the file and restart SSH (disable in DSM, and then re-enable)

## Prepare Synology

I basically followed [this guide](https://trash-guides.info/Hardlinks/How-to-setup-for/Synology/), specifically:

* [Install Docker](https://trash-guides.info/Hardlinks/How-to-setup-for/Synology/#install-docker)
* [Create the main share](https://trash-guides.info/Hardlinks/How-to-setup-for/Synology/#create-the-main-share)
* [Create a user](https://trash-guides.info/Hardlinks/How-to-setup-for/Synology/#create-a-user)
* [SSH](https://trash-guides.info/Hardlinks/How-to-setup-for/Synology/#ssh)
* [Create Folder Structure](https://trash-guides.info/Hardlinks/How-to-setup-for/Synology/#create-folder-structure)

For the last step, I created a shell script called `directories.sh` that you can run (`./directories.sh -h` shows the options).

After you run the script, run the following commands to change permissions:

```shell
sudo chown -R docker:users /volume1/data /volume1/docker
sudo chmod -R a=,a+rX,u+w,g+w /volume1/data /volume1/docker
```

> ⚠️ When you add a folder later (e.g. when you add a new *arr app), run these 2 commands on the new folder only, e.g. `/volume1/docker/appdata/<app>`. `/volume1/docker` can also hold files of other containers, and `a+rX` makes everything in it readable for every user.

## Configure the environment

Copy `.example.env` to `.env`, then fill in the values marked `CHANGE` or `SET`. You get the API keys from each app after its first start.

```shell
cp .example.env .env
```

> `.env` is in `.gitignore`. Never commit it: it holds your VPN key, passwords and API keys.

## Start

```shell
sudo docker-compose up -d
```

This creates and starts the containers for all the services in the compose file. If containers are already running, it only recreates the ones whose configuration or image changed.

> I no longer run this by hand: a container management tool deploys this stack, checks for new images every week and redeploys the services that have one.

## Verify your VPN

qBittorrent uses the network of the gluetun container, so all its traffic goes through the VPN. To see the public IP address that qBittorrent uses:

```shell
sudo docker exec qbittorrent curl -s https://ipinfo.io
```

The result must show your VPN provider, not your own internet provider. To check the torrent client itself for leaks, use the torrent address detection on <https://ipleak.net/>.

## Known issue: qBittorrent is down after a Container Manager restart

qBittorrent uses `network_mode: service:gluetun`, so gluetun must run first. When DSM restarts Container Manager (e.g. after an update), it can start qBittorrent before gluetun, and then qBittorrent fails. gluetun has `restart: always` to make this less likely. If qBittorrent is still down, start gluetun first, then qBittorrent.

## Configure qBittorrent

Change the default download location to `/data/torrents` (or whatever folders you created earlier in the setup):

* Tools -> Options -> Downloads -> Default Save Path: `/data/torrents`
* Tools -> Options -> Downloads -> Monitored Folder: `/data/watch`

Make sure you setup categories:
<https://trash-guides.info/Downloaders/qBittorrent/How-to-add-categories/>

## Configure sabnzbd

<https://trash-guides.info/Downloaders/SABnzbd/Basic-Setup/>

## Configure Prowlarr

1. Add indexers (see <https://www.synoforum.com/resources/ultimate-starter-page-2-jellyfin-jellyseerr-nzbget-torrents-and-arr-media-library-stack.185/>)
1. Add Applications (Radarr, Sonarr ...)

## Configure Radarr, Sonarr and Lidarr

1. Add the Download Clients (qBittorrent, SABnzbd) in Settings -> Download Clients
1. Add the "Root Folder" in Settings -> Media Management

## Configure Bazarr (Subtitles)

<https://wiki.bazarr.media/Getting-Started/Setup-Guide/>

## Plex

Plex is not part of this stack (for reasons). Overseerr and Tautulli connect to an existing Plex server.

## Homepage

In order for Homepage's auto-discovery to work I had to make a few changes.

First I had to add (or uncomment) the following in Homepage's `docker.yaml` file:

```yaml
my-docker:
  socket: /var/run/docker.sock
```

I also had to comment everything else out in Homepage's `services.yaml` file.

Finally, make sure you have the correct labels and `- /var/run/docker.sock:/var/run/docker.sock:ro` in volumes for Homepage.

See [here](https://gethomepage.dev/configs/docker/#using-docker-socket-proxy) for more details.

## Stop

```shell
sudo docker-compose down
```

This stops the containers and also removes them (and the stack's network). Your config and data stay in the appdata and data folders.

## Clean

```shell
sudo docker image prune -a
```

This removes all images that no container uses.

> ⚠️ Do not use `docker system prune -a --volumes` for this. It works on the whole NAS, not only on this stack: it also removes every stopped container (of any stack), all unused networks and unused anonymous volumes.

## Setup Domain Names for LAN

You'll need to point all requests for the domain names you want to use to a reverse proxy, which then forwards each request to the proper service. The first part is done in your local DNS. Since I have a Firewalla, I do this there, as Custom DNS Rules in Services, but it can be done of course on any DNS service (Pi-hole, AdGuard Home ...). The second part you do on the reverse proxy: create an entry for each service, using the domain name you entered in your DNS, and point it to the IP address of the NAS and the port on which your dockerized service is available. It looks like this:

```plaintext
   ┌──Local DNS───────────────────────────────┐      ┌──Reverse Proxy──────────────────────────────┐      ┌──NAS──────┐
   │                                          │      │                                             │      │           │
   │  <app>.example.com  ──► <proxy IP>       │ ───► │  <app>.example.com  ──► <NAS IP>:<port>     │ ───► │  <app>    │
   │                                          │      │                                             │      │           │
   └──────────────────────────────────────────┘      └─────────────────────────────────────────────┘      └───────────┘
```

Just keep adding entries as you extend your Services.

> I could not find a way to do this in bulk on the Firewalla, so each DNS entry was made manually.

If you want to use your Synology NAS itself as the reverse proxy, see the [appendix](#appendix-use-your-synology-nas-as-the-reverse-proxy).

## Enable Tailscale DNS Splitting

In order to be able to access all devices on your network without having to install tailscale on all of those devices, you need to enable the Subnet Router on Tailscale on the device on which you did install Tailscale. In my case, that device is the Synology NAS.

Make sure you are connected to your Tailscale network, then open Tailscale on your Synology. It should show your Devices and Settings. Under settings you can Advertise new routes. Enter a subnet in CIDR notation to make all those IP addresses available on the Tailscale network. For example, if your IP addresses are 192.168.1.x, you can represent them as the CIDR block 192.168.1.0/24. After advertising these, you will need to _approve_ this range in the Tailscale Admin Webpage. Go to your [list of machines](https://login.tailscale.com/admin/machines), and you should see a "subnet" tag under your synology (or whichever device is advertising your IP range). Go to the 3 dots and select "Edit route settings...". You should see subnet and you should be able to approve it (Select the checkbox).

Now we need to make some changes to the tailscale DNS, so go to your [tailscale DNS settings](https://login.tailscale.com/admin/dns). First we will add a Global nameserver, pick Cloudflare Public DNS (I am actually not 100% sure this is required). This guarantees that all devices on the tailscale network will use this as their DNS. Then you want to set "Override local DNS". Finally you need to add a Custom Nameserver. Add your local DNS server's IP address as the nameserver. For me, this is my Firewalla. Then you need to enable Split DNS by enabling Restrict to domain, and set the domain to the domain of your services (e.g. `example.com`). This will route all requests for that domain through your local DNS server, and since this was setup earlier to point e.g. `sonarr.example.com` to the reverse proxy, that is what will happen. The reverse proxy will then forward this to the correct service and port (also setup earlier). So this now allows you to access your services with the same domain name from Tailscale or on your LAN locally.

This [video](https://www.youtube.com/watch?v=Uzcs97XcxiE&ab_channel=KTZSystems) was very helpful.

## Adding Users

* Tell your users to install Tailscale and Plex
* Invite users to your Plex and Tailscale network
* Tell users to accept the Plex and Tailscale invite and finish creating their account

When users login to their Tailscale account, they should be presented with (at least) 2 network options: their own tailscale network and the one you invited them to (your tailscale network), tell them to pick the latter.

In Overseerr, go to Users and click Import Plex Users.

## Enable zsh and oh-my-zsh

<https://3os.org/infrastructure/synology/Install-oh-my-zsh/#change-the-default-shell-to-zsh>

<https://www.reddit.com/r/synology/comments/991lg1/comment/ldxcola/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button>

## Resources

* <https://www.synoforum.com/resources/ultimate-starter-page-2-jellyfin-jellyseerr-nzbget-torrents-and-arr-media-library-stack.185/>
* <https://github.com/TechHutTV/homelab/blob/main/media/arr-compose.yaml>
* <https://github.com/qdm12/gluetun-wiki/blob/main/setup/providers/mullvad.md>
* <https://trash-guides.info/Hardlinks/How-to-setup-for/Synology/>
* <https://yams.media/>
* <https://mullvad.net/en/account/wireguard-config>
* <https://dr-b.io/post/Synology-DSM-7-with-Lets-Encrypt-and-DNS-Challenge>
* <https://www.reddit.com/r/synology/comments/991lg1/comment/ldxcola/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button>
* <https://3os.org/infrastructure/synology/Install-oh-my-zsh/#change-the-default-shell-to-zsh>

## Appendix: Use your Synology NAS as the reverse proxy

I no longer use this, but it works if you want your Synology NAS to be the reverse proxy for your services, instead of a separate one.

### Reverse proxy rules in DSM

In your local DNS, point the domain names of your services to the IP address of the NAS. Then, in DSM, go to Control Panel -> Login Portal -> Advanced -> Reverse Proxy. Create an entry for each service:

* Source: protocol HTTPS, the domain name you entered in your DNS, port 443
* Destination: protocol HTTP, `localhost`, the port on which your dockerized service is available

> I could not find a way to do this in bulk, so each entry was made manually.

### Enable SSL

In order to enable ssl (https) for all services, we are going to get a wildcard certificate for our domain (`*.vilrokx.com`), which we can then use on Synology for all our subdomains that use `vilrokx.com`

> Note that this requires that you have a public domain name that you need to register at a registrar, but we are not going to make anything publicly available nor are we going to open up any ports. We are going to use [Let's Encrypt's DNS-01 challenge](https://letsencrypt.org/docs/challenge-types/#dns-01-challenge) and the APIs from our registrar.

We are going to use a script called [acme.sh](https://github.com/acmesh-official/acme.sh), which was specially developed to do this DNS-01 challenge and then we are going to use a 3rd party deploy plugin for Synology DSM from that same repo to deploy the certificates. Finally we will create a Task in the DSM Task Scheduler to retrieve and deploy a new certificate at a regular interval in order to avoid issues with expired certificates (Let's Encrypt certificates are only valid for 3 months)

Create a user in Synology DSM.

Log into your Synology device, click Control Panel, click User & Group, and click Create. I used `certadmin` as the username and give the user a good description. Make sure the user is a member of the `administrators` group and the `http` group. The `certadmin` user only needs Read/Write access to the `homes` folder and you can deny access to all applications. Once the user has been created go back to the Control Panel home and click Terminal & SNMP. Check Enable SSH service and click apply.

Now ssh into your Synology with this user:

```shell
ssh certadmin@YOURHOSTorIPADDRESS
```

Follow the [git installation steps for acme.sh](https://github.com/acmesh-official/acme.sh?tab=readme-ov-file#2-or-install-from-git). Since my synology box did not come with crontab setup, I got an error which can be circumvented (as per the error message) by adding the `--force` flag, so the command for me was `./acme.sh --install --force -m you@example.com` (use your own email address)

Once installed, you need an API Token from your registrar that this script will use to update your DNS entries (for the DNS-01 challenge). You also need to know the Zone ID of your domain, which you should be able to find on your domain dashboard at your registrar. Since I am using Cloudflare as my registrar, I basically just follow [this guide](https://github.com/acmesh-official/acme.sh/wiki/dnsapi#dns_cf). However, this page has instructions for many many more registrars, so just follow yours to [get your first certificate](https://github.com/acmesh-official/acme.sh/wiki/dnsapi#getting-a-certificate). One change I had to make to this command was pick Let's Encrypt as the certificate server since acme.sh uses another provider as default, so my command looked like this:

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
