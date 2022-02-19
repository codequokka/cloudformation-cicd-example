Cloudformation CI/CD example
============================

[![Check CFn templates](https://github.com/codequokka/cloudformation-cicd-example/actions/workflows/check.yml/badge.svg)](https://github.com/codequokka/cloudformation-cicd-example/actions/workflows/check.yml)
[![Deploy CFn templates](https://github.com/codequokka/cloudformation-cicd-example/actions/workflows/deploy.yml/badge.svg)](https://github.com/codequokka/cloudformation-cicd-example/actions/workflows/deploy.yml)

## An example of AWS cloudfomation CI/CD with Github Actions

Templates
---------
### Overview
|Template|Stack|Description|
|--------|-----|-----------|
|[initial.yml](cfn/templates/initial.yml)|InitialStack|Create a role for Github Actions CD.|
|[kms.yml](cfn/templates/kms.yml)|KMSStack|Create key for common usage.|
|[config.yml](cfn/templates/config.yml)|ConfigStack|Enable Config service.|
|[cloudtrail.yml](cfn/templates/cloudtrail.yml)|CloudtrailStack|Enable Cloudtrail service.|
|[guardduty.yml](cfn/templates/guardduty.yml)|GuarddutyStack|Enable Guardduty service.|
|[vpc.yml](cfn/templates/vpc.yml)|VPCStack|Create network related resources(VPC, IGW, Subnets, Routetables, EIP, NATGW).|
|[ec2.yml](cfn/templates/ec2.yml)|EC2Stack|Create EC2 instances.|
|[ssm-patchmanager.yml](cfn/templates/ssm-patchmanager.yml)|SSMPatchmanagerStack|Enable SSM Patch manager.|


### Resouces created by templates
- initial.yml  
![initial.yml](./docs/imgs/drawio/initial.png)

- kms.yml
![](./docs/imgs/kms.jpg?raw=true "KMS")

- config.yml
![](./docs/imgs/config.jpg?raw=true "Config")

- cloudtrail.yml
![](./docs/imgs/cloudtrail.jpg?raw=true "Cloudtrail")

- guardduty.yml
![](./docs/imgs/guardduty.jpg?raw=true "Guardduty")

- vpc.yml
![](./docs/imgs/vpc.jpg?raw=true "VPC")

- ec2.yml
![](./docs/imgs/ec2.jpg?raw=true "EC2")

- ssm-patchmanager.yml
![](./docs/imgs/ssm-patchmanager.jpg?raw=true "SSM Patch Manager")

Usage
-----
### Before starting CI/CD
- Deploy the initial.yml template manually to create an IAM role to deploy templates by Github Actions.
```
$ aws cloudformation deploy --stack-name InitialStack --template-file cfn/templates/initial.yml 
```
- Set Github Actions secrets AWS_ACCOUNTID to your account id(Ex. 123456789012)

### CI
- Check templates with cfn-lint, cfn-nag by Github Actions.[(check.yml)](.github/workflows/check.yml)
- When you push a commit to a branch other than the master branch, Github Actions will run cfn-lint, cfn-nag against the templates.
- Click a button to show the check workflow results.
[![Check CFn templates](https://github.com/codequokka/cloudformation-cicd-example/actions/workflows/check.yml/badge.svg)](https://github.com/codequokka/cloudformation-cicd-example/actions/workflows/check.yml)

### CD
- Deploy templates to your AWS environment by Github Actions.[(deploy.yml)](.github/workflows/deploy.yml)
- When you commit to the master branch or merge a pull request into the master branch, Github Actions will apply the templates.
- Click a button to show the deploy workflow results.
[![Deploy CFn templates](https://github.com/codequokka/cloudformation-cicd-example/actions/workflows/deploy.yml/badge.svg)](https://github.com/codequokka/cloudformation-cicd-example/actions/workflows/deploy.yml)