#!/usr/bin/env bash

# stop immediately if any process returns non-zero exit code
set -e

# Make sure only root can run our script
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root."
   exit 1
fi

# add redis package to apt
echo "Adding Redis package to apt..."
pushd /etc/apt/sources.list.d/
if [ ! -f ./dotdeb.org.list ]; then
  touch ./dotdeb.org.list
  echo "deb http://packages.dotdeb.org wheezy all" >> ./dotdeb.org.list
  echo "deb-src http://packages.dotdeb.org wheezy all" >> ./dotdeb.org.list
fi
wget -q -O - http://www.dotdeb.org/dotdeb.gpg | apt-key add -
popd

# add rabbit package to apt
echo "Adding Rabbit package to apt..."
pushd /etc/apt/sources.list.d/
if [ ! -f ./rabbitmq.com.list ]; then
  touch ./rabbitmq.com.list
  echo "deb http://www.rabbitmq.com/debian/ testing main" >> ./rabbitmq.com.list
fi
wget -q -O - http://www.rabbitmq.com/rabbitmq-signing-key-public.asc | apt-key add -
popd

# update apt and install packages
apt-get update
apt-get install -y build-essential openssl htop curl make vim nautilus-open-terminal git gitk redis-server rabbitmq-server

# enable rabbit admin console on port 15672 and restart
rabbitmq-plugins enable rabbitmq_management
service rabbitmq-server restart

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
