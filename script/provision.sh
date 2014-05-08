#!/usr/bin/env bash

#base packages
sudo apt-get -y update
sudo apt-get -y install build-essential zlib1g zlib1g-dev libpq-dev curl git-core openssl libssl-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt-dev uuid-dev

#install rvm
\curl -L https://get.rvm.io | bash -s stable
source /usr/local/rvm/scripts/rvm

#install ruby under rvm
rvm install 1.8.7-p302

#fix rvm folder permissions
sudo chown -R vagrant:rvm /usr/local/rvm/
