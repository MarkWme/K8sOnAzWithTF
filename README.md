# K8sOnAzWithTF
## Kubernetes on Azure with Terraform
### or
## Kubernetes the Terraform Way

This is a personal attempt at two things

1. Deepen my knowledge of Kubernetes
2. Gain more experience with Terraform

And so, I'm going to try and follow through Kelsey Hightower's excellent **Kubernetes the Hard Way** and create Terraform scripts to deploy the whole thing to Azure.

Let's see how this goes 😉

-----

#### Terraform Setup

Using a Terraform configuration which uses an Azure backend so that state is kept in an Azure Storage account and secrets are in Azure Key Vault.

#### cfssl
brew install cfssl

#### kubectl

curl -o kubectl https://storage.googleapis.com/kubernetes-release/release/v1.10.2/bin/darwin/amd64/kubectl

chmod +x kubectl

sudo mv kubectl /usr/local/bin/

#### Network

Virtual network, subnet, public IP and NSG's. Default inbound / outbound and deny all are created automatically, just added HTTPS (6443) and SSH (22). KTHW suggests ICMP, but doesn't look like Azure allows that.

#### Compute

Standard_D1_v2 equivalent to gcloud's n1-standard-1
