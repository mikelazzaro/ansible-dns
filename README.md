Phoenix Servers with Ansible
============================

This is the demo code for [Phoenix Servers with Ansible: or How I Learned to Stop Worrying and Love
 DNS](https://docs.google.com/presentation/d/1qA5vXhKMeg2iOgg4lIYN6OTwpa46EzXhr70U1a05Z0g/edit?usp=sharing).

Presentation
----------------------

Slides for the presentation can be found 
[here](https://docs.google.com/presentation/d/1qA5vXhKMeg2iOgg4lIYN6OTwpa46EzXhr70U1a05Z0g/edit?usp=sharing).

Running the Demo
----------------------

### Prerequisites

To run the demo, you'll need the following things:
- AWS account set up
- [AWS cli tools](https://docs.aws.amazon.com/cli/latest/userguide/installing.html) configured, including AWS access keys
- [Terraform](https://www.terraform.io/intro/getting-started/install.html) installed

_**NOTE**: The networking setup includes a managed NAT Gateway, which is not eligible for the AWS Free Tier. 
As of 09/2018, NAT Gateway pricing runs $0.045/hr (~$33/mo), plus data processing & transfer costs._

### SSH Keypairs

You'll need to manually set up an AWS key pair in the **US-east-2** region (Ohio), where all servers will be created, 
with the name "phoenix". Create & download the private key, then generate the public key for it.   

On OSX or Linux:

```bash
ssh-keygen -f phoenix.pem -y > phoenix.pub
``` 

**Note:** if you want to use a different SSH key name, or if your SSH keys are located somewhere other than `~/.ssh/`, 
you'll need to specify the correct values in:
- the Terraform vars file: `terraform/terraform.tfvars` 
- the "ansible_private_key_file" variable in `group_vars/all`

### Environment Setup

Use Terraform to set up networking & core servers (bastion host & central-dns01).
```bash
cd terraform
terraform apply
```

Once Terraform finishes, pull the IP address of the bastion host from the output:
```
Outputs:

bastion_ip = 18.188.137.189
```

You'll use this IP address, along with username `ubuntu` and the `human.pem` key to access the bastion host, e.g.: 
```
Host bastion
    HostName=18.188.137.189
    User=ubuntu
    IdentityFile=~/.ssh/human.pem
```

Log into the bastion host, go into the `ansible-dns` folder, and run `bootstrap.sh` to complete the setup of the 
bastion host and the central DNS server.
```bash
cd ansible-dns
./bootstrap.sh
``` 

Finally, log out and back in to the bastion host to ensure that you're using the updated settings.  

#### Template Setup 

While not strictly required in AWS, this is necessary in our current on-prem environment, where we're starting 
from the Ubuntu 16.04 installation media. After the basic installation process and networking setup is complete,
a minimal set of manual steps are needed to allow Ansible to take over. This includes:
- Setting up an `ansible` user account
- Granting `ansible` passwordless sudo privileges
- Allowing login as `ansible` using the `ansible.pem` key 

Provision a new Ubuntu 16.04 instance as the starting point for the template by running the provisioning script:
```bash
./provision_template.sh
```

It may take a minute or two after the script finishes for the instance to finish initializing. 

Log into the template server, using the pre-configured setup from the SSH config file:
```bash
ssh template
``` 

First, create the new ansible user:
```bash
sudo adduser --system --shell /bin/bash --group --gecos 'Ansible automation user' --disabled-password ansible
``` 

Next, open visudo to update the `ansible` user's sudo rights:
```bash
sudo EDITOR=vim visudo -f /etc/sudoers.d/50-ansible
```

Add the following line, then save and close:
```
ansible ALL=(ALL) NOPASSWD:ALL
```

Lastly, switch over to the `ansible` user, create a `.ssh` folder, and paste the contents of ansible.pub 
into `~/.ssh/authorized_keys`:
```
ubuntu@ip-10-0-0-99:~$ sudo su - ansible
ansible@ip-10-0-0-99:~$ mkdir .ssh
ansible@ip-10-0-0-99:~$ vi ~/.ssh/authorized_keys
``` 

Disconnect from the template, and confirm that things are working by logging in again using the 
Ansible credentials:
```bash
ssh template-ansible
```

Create an AMI from the template, and make a note of the ID, since you'll need it for the next section. 

Finally, terminate the template server:
```bash
./terminate_template.sh
```

#### Provisioning & Configuration of DNS servers
 
Finally, you're ready to set up the DNS servers!
 
Run the `provision_dns.sh` script to provision primary and secondary DNS servers for each remote environment:
```bash
./provision_dns.sh
```

Finally, to set up and configure the DNS servers, run the `configure_dns_server.yml` playbook:

```bash
ansible-playbook -i hosts configure_dns_server.yml
```


#### Rebuilding DNS servers

To perform a complete rebuild of the DNS servers, simply run the `terminate_dns.sh` script, following by the 
provisioning and configuration steps above.

#### Zero-Downtime Updates

Since the configuration scripts carry a potential risk of downtime (e.g. if a reboot is required), you can 
perform a zero-downtime update by updating the secondary servers first: 

```bash
ansible-playbook -i hosts configure_dns_servers.yml --limit secondary
```

followed by the primaries:

```bash
ansible-playbook -i hosts configure_dns_servers.yml --limit primary
```

### Teardown

To clean up and remove all the resources used by the demo: 

- Terminate DNS servers via the `terminate_dns.sh` script
    - Note: if you've switched between branches, run the termination script from the `complete` branch to make 
    sure all DNS servers are removed
    ```bash
    ./terminate_dns.sh
    ```
- Deregister the template AMI via the EC2 console
- Delete any remaining snapshots in the EC2 console 
- From your local environment, use terraform to destroy the infrastructure
    ```bash
    terraform destroy
    ```

Alternate Branches
----------------------

This repo includes several branches that include different versions of the DNS server configuration playbooks.

- **master** - basic version of scripts
- **extras** - includes expanded testing, and various other added features
- **test-servers** - includes support for testing environments
- **complete** - everything from **extras** and **test-servers**

### Using an alternate branch

All aspects of the demo other than the local DNS server configuration (such as the networking, or the bastion host 
setup) are identical across all branches.

To use the scripts from an alternate branch, simply terminate the existing DNS servers, check out the new branch, 
and re-run the provisioning and configuration steps:

```bash
./terminate_dns.sh
git checkout extras
./provision_dns.sh
ansible-playbook -i hosts configure_dns_servers.yml
```


