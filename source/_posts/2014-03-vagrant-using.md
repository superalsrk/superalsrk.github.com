---

title: vagrant虚拟机使用
date: 2014-03-28 09:46:55
tags: ['工具']
description: "vagrant是一个用于创建和部署虚拟化开发环境,这篇文章是vagrant的使用教程及一些tips"
keywords: "vagrant,vagrant配置,vagrant目录映射"
toc: true
---

## Vagrant 虚拟机使用 ##

vagrant 是一款用于创建和部署虚拟化开发环境，一般都是用virtualbox做provider的，不过也可以使用其他虚拟机,比如vmware和docker,
有国外大牛做出了这个[vagrant-docker](https://github.com/philspitler/vagrant-docker)项目,就是使用docker作为provider.

## 安装 ##
+ 安装 [VirtualBox-4.3.6-91406-Win.exe](http://download.virtualbox.org/virtualbox/4.3.6/VirtualBox-4.3.6-91406-Win.exe)
+ 安装 [Vagrant_1.4.3.msi](http://966b.http.dal05.cdn.softlayer.net/data-production/1835e881651ac8f27a9e4b815754f1934db71fe6?filename=Vagrant_1.4.3.msi)

## 配置 ##
+ 从[www.vagrantbox.es](http://www.vagrantbox.es/)‎下载虚拟机，我们使用32位的ubuntu版本 [lucid32.box](http://files.vagrantup.com/lucid32.box)(这个是ubuntu10不推荐使用)

+ 将box文件拷贝到计算机的某个文件夹中，msys运行添加虚拟机命令
```bash
$ vagrant box add lucid32 ./lucid32.box
```

+ 创建内容如下的 `Vagrantfile` 文件

```ruby
  # -*- mode: ruby -*-
  # vi: set ft=ruby :

  # Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
  VAGRANTFILE_API_VERSION = "2"

  Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  # All Vagrant configuration is done here. The most common configuration
  # options are documented and commented below. For a complete reference,
  # please see the online documentation at vagrantup.com.

  # Every Vagrant virtual environment requires a box to build off of.
  config.vm.box = "lucid32"

  # The url from where the 'config.vm.box' box will be fetched if it
  # doesn't already exist on the user's system.
  config.vm.box_url = "http://files.vagrantup.com/lucid32.box"

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine. In the example below,
  # accessing "localhost:8080" will access port 80 on the guest machine.
  # config.vm.network :forwarded_port, guest: 80, host: 8080

  # Create a private network, which allows host-only access to the machine
  # using a specific IP.
  # config.vm.network :private_network, ip: "192.168.33.10"

  # Create a public network, which generally matched to bridged network.
  # Bridged networks make the machine appear as another physical device on
  # your network.
  # config.vm.network :public_network

  # If true, then any SSH connections made will enable agent forwarding.
  # Default value: false
  # config.ssh.forward_agent = true

  # Share an additional folder to the guest VM. The first argument is
  # the path on the host to the actual folder. The second argument is
  # the path on the guest to mount the folder. And the optional third
  # argument is a set of non-required options.
  # config.vm.synced_folder "../data", "/vagrant_data"

  # Provider-specific configuration so you can fine-tune various
  # backing providers for Vagrant. These expose provider-specific options.
  # Example for VirtualBox:
  #
  # config.vm.provider :virtualbox do |vb|
  #   # Don't boot with headless mode
  #   vb.gui = true
  #
  #   # Use VBoxManage to customize the VM. For example to change memory:
  #   vb.customize ["modifyvm", :id, "--memory", "1024"]
  # end
  #
  # View the documentation for the provider you're using for more
  # information on available options.

  # Enable provisioning with Puppet stand alone.  Puppet manifests
  # are contained in a directory path relative to this Vagrantfile.
  # You will need to create the manifests directory and a manifest in
  # the file base.pp in the manifests_path directory.
  #
  # An example Puppet manifest to provision the message of the day:
  #
  # # group { "puppet":
  # #   ensure => "present",
  # # }
  # #
  # # File { owner => 0, group => 0, mode => 0644 }
  # #
  # # file { '/etc/motd':
  # #   content => "Welcome to your Vagrant-built virtual machine!
  # #               Managed by Puppet.\n"
  # # }
  #
  # config.vm.provision :puppet do |puppet|
  #   puppet.manifests_path = "manifests"
  #   puppet.manifest_file  = "init.pp"
  # end

  # Enable provisioning with chef solo, specifying a cookbooks path, roles
  # path, and data_bags path (all relative to this Vagrantfile), and adding
  # some recipes and/or roles.
  #
  # config.vm.provision :chef_solo do |chef|
  #   chef.cookbooks_path = "../my-recipes/cookbooks"
  #   chef.roles_path = "../my-recipes/roles"
  #   chef.data_bags_path = "../my-recipes/data_bags"
  #   chef.add_recipe "mysql"
  #   chef.add_role "web"
  #
  #   # You may also specify custom JSON attributes:
  #   chef.json = { :mysql_password => "foo" }
  # end

  $script = %Q{
    sudo apt-get update
    sudo apt-get install nasm make build-essential grub qemu zip -y
  }


  config.vm.provision :shell, :inline => $script


  # Enable provisioning with chef server, specifying the chef server URL,
  # and the path to the validation key (relative to this Vagrantfile).
  #
  # The Opscode Platform uses HTTPS. Substitute your organization for
  # ORGNAME in the URL and validation key.
  #
  # If you have your own Chef Server, use the appropriate URL, which may be
  # HTTP instead of HTTPS depending on your configuration. Also change the
  # validation key to validation.pem.
  #
  # config.vm.provision :chef_client do |chef|
  #   chef.chef_server_url = "https://api.opscode.com/organizations/ORGNAME"
  #   chef.validation_key_path = "ORGNAME-validator.pem"
  # end
  #
  # If you're using the Opscode platform, your validator client is
  # ORGNAME-validator, replacing ORGNAME with your organization name.
  #
  # If you have your own Chef Server, the default validation client name is
  # chef-validator, unless you changed the configuration.
  #
  #   chef.validation_client_name = "ORGNAME-validator"
end
```

+ 进入Vagrantfile的同名目录

```bash
#查看帮助
$ vagrant --help

#启动虚拟机
$ vagrant up

#关闭虚拟机
$ vagrant halt

#ssh连接
$ vagrant ssh

#显示add的所有box
$ vagrant box list

#remove box,第一个参数是box的名称，第二个是provider的名称
$ vagrant box remove precise64 virtualbox

#摧毁一个vm，(在VagrantFile相同文件夹下)，注意与 vagrant box remove的不同
$ vagrant destroy

#也可以通过ssh-client连接，用户名密码都为vagrant,端口为2222
$ ssh -p 2222 vagrant@localhost

```
## 导出Box ##
+ 步骤
    1. cd into the directory with your __Vagrantile__
    2. run `vagrant package`· This will export a box file called package.box by default
    3. run `vagrant box add foo package.box` virtualbox to add package.box to your existing boxes. (Assuming you are using virtualbox and not VMWare)
    4. run `vagrant box list` to verify it was added.


 Now you can just create a new folder, run vagrant init as normal and set your box to the following:`config.vm.box = "foo"`,The new VM will spin up with the exact data that was present in the previous VM.

## 时间同步 ##

把`virtualbox/bin`加入环境变量，运行一下命令，设置时间同步（win下也可）
```bash
#List vms
$ VBoxManage list vms

#get status of time sync
$ VBoxManage getextradata <vm-name> VBoxInternal/Devices/VMMDev/0/Config/GetHostTimeDisabled

#NOTE: Make sure to restart the VM after changing these settings.

#disable time sync
$ VBoxManage setextradata <vm-name> VBoxInternal/Devices/VMMDev/0/Config/GetHostTimeDisabled 1

#enable time sync
$ VBoxManage setextradata <vm-name> VBoxInternal/Devices/VMMDev/0/Config/GetHostTimeDisabled 0


```

## 使用 ##
+ 网络配置
    1.  较为常用是端口映射，就是将虚拟机中的端口映射到宿主机对应的端口直接使用 ，在Vagrantfile中配置：`config.vm.network :forwarded_port, guest: 80, host: 8080`,guest: 80 表示虚拟机中的80端口， host: 8080 表示映射到宿主机的8080端口
    2.  如果需要自己自由的访问虚拟机，但是别人不需要访问虚拟机， ，在Vagrantfile中配置：`config.vm.network :private_network, ip: "192.168.1.104"`,192.168.1.104表示虚拟机的IP，多台虚拟机的话需要互相访问的话，设置在相同网段即可
    3.  如果需要将虚拟机作为当前局域网中的一台计算机，由局域网进行DHCP，那么在Vagrantfile中配置：`config.vm.network :public_network`



+ 目录映射

  虚拟机初始化启动时， host的当前工作目录就会映射到 guest的 `/vagrant` 文件夹下

  也可以通过VagrantFile `config.vm.synced_folder "wwwroot/", "/var/www"` 完成映射配置
  


## 常见问题 ##

+ 找不到rsync命令:  参考 [这个](http://stackoverflow.com/questions/34176041/vagrant-with-virtualbox-on-windows10-rsync-could-not-be-found-on-your-path), 配置文件中加入 `config.vm.synced_folder ".", "/vagrant", type: "virtualbox"` 即可
+ `vagrant up` 的时候私钥错误, 可以暂时删除 `.vagrant/**/private_key.`, 用用户名密码登陆
+ 推荐fedora cloud镜像