# Terraform - ALB with Web Servers

Terraform file configuration that creates an **Application Load Balancer** with two **EC2** Instances, the first pointing to an **NGINX** server and the second one pointing to an **APACHE** server. The other resources were created so that everything functions well and is kept organized.

Reminder: these files use **AWS** as provider.

# File Layout

This section details the content of each file.

## /terraform.tfvars

In this file, all the variables that you need to change for the application to work are present. There's an example file in the repo, you just need to change the values and remove the .example extension.

## /main.tf

In this file, all the settings for the usage of variables, provider and data are defined.

## /networking.tf

In this file, all resources regarding networking setup are created, e.g. VPC, subnets, gateways, etc, along with key-pair to SSH into the instances. **This key-pair should be created and kept safely, as it will allow its owners to enter into the instances.**

## /security_groups.tf

In this file, the security groups for both the ALB and the EC2 instances are configured.

## /application_load_balancer.tf

In this file, the resources for the Application Load Balancer are present. Here, we will find resources such as ALB itself along with its listeners and target groups.


## /instances.tf

In this file, both the NGINX and APACHE instances are being configured. 

## /output.tf

In this file, an output for the `terraform apply` is set. In this case, we are outputting the hostname for the ALB we created.


# Usage

The files are set in a way that only changes to the **terraform.tfvars.example** file is necessary. In it, you should swap the example values for real values and remove the **.example** extension from the file. 

With that set, you need to initialize Terraform by running `terraform init`. Next, you will be able to run a `terraform plan -out=tfplan.out` to check if the resources will be created correctly. As of right now, 17 resources are planned to be created. After that, you can run `terraform apply "tfplan.out"` and wait a little while for the creation of the resources.

When the hostname gets outputted, it's all set!