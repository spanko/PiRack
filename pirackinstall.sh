sudo mkdir home/spanko/source
sudo mkdir home/spanko/source/repos
cd /home/spanko/source/repos
sudo git clone https://github.com/UCTRONICS/U6143_ssd1306.git

sudo apt install make
sudo apt install gcc

cd /source/repos/U6143_ssd1306
sudo make

# Now make it work at startup
# Assume lcdservice.service file has been copied from /storage/share on 192.168.1.169
# to /etc/systemd/system

sudo chmod 744 /home/spanko/source/repos/U6143_ssd1306/C/display

sudo chmod 664 /etc/systemd/system/lcdservice.service

sudo systemctl daemon-reload
sudo systemctl enable lcdservice.service
