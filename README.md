Phoenix Servers with Ansible
============================

This is the demo code for [Phoenix Servers with Ansible: or How I Learned to Stop Worrying and Love
 DNS](https://docs.google.com/presentation/d/e/2PACX-1vTWYKZ1BDMMzfY4gz5uelKpJpmhU8eDWAhPQR5PgcIdCuzELA0-q1xLT4DBXNdIMZ9wI6_SlaG5L835/pub?start=false&loop=false&delayms=3000).

Presentation
----------------------

Slides for the presentation can be found 
[here](https://docs.google.com/presentation/d/e/2PACX-1vTWYKZ1BDMMzfY4gz5uelKpJpmhU8eDWAhPQR5PgcIdCuzELA0-q1xLT4DBXNdIMZ9wI6_SlaG5L835/pub?start=false&loop=false&delayms=3000).

Running the Demo
----------------------

### Prerequisites

To run the demo, you'll need the following things:
- AWS account set up
- [AWS cli tools](https://docs.aws.amazon.com/cli/latest/userguide/installing.html) configured, including AWS access keys
- [Terraform](https://www.terraform.io/intro/getting-started/install.html) installed

_**NOTE**: The networking setup includes a managed NAT Gateway, which is not eligible for the AWS Free Tier. 
As of 09/2018, NAT Gateway pricing runs $0.045/hr (~$33/mo), plus data processing & transfer costs._

### SSH Keypair

You'll need to manually set up an AWS key pair in the **US-east-2** region (Ohio), where all servers will be created, 
with the name "phoenix". Create & download the private key, then generate the public key for it.   

On OSX or Linux:

```bash
ssh-keygen -f phoenix.pem -y > phoenix.pub
``` 

**Note:** if you want to use a different SSH key name, or if your SSH keys are located somewhere other than `~/.ssh/`, 
you'll need to specify the correct values in:
- the Terraform vars file: `terraform/terraform.tfvars` 
- the `ssh_key_folder` and `ssh_key_name` variables in `group_vars/all`

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

Use this IP address, along with username `ubuntu` and the SSH key to access the bastion host, e.g.: 
```
Host bastion
    HostName=18.188.137.189
    User=ubuntu
    IdentityFile=~/.ssh/phoenix.pem
```

Log into the bastion host, go into the `ansible-dns` folder, and run `bootstrap.sh` to complete the setup of the 
bastion host and the central DNS server.
```bash
cd ansible-dns
./bootstrap.sh
``` 

Finally, log out and back in to the bastion host to ensure that you're using the updated settings.  

#### Provisioning & Configuration of DNS servers
 
Now you're ready to set up the new DNS servers!
 
Run the `provision_dns.sh` script to provision primary and secondary DNS servers for each location:
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
