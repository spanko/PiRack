# Revisiting the PiRack project and breathing new life into it

I'm now taking one of the pi's and configuring it to sit across all of my VLANs, or at least those that have distinct egress points configured.  

Generally, the plan is:
- Enable VLAN on the Rpi
- Configure the VLANs to reflect what I have setup on my router and switch
- Create a docker network for each VLAN
- Build out multiple docker-compose.yml files - one for each vlan - for speedtest
- Deploy a speedtest container on each VLAN so I can get regulard speedtests on each WAN (I have 3)
- Fgure out how to aggregate and report on that data

#Enabling Vlan usage
```
sudo apt-get install vlan
sudo su -c 'echo "8021q" >> /etc/modules
```
Now you are vlan-enabled, let's do something with it.  Here I'm assuming we're using the default Ubuntu network manager.

# Use Netplan for durable vlan definitions
Edit /etc/netplan/50-cloud-init.yaml and add the following for vlans using DHCP
```
network:
  version: 2
  ethernets:
    eth0:
      dhcp4: true
  vlans:
    vlan20:
      id: 20
      link: eth0
      dhcp4: false
    vlan40:
      id: 40
      link: eth0
      dhcp4: true
```
# Now setup the Docker network
```
sudo docker network create -d macvlan /
--subnet=192.168.40.0/24 /
--gateway=192.168.40.1 /
-o parent=vlan40   docker_40
```
There is a LOT of complexity here, but I ended up with this simple network creation and pushed more complexity to the container

# Spin up a container on that network with docker-compose
```
   services:
     speedtest-tracker:
       cap_add:
         - NET_ADMIN
       image: lscr.io/linuxserver/speedtest-tracker:latest
       container_name: speedtest-tracker-vlan40
       networks:
         vlan40_docker:
           ipv4_address: 192.168.40.4
       dns:
         - 8.8.8.8
         - 1.1.1.1
       environment:
         - PUID=1000
         - PGID=1000
         - TZ=America/Denver
         - APP_KEY=
         - APP_URL=
         - DB_CONNECTION=sqlite
         - SPEEDTEST_SCHEDULE=*/5 * * * *
         - SPEEDTEST_SERVERS= # Run sudo docker run -it --rm --entrypoint /bin/bash lscr.io/linuxserver/speedtest-tracker:latest list-servers
         - DB_HOST= #optional
         - DB_PORT= #optional
         - DB_DATABASE= #optional
         - DB_USERNAME= #optional
         - DB_PASSWORD= #optional
         - DISPLAY_TIMEZONE=America/Denver #optional
         - PRUNE_RESULTS_OLDER_THAN=0
       volumes:
         - /home/spanko/docker-volumes/speedtest40/data:/config
       ports:
         - 8080:80
         - 8443:443
       restart: unless-stopped
   
   networks:
     vlan40_docker:
       external: true
         name: docker_40
```
# Now reserve 192.168.40.4 in the DHCP server for this vlan
I start all my ranges at 10 so I have room for a few IPs like this
![image](https://github.com/user-attachments/assets/02d8d120-bb4d-422b-86bb-6a501c7c7439)

You'll need the MAC address from the container, going to the container terminal and running ip addr is an easy way to get it

#References
Vlan prep: https://tom-henderson.github.io/2019/04/12/ubuntu-vlan-config.html
Speedtest: https://hub.docker.com/r/linuxserver/speedtest-tracker 
