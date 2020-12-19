# miq-assignment
miq-assignment


Case study:
Create a VPC (192.168.1.0/24) with 2 subnets  (192.168.1.0/25 and 192.168.1.128/25) in any region. Make one Subnet as Private and other one as Public. Add 2 instances, one in Public and one in Private. Then, create a docker nginx container with ‘HELLO DOCKER’ content in the Private Instance and that docker container should be accessible with a Load Balancer URL.
The Above scenario needs to be automated. Make use of Terraform and Ansible. 


Solution:

Please find the "miq_test" folder in this repo, it includes a 'modules' dir which has terraform codes and 'resource' dir which has terraform veriables and their values mentioned.

To run this code:
step1: go to the 'resource' dir and run 'terraform init'
step2: run 'terraform plan -var-file="miq-test.tfvars" '
step3: run 'terraform apply -var-file="miq-test.tfvars" '

Please open the aws console and hit the DNS name eg. miq-test-123223.us-west-1.elb.amazonaws.com


NOTE: I am using terraform version 0.13.5
