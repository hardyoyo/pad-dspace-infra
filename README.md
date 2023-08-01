# pad-dspace-infra: CDL DSpace Devops tools
A collection of devops scripts and configs, useful for deploying DSpace to AWS.

Borrowed from the amazing https://github.com/cdlib/web-matomo

## Getting started
* Clone this directory on your local machine and cd to it
* `./setup.sh`
* Set up your AWS credentials to access the cdl-pad-prd account (either by setting up
profiles and doing `export AWS_PROFILE=cdl-pad-prd`, or pasting temporary shell
credentials, or logging in with `aws sso login`).
* `sceptre launch -y .`
* `./build.sh`
* lather, rinse, repeat
