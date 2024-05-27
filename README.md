# tinker-tech

Repo is a project that exists to play with some tech stacks.

## Network and Account Structure

At an AWS level the goal is to do a multi-account setup, using
a hub and spoke network. The hub acting as the egress point for
all accounts as it contains the single NAT.
The hub is the 'network' account in the tofu folder structure.

The single spoke will be the 'apps' account, which will run
an EKS cluster. We'll allocate the EKS pods IPs out of the
non-allocated range. Outbound connections will be routed
via the TGW to the network account.

## Kubernetes stack

Target is an autoscaling cluster using Karpenter & Bottlerocket.
Most likely using managed node groups, and AWS' ALBs for
ingress management.

For actual manifest deployment, something like Argo or Flux will be used.
We need an actual application to deploy first :)

## Applications

Still undecided what to build and deploy. Could do a little python application
to check that the TF is in sync with the deployed resources (a very simple
Atlantis).
