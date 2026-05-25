# https://github.com/jtroo/kanata/blob/main/docs/setup-linux.md

# 1
sudo groupadd --system -f uinput

# 2
sudo usermod -aG input "$USER"
sudo usermod -aG uinput "$USER"

# 3
sudo tee /etc/udev/rules.d/99-input.rules > /dev/null <<EOF
KERNEL=="uinput", MODE="0660", GROUP="uinput", OPTIONS+="static_node=uinput"
EOF

# 4
sudo udevadm control --reload-rules
sudo modprobe uinput
sudo udevadm trigger
