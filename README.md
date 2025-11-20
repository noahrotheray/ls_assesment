# ls_assesment

### Stack:

Docker image built and pushed to repo.

K3s for orchestration

Ingress-nginx as proxy/LB

Ansible for provisioning

## Dependancies:

`kubectl` - [Install Kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/)

`ansible` - [Install Ansible](https://docs.ansible.com/projects/ansible/latest/installation_guide/installation_distros.html)

## What you need to change
- Adjust the ssh user and auth according to your environment in `ansible/inventory/prod/group_vars/all.yml`. Ansible requires this to ssh to each node and perform the provisioning tasks. In this setup it is assumed both server and worker nodes share the same ssh user and keys.
- If you are not running the stack on localhost, or you intend to add worker nodes, set the LAN IP of k3s server (and worker(s)) in `ansible/inventory/prod/hosts.yml`

## Provisioning

- Provision k3s server
  ```
  ansible-playbook -i ansible/inventory/prod site.yml --limit server1
  ```
  _Note: Take note of the k3s_token, this is required for worker nodes._
  
- install ingress-nginx
  ```
  kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.1.2/deploy/static/provider/cloud/deploy.yaml
  ```
- Wait around 120s for nginx-admission to come up.

- Apply orchestration manifests
  ```
  kubectl apply -f k3s/app.yaml
  ```
### TLDR:

  ```
  bash ansible/provision.sh server1
  ```
  Wepapp is listening on http://localhost

### Optional: Provision worker node
- Set the worker IPs in `ansible/inventory/prod/hosts.yml`
- set `k3s_token` in  `ansible/inventory/prod/group_vars/k3s_workers.yml`
- Run the playbook
 ```
 ansible-playbook -i inventory/prod site.yml --limit worker1
 ```
 ### Cleanup:
 server - `sudo /usr/local/bin/k3s-uninstall.sh`
 
 worker - `sudo /usr/local/bin/k3s-agent-uninstall.sh`


TODO:
- Add provision script for workers
- Add process to build and push image
- ArgoCD to manage manifests
- Get k3s_token automatically (no manual steps for worker nodes)
- Terraform instead of ansible maybe?
- Add rate limiting on nginx
- Add taints to put nginx on its own node pool
