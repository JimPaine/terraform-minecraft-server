# Terraform Provisioners Demo
Provisioners allow for a number of things to be executed either remotely or locally when a resource is created, this is really useful for setting up pre-reqs on a new VM. 

While this is not the approach I would take to deploy an application into an environment, it was a great way for me to test out a few of the provisioners.

## Objective
To have a Minecraft Bedrock Server running in Azure and setup as a systemd service

## Approach
As mentioned above, this isn't the way I would tend to deploy applications into an environment and is purely a fun way to demo Terraform Provisioners

## Running it

Clone the repo

```
git clone https://github.com/JimPaine/terraform-minecraft-server.git
```
Log in

```
az login
```

Optionally set a subscription

```
az account set --subscription {id}
```

Navigate to the Terraform scripts

```
cd env
```

```
terraform init
```

Pick your own slightly more secure password and apply

```
terraform apply --auto-approve -var "password=Password1234!"
```

Once it has completed capture the details from the output and add the server to your server list, now you can play away on your own dedicated Minecraft server on both your mobile and your Xbox.

## Recommendations

In /env/nsg.tf I would recommended filtering the ssh rule by your IP address to ensure that it is at least filterd slightly. Even better would to remove the rule all together and re-run the terraform apply command, this way only the Minecraft ports are open. If you do need to get access to the vm add the rule back in and re-run the apply.

In /config there are three files, ops.json, whitelist.json and server.properties. In server.properties I would recommend setting whitelist to true and then adding your uuid and name to both the ops and whitelist files.

ops.json

```
[
    {
      "uuid": "781db3a4-7765-4dd3-bbf1-3d7955e6fc6d",
      "name": "SocklessCoder",
      "level": 4
    }
]
```
whitelist.json

```
[
    {
      "uuid": "781db3a4-7765-4dd3-bbf1-3d7955e6fc6d",
      "name": "SocklessCoder"
    }
]
```

## Gotchas

### Alpha

The Minecraft Bedrock server is still in alpha so be warned anything could happen.

### Shared object dependancy issues
Currently the service needs to know about libCrypto.so which is why on the offical site they recommend you start the service which running

```
LD_LIBRARY_PATH=. ./bedrock_server
```

This caused be all sorts of run when trying to run it from systemd so with a little bit of a fiddle I remotely copy the file /usr/lib and reload the ldconfig, this allows bedrock_server to be aware where the file is without setting LD_LIBRARY_PATH

```
sudo cp /minecraft/libCrypto.so /usr/lib/libCrypto.so
sudo ldconfig -v | grep libCrypto.so
```

### UFW and iptables

I started to use UFW to set the firewall rules but kept hitting issues with not being able to make the enable command run silently, so instead worked directly with iptables.