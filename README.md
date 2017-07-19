# CoreCloner
A simple ruby image with a script to build customized CoreOS VMs from template

## Description

The CoreOS VM Backdoor allows you to inject guestinfo config after cloning a VM to customize host config.  This includes injecting an encoded cloud-config file which will, basically, let you customize the host however you want.  

This docker image includes a script (and all you need to run it) that uses rbvmomi to clone such a VM and inject your custom config.

## HowTO
1.  Download a CoreOS VMware OVA and import it as a template into your datecenter
  https://coreos.com/os/docs/latest/booting-on-vmware.html#booting-with-vmware-esxi
~~~
git clone https://github.com/mmoore0011/CoreCloner.git
~~~
Edit cloud-config.yml
~~~
docker build .
docker run [IMAGE] /scripts/makecorevm.rb -o [VSphere Host] -k -u [USER] [--folder [FOLDER]] -D [DATACENTER] -p [PASSWORD] -i [IP] -g [GATEWAY] -n [NAMESERVER] --pool [RESOURCE POOL] --config [CLOUD CONFIG YML] [GUEST NAME]
~~~

For flexibility I used a lot of command-line options, which can always be scripted.  Note that you must create a cloud-config for the script to use unless you wat to just clone mindless copies of CoreOS

## References
#### CoreOS instructions
https://coreos.com/os/docs/latest/booting-on-vmware.html

#### Another practical example of doing something similar with powershell...  much thanks to Robert Labrie for showing that this is possible
https://robertlabrie.wordpress.com/2015/09/27/coreos-on-vmware-using-vmware-guestinfo-api/
