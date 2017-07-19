# CoreCloner
A container for building customized CoreOS VMs from template

## Description

The VM Backdoor allows you to inject CoreOS guestinfo config after cloning a VM to customize host config.  This includes an encoded cloud-config file which will basically let you customize the host however you want.  

This docker image includes a script (makecorevm.rb) that uses rbvmomi to clone such a VM and inject your custom config.

## HowTO
1.  Download a CoreOS VMware OVA and import it as a template into your datecenter
  https://coreos.com/os/docs/latest/booting-on-vmware.html#booting-with-vmware-esxi

2.  Pull down this repo:
~~~
git clone https://github.com/mmoore0011/CoreCloner.git
~~~

3.  Edit cloud-config.yml to suit your needs
https://coreos.com/os/docs/latest/cloud-config.html

4.  Build and run:
~~~
docker build .
docker run [IMAGE] /scripts/makecorevm.rb -o [VSphere Host] -k -u [USER] [--folder [FOLDER]] -D [DATACENTER] -p [PASSWORD] -i [IP/BITS] -g [GATEWAY] -n [NAMESERVER] --pool [RESOURCE POOL] --config [CLOUD CONFIG YML] [GUEST NAME]
~~~

For flexibility I used a lot of command-line options, which can always be scripted.  Note that you must create a cloud-config for the script to use unless you want to just clone mindless copies of CoreOS

## Troubleshooting
- If the VM gets cloned properly and comes up without a config, you probably have invalid guestconfig parameters.  Check the following:
1.  Get into a shell on the console (append coreos.autologin to grub line) 

https://coreos.com/os/docs/latest/other-settings.html#adding-custom-kernel-boot-options

2. sudo coreos-cloudinit --from-vmware-guestinfo

- A common cause is not specifying the ip correcly on the command line.  Note that you have to specify the CIDR.  Eg.  10.0.0.1/24


## References
#### CoreOS instructions
https://coreos.com/os/docs/latest/booting-on-vmware.html

#### Another practical example of doing something similar with powershell...  much thanks to @robertlabrie for showing that this is possible
https://robertlabrie.wordpress.com/2015/09/27/coreos-on-vmware-using-vmware-guestinfo-api/

#### More helpful info
https://blog.kingj.net/2016/04/10/how-to/using-vmwares-guestinfo-interface-to-configure-cloud-config-on-a-coreos-vm/
