# CoreCloner
A simple ruby image with a script to build customized CoreOS VMs from template

## Description

The CoreOS VM Backdoor allows you to inject guestinfo config after cloning a VM to customize host config.  This includes injecting an encoded cloud-config file which will, basically, let you customize the host however you want.  

This docker image includes a script (and all you need to run it) that uses rbvmomi to clone such a VM and inject your custom config.

## HowTO

~~~
git clone https://github.com/mmoore0011/CoreCloner.git
~~~
Edit cloud-config.yml
~~~
docker build .
docker run [IMAGE] /scripts/makecorevm.rb -o [VSphere Host] -k -u [USER] [--folder [FOLDER]] -D [DATACENTER] -p [PASSWORD] -i [IP] -g [GATEWAY] -n [NAMESERVER] --pool [RESOURCE POOL] --config [CLOUD CONFIG YML] [GUEST NAME]
~~~

For flexibility I used a lot of command-line options, which can always be scripted.  Note that you MUST create a cloud-config for the script to use unless you wat to just clone mindless copies of CoreOS

