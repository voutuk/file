#!/bin/bash
cd /home/ubuntu

# Update package lists and install dependencies
sudo apt-get update && sudo apt-get install -y ca-certificates curl gnupg
sudo curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
NODE_MAJOR=20
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | sudo tee /etc/apt/sources.list.d/nodesource.list
sudo apt-get update && sudo apt-get install nodejs -y

# Clone Ogar3 repository and install dependencies
sudo git clone https://github.com/Faris90/Ogar3.git
cd Ogar3
sudo npm install

# Start the application directly with Node.js

cd Ogar3
sudo node index.js
