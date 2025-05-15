Revisiting the PiRack project and breathing new life into it - I'm now taking one of the pi's and configuring it to sit across all of my VLANs, or at least those that have distinct egress points configured.  
Generally, the plan is:
- Enable VLAN on the Rpi
- Configure the VLANs to reflect what I have setup on my router and switch
- Create a docker network for each VLAN
- Build out multiple docker-compose.yml files - one for each vlan - for speedtest
- Deploy a speedtest container on each VLAN so I can get regulard speedtests on each WAN (I have 3)
- Fgure out how to aggregate and report on that data

#Enabling Vlan usage

'sudo apt-get install vlan'
'sudo su -c 'echo "8021q" >> /etc/modules'

Now you are vlan-enabled, let's do something with it.  Here I'm assuming we're using the default Ubuntu network manager.

# Use Netplan for durable vlan definitions

# Now setup the Docker network
sudo docker network create -d macvlan /
--subnet=192.168.40.0/24 /
--gateway=192.168.40.1 /
-o parent=vlan40   docker_40

There is a LOT of complexity here, but I ended up with this simple network creation and pushed more complexity to the container

# Now setup the container to use DHCP from the vlan


# To use DHCP, you'll need to use dhclient OR for Alpine-based containers the following:

   #!/bin/sh
   apk add --no-cache busybox
   ip addr flush dev eth0
   udhcpc -i eth0

# Spin up a container on that network with docker-compose

   services:
     speedtest-tracker:
       cap_add:
         - NET_ADMIN
       image: lscr.io/linuxserver/speedtest-tracker:latest
       container_name: speedtest-tracker-vlan40
       networks:
         vlan40_docker:
       dns:
         - 8.8.8.8
         - 1.1.1.1
       environment:
         - PUID=1000
         - PGID=1000
         - TZ=America/Denver
         - APP_KEY=3Z531fCaC6Xv28CaYwakJpf6qfxZyV0sV0Dvtwgyvq8=
         - APP_URL=
         - DB_CONNECTION=sqlite
         - SPEEDTEST_SCHEDULE=*/5 * * * *
         - SPEEDTEST_SERVERS= #optional
         - DB_HOST= #optional
         - DB_PORT= #optional
         - DB_DATABASE= #optional
         - DB_USERNAME= #optional
         - DB_PASSWORD= #optional
         - DISPLAY_TIMEZONE=America/Denver #optional
         - PRUNE_RESULTS_OLDER_THAN=0
       volumes:
         - /home/spanko/docker-volumes/speedtest40/data:/config
         - ./dhclient.sh:/etc/local.d/dhclient.sh
       ports:
         - 8080:80
         - 8443:443
       entrypoint: ["/bin/sh", "-c", "/etc/local.d/dhclient.sh && /init"]
       restart: unless-stopped
   
   networks:
     vlan40_docker:
       external:
         name: docker_40

#References
Vlan prep: https://tom-henderson.github.io/2019/04/12/ubuntu-vlan-config.html
Speedtest: https://hub.docker.com/r/linuxserver/speedtest-tracker 
