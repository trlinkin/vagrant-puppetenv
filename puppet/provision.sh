#!/bin/bash

## Install some prerequisites
yum install -y git
/opt/puppet/bin/gem install r10k

## Use the control repo for bootstrapping
cp -r /vagrant/code/control /tmp/control
cd /tmp/control
git init && git add . && git commit -m "Initial commit"
/opt/puppet/bin/r10k puppetfile install -v

## Run a Puppet apply against the role in the copy of the control repo so we
## can bootstrap
echo "======================================================================"
echo "Applying role::puppet::master"
echo
/opt/puppet/bin/puppet apply -e 'include role::puppet::master' \
  --modulepath=./modules:./site

if [ $? -eq 0 ]; then
  ## So we'll stub out the production environment until our gitlab server
  ## is ready.  We want the other vagrant instances to be able to come up and
  ## do a Puppet run cleanly
  cp -r /tmp/control /etc/puppetlabs/puppet/environments/production

  git --git-dir /etc/puppetlabs/puppet/environments/production/.git \
    --work-tree /etc/puppetlabs/puppet/environments/production remote \
    add cache /var/cache/r10k/git@gitlab.vagrant.vm-puppet-control.git

  /opt/puppet/bin/puppet agent -t

  if [ -f "/root/.ssh/id_rsa.pub" ]; then
    echo "################################################################"
    echo "Copy the following SSH pubkey to your clipboard:"
    echo
    cat /root/.ssh/id_rsa.pub
    echo
    echo "################################################################"
    echo "This key should be added to Gitlab."
  fi
  echo "Now configure the Gitlab server"
else
  echo "The master failed to apply its role."
fi
