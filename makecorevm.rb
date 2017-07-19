#!/usr/local/bin/ruby

# example usage
#./makecorevm.rb -o [Vcenter Host] -k -u [user] --folder [folder] -D [datacenter] -p [password] -i [CIDR] -n [nameserver] -g [gateway] -c [cloud yml] [vmname]

require 'trollop'
require 'rbvmomi'
require 'rbvmomi/trollop'
require 'base64'

VIM = RbVmomi::VIM

######### Specify name of coreos VMware template https://coreos.com/os/docs/latest/booting-on-vmware.html
template_name = 'coreos_production_vmware_ova'

######### Trollup options #########
opts = Trollop.options do
  banner <<-EOS
Create a VM.

Usage:
    create_vm.rb [options]

VIM connection options:
    EOS

    rbvmomi_connection_opts

    text <<-EOS

VM location options:
    EOS

    rbvmomi_datacenter_opt
    rbvmomi_folder_opt

    text <<-EOS

Other options:
  EOS

  opt :list_vms, "List all vms in specified folder"
  opt :ip, "CIDR ip address to give VM (eg. 10.0.0.1/24)", :type => String, :required => true
  opt :config, "Your cloud config yaml", :type => String, :required => true
  opt :gw, "The default gateway to give the VM", :type => String, :required => true
  opt :dns, "The dns server to give the VM", :type => String, :required => true
  opt :pool, "The resource pool to use", :type => String, :required => true

end

Trollop.die("must specify vSphere hostname") unless opts[:host]
Trollop.die("must specify ip for vm (eg. 10.0.0.1/24)") unless opts[:ip]
Trollop.die("must specify cloudconfig file") unless opts[:config]
Trollop.die("must specify default gw for vm") unless opts[:gw]
Trollop.die("must specify domain name server for vm") unless opts[:dns]
Trollop.die("must specify resource pool") unless opts[:pool]
VM_name = ARGV[0] or abort "must specify VM name"


######### These 2 lines connect to the vsphere and get the datacenter object ########
vim = VIM.connect opts
DC = vim.serviceInstance.find_datacenter(opts[:datacenter]) or abort "datacenter not found"


######### Routine to get the resource pool name.  #########
def find_pool(poolName)
  base_entity = DC.hostFolder
  entity_array = poolName.split('/')
  entity_array.each do |entityArrItem|
    next if entityArrItem == ''
    if base_entity.is_a? RbVmomi::VIM::Folder
      base_entity = base_entity.childEntity.find { |f| f.name == entityArrItem } ||
                    abort("no such pool #{poolName} while looking for #{entityArrItem}")
    elsif base_entity.is_a?(RbVmomi::VIM::ClusterComputeResource) || base_entity.is_a?(RbVmomi::VIM::ComputeResource)
      base_entity = base_entity.resourcePool.resourcePool.find { |f| f.name == entityArrItem } ||
                    abort("no such pool #{poolName} while looking for #{entityArrItem}")
    elsif base_entity.is_a? RbVmomi::VIM::ResourcePool
      base_entity = base_entity.resourcePool.find { |f| f.name == entityArrItem } ||
                    abort("no such pool #{poolName} while looking for #{entityArrItem}")
    else
      abort "Unexpected Object type encountered #{base_entity.type} while finding resourcePool"
    end
  end

  base_entity = base_entity.resourcePool if !base_entity.is_a?(RbVmomi::VIM::ResourcePool) && base_entity.respond_to?(:resourcePool)
  base_entity
end


######### These 2 lines find the folder as specified with --folder and set it to vmFolder #########
root_vm_folder = DC.vmFolder
vmFolder = root_vm_folder.traverse(opts[:folder], VIM::Folder)


######### Find the template #########
Template=vim.serviceInstance.find_datacenter.find_vm(template_name) or abort ("Template " + template_name + " Not Found!")

######### Define spec #########
rspec_pool = find_pool(opts[:pool])
relocateSpec = VIM.VirtualMachineRelocateSpec(:pool => rspec_pool)

Spec = VIM.VirtualMachineCloneSpec(
  :location => relocateSpec,
  :powerOn => false,
  :template => false)


######## clone from template coreos_production_vmware_ova #########
task = Template.CloneVM_Task(:folder => vmFolder, :name => VM_name, :spec => Spec).wait_for_completion
puts "creating " + VM_name +  "..."


######### Find the VM you just created and call it NewVM #########
children = vmFolder.children.find_all
children.each do |child|
  if child.name == VM_name
    NewVM = child
  end
end

puts VM_name + " created. Sending custom config..."

######### base64 encode the cloudconfig into a giant string #########
encoded_string = Base64.strict_encode64(File.open(opts[:config]).to_a.join)

######### Define hash with guestinfo params #########
Guestinfo = Hash.new
Guestinfo["guestinfo.hostname"] = VM_name
Guestinfo["guestinfo.interface.0.route.0.destination"] = "0.0.0.0/0"
Guestinfo["guestinfo.interface.0.route.0.gateway"] = opts[:gw]
Guestinfo["guestinfo.dns.server.0"] = opts[:dns]
Guestinfo["guestinfo.interface.0.dhcp"] = "no"
Guestinfo["guestinfo.interface.0.role"] = "private"
Guestinfo["guestinfo.coreos.config.data.encoding"] = "base64"
Guestinfo["guestinfo.interface.0.name"] = "ens192"
Guestinfo["guestinfo.interface.0.ip.0.address"] = opts[:ip]
Guestinfo["guestinfo.coreos.config.data"] = encoded_string


######### Pump the guestinfo params into the new vm #########
Guestinfo.each do |key, value|
  extraConfig = [{ :key => key, :value => value}]
  NewVM.ReconfigVM_Task(:spec => VIM.VirtualMachineConfigSpec(:extraConfig => extraConfig)).wait_for_completion
end


######### Power on the new vm #########
NewVM.PowerOnVM_Task.wait_for_completion


######### The option --list_vms has nothing to do with this script but dealing with folders using rbvmomi is painful #########
######### so leaving this as an example #########
def list_vms(folder)
  children = folder.children.find_all
  children.each do |child|
    if child.class == VIM::VirtualMachine
      puts child.name
    elsif child.class == VIM::Folder
      list_vms(child)
    end
  end
end

if opts[:list_vms]
  # list all vms in the folder specified with --folders
  list_vms(vmFolder)
end


