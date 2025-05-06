# PiRack
Tutorials and info around the UCTRONICS PiRack

I set out to learn more about Kubernetes,  and decided to jump in with 4 Raspberry Pi 4's running Ubuntu 20.04 LTS.  Having one Rpi4 already with this setup, I realized the logistics were going to be ugly - 4 power supplies, 4 slippery cases, no good way to mount them, and HDMI hell during at least initial setup (and the inevitable re-wipe.)
Enter the UCTRONICS Ultimate Rack with PoE: https://smile.amazon.com/gp/product/B0998MXWR6/ref=ppx_yo_dt_b_asin_title_o07_s02?ie=UTF8&psc=1; after pricing out individual PoE hats, this felt like a deal since it solved my mounting issues.  I'm doing this in a new house while renting out my old house where ALL of my equipment (USG Pro, 16 port managed unifi switch, etc...) remained, so I also got an inexpensive 8 port switch to power the PoE Hats (and therefore the Pis.)  Link for the switch: https://smile.amazon.com/gp/product/B07788WK5V/ref=ppx_yo_dt_b_asin_title_o05_s00?ie=UTF8&psc=1.

I got the 4 Pis and went straight to work - and immediately screwed up.  If you are going to use the UNCTRONICS system, you CANNOT INSTALL THE RPi Heatsinks - or at least you can't install the heatsink for the CPU.  This ends up being too tall for the hat to seat properly.  It took me the better part of an hour to assemble the first one (heat sink removal included, obv) but I sped through the other 3, 10 minutes or so on each.  Some tips:

  1)	Trust the fit - it's a solid kit, but these are still PCBs and you'll have to work with them to get everything lined up.  The board dedicated to bringing HDMI to the front         can be a tight fit but OMG you will love it once it is racked up
  2)	Watch the CPU fans - they will sit above the RPi CPU (thus the heat sink fit issue) when everything is in place; in my kit, 2 of the fans had loose nuts and one had a nut         missing, so I tightened all of them.  Someone more anal than I would have had loctite on hand, and I wish I had pulled out my tweezer set to hold the nuts instead of just         fat-fingering it
  3)	The assembled hat will fit into the rack front - work with it until it fully seats, it'll "clunk" a little and then all of the screws will line up.

OK - so you have your pi-rack all mounted, power and LCD cords connected - plug your ethernet patch cables into the Pis and the Switch!  Here's something weird, the power lights on the rack are red and they stay red.  I digress - all 4 of my Pis popped up with no problems.  I used the  raspberry pi imager tool, picked the Ubuntu LTS arm64 image and cycled through making 4 images.  Thanks to Trav for that guidance!

I did the needful to get them all on the network and updated, then wanted to get the LCDs working.  I thought this was going to be brutally difficult - I found the repo here: 
https://github.com/UCTRONICS/U6143_ssd1306/tree/master/C and the first line says

# Enable i2c
 $ sudo raspi-config

Uh... yeah, the thing is, I'm running Ubuntu 20.04 LTS, not any RasPi flavored linux.  I then went on a horrendous series of rabbit-hole adventures which included building CircuitPython until common sense prevailed and I just tried making the C-based app in that repository.  Here is what I did: 

 $ git clone https://github.com/UCTRONICS/U6143_ssd1306.git

# Compile the source code
 
 $ cd U6143_ssd1306/C
 
 $ make 

To successfully make that app I had to also do the following (if you do dev this won't be an issue I expect - these were fresh installs):

 $ sudo apt install make
 
 $ sudo apt install gcc

So now you have an app called "display" in my case in /home/ubuntu//U6143_ssd1306/C - you can run it now interactively and you should see the LCD light up.  Cool!  Then when you exit, the screen stays frozen.  Less cool.

# Make it work at startup!
So - onto systemctl!  Let's make it so that everytime you start-up, this thing works.  There are a couple of steps here - I found the tutorials at LinuxConfig.org wildly helpful (I am not a native linux speaker, I still dream in Windows) and this one was the best: https://linuxconfig.org/how-to-run-script-on-startup-on-ubuntu-20-04-focal-fossa-server-desktop 

Basically, you're going to put a service file in /etc/systemd/system:
 
$ sudo nano /etc/systemd/system/lcdservice.service

In that service file I put:

  [Unit]
  Description=Front Panel LCD
  After=network.service
  
  [Service]
  Type=simple
  RemainAfterExit=yes
  ExecStart= /home/ubuntu/U6143_ssd1306/C/display
  
  [Install]
  WantedBy=default.target

As the tutorial explains, we’re basically saying here "Once you have a network, run the 'display' app we just built."  To make sure this stuff runs (sorry to get so technical there) I did the following b/c the tutorial told me to:

$ sudo chmod 744 /home/ubuntu/U6143_ssd1306/C/display

$ sudo chmod 664 /etc/systemd/system/lcdservice.service

I then ran (also per the tutorial):

$ sudo systemctl daemon-reload

$ sudo systemctl enable lcdservice.service

There is a nice little command I needed b/c I screwed a bunch of stuff up:

$ systemctl status lcdservice.service

This is great, because it will tell you what went wrong.  Like building out the Pi Rack itself, the first one was a debacle and the other three went flawlessly for me.
Anyhow - do a sudo reboot after, and enjoy your up-to-date info on the LCD!

#Add Caching!

I came back to this project and even with RPi imager, there are plenty of apps and modules still needing installation - so I added local caching on my file server.
Key steps:
1) Install apt-cacher-ng
2) CHOWN and CHMOD on the folder you pick for the cache
3) Add apt-cahcer-ng soft nofile 4096 and apt-cacher-ng hard nofile 10240 to /etc/security/limits.conf
4) For all the machines that should participate in caching, create a file called 02proxy in /etc/apt/apt.conf.d - put a line like this in it: 'Acquire::http { Proxy "http://192.168.1.169:3142"; };'
