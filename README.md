# Phoenix Servers with Ansible

This is the demo code for "Phoenix Servers with Ansible: or How I Learned to Stop Worrying and Love DNS", by Mike Lazzaro.

## Presentation

Slides for the presentation can be found [here](https://docs.google.com/presentation/d/1qA5vXhKMeg2iOgg4lIYN6OTwpa46EzXhr70U1a05Z0g/edit?usp=sharing).

(TODO)

## Branches

1. master - basic setup
1. extras - includes expanded testing, and various other features
1. test-servers - includes support for testing environments
1. complete - everything from extras and test-servers

## Setup Instructions
 
(TODO: Clean this up!)

Prerequisites:

1. AWS account set up
1. [AWS cli tools](https://docs.aws.amazon.com/cli/latest/userguide/installing.html) set up, including AWS access keys
1. [Terraform](https://www.terraform.io/intro/getting-started/install.html) installed

Manual setup:

1. Create 2 new AWS keypairs, named "human" and "ansible"
1. Generate the public key for the "ansible" keypair (suitable for use in authorized_keys)

Usage:

1. Use Terraform to set up networking & core servers (bastion host & central-dns01)
1. Pull bastion host IP address from terraform output
1. Log into bastion host
1. Switch into repo folder and run bootstrap script
1. Provision template
1. Manual setup of template
1. Take snapshot of template
1. Terminate template
1. Update group_vars/all with id of template AMI
1. Provision DNS servers (via script)
1. Run DNS server config playbooks

Teardown:

1. Terminate DNS servers (via script)
1. Deregister template AMI
1. Run Terraform destroy

