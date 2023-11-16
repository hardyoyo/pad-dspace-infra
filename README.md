# pad-dspace-infra: CDL DSpace Devops tools
A collection of devops scripts and configs, useful for deploying DSpace to AWS.

Inpsired by the amazing https://github.com/cdlib/web-matomo

# Overview

This is a multi-stack Sceptre project that uses Docker and AWS services to
deploy a frontend, backend, and Solr service. The combination of these services
provides CDL with a DSpace instance. The project includes individual templates 
for each stack, and uses Sceptre to manage the infrastructure as code.

Remember: Sceptre is for infrastructure, build.sh is for pushing images into ECR.

## Stacks
The project includes the following stacks:

* **frontend**: Creates a container to run the frontend service for the project.
* **backend**: Creates a container to run the backend service for the project.
* **solr**: Creates a container to run Solr for use with the project.

Each stack has its own Docker image, which is built and deployed to AWS ECR
using the [build.sh](build.sh) script.

# Getting Started

To get started with the project, you'll need to have Python and Docker installed
on your system. You'll also need to have an AWS account and credentials set up.

Once you have the prerequisites installed and set up, you can use the build.sh 
script to build and deploy the Docker images to AWS ECR. You can then use 
Sceptre to deploy and manage the infrastructure on AWS.

## Deploying a Single Stack

```bash
sceptre launch-env <stack_name>
```
For example, to deploy the Solr stack, you can use the following command:
```bash
sceptre launch-env solr
```

This will create the necessary AWS resources for the Solr stack, including an 
AWS ECR repository for the Docker image and an ECS service to run the container.

## Deploying All Stacks

To deploy all the stacks in the project, you can use the following command:

```bash
sceptre launch-all
```

This will create the necessary AWS resources for all the stacks in the project, 
including AWS ECR repositories for the Docker images and ECS services to run the
containers.

Note that you'll need to have the necessary AWS credentials set up in your 
environment for these commands to work.

For more information on how to use the project, please refer to the 
documentation in the docs folder.


## TLDR
* Clone this directory on your local machine and cd to it
* `./setup.sh`
* Set up your AWS credentials to access the cdl-pad-prd account (either by setting up
profiles and doing `export AWS_PROFILE=cdl-pad-prd`, or pasting temporary shell
credentials, or logging in with `aws sso login`).
* `sceptre launch -y .`
* `./build.sh`
* lather, rinse, repeat
