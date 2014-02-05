#!/usr/bin/env bash

# stop immediately if any process returns non-zero exit code
set -e

# add redis package to apt
pushd /etc/apt/sources.list.d/
if [ ! -f ./dotdeb.org.list ]; then
  echo "Adding Redis package to apt..."
  echo "deb http://packages.dotdeb.org wheezy all" | sudo tee -a ./dotdeb.org.list > /dev/null
  echo "deb-src http://packages.dotdeb.org wheezy all" | sudo tee -a ./dotdeb.org.list > /dev/null
fi
wget -q -O - http://www.dotdeb.org/dotdeb.gpg | sudo apt-key add -
popd

# add rabbit package to apt
pushd /etc/apt/sources.list.d/
if [ ! -f ./rabbitmq.com.list ]; then
  echo "Adding Rabbit package to apt..."
  echo "deb http://www.rabbitmq.com/debian/ testing main" | sudo tee -a ./rabbitmq.com.list > /dev/null
fi
wget -q -O - http://www.rabbitmq.com/rabbitmq-signing-key-public.asc | sudo apt-key add -
popd

# update apt and install packages
sudo apt-get update
sudo apt-get install -y build-essential openssl htop curl make vim nautilus-open-terminal git gitk redis-server rabbitmq-server

# enable rabbit admin console on port 15672 and restart
sudo rabbitmq-plugins enable rabbitmq_management
sudo service rabbitmq-server restart

# workers will write logs to /var/log, make sure they have access
sudo chmod 777 /var/log

if [ ! -d ~/.nvm ]; then
  # monkey-patch .profile so nvm doesn't cause infinite login loop when it's sourced
  echo -e "\nreturn" >> ~/.profile

  # install nvm (node version manager)
  wget -qO- https://raw.github.com/creationix/nvm/master/install.sh | sh
  source ~/.nvm/nvm.sh && echo -e "\n. ~/.nvm/nvm.sh" >> ~/.bashrc
fi

# install the newest nodejs 0.10.x and set it as the default nodejs
nvm install 0.10 && nvm alias default 0.10

# install coffee-script globally
npm install -g coffee-script
npm install -g coffeelint

# install the other dependencies of the code locally
npm install

echo "Setup done. Please close and reopen your terminal session to apply the changes to your bashrc file."
