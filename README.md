# ls_assesment

### Stack:

2 Debian PRX VM's 

node-app Docker image built and pushed to repo.

K3s for orchestration

Ingress-nginx as proxy/LB

Ansible for provisioning

## Dependancies:

`kubectl` - [Install Kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/)

`ansible` - [Install Ansible](https://docs.ansible.com/projects/ansible/latest/installation_guide/installation_distros.html)

## Prerequisites
- Adjust the ssh user and auth according to your environment in `ansible/inventory/prod/group_vars/all.yml`. In this setup it is assumed both server and worker nodes share the same ssh user and keys, and that the user has root privileges on the host machine.
- Set the **LAN IP** of k3s server/worker(s) in `ansible/inventory/prod/hosts.yml`. 

## Provisioning

- Provision k3s server
  ```
  ansible-playbook -i ansible/inventory/prod ansible/site.yml --limit server1
  ```
  _Note: Take note of the k3s_token, this is required for worker nodes._
  
- install ingress-nginx
  ```
  kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.1.2/deploy/static/provider/cloud/deploy.yaml --kubeconfig=ansible/k3s_config
  ```
- Wait around 120s for nginx controller to come up. Otherwise you will receive this error `no endpoints available for service "ingress-nginx-controller-admission"`

- Apply orchestration manifests
  ```
  kubectl apply -f k3s/app.yaml --kubeconfig=ansible/k3s_config
  ```
### TLDR:

  ```
  bash ansible/provision.sh
  ```
  WebApp should now be listening on: http://server_ip

### Optional: Provision worker node
- set `k3s_token` in  `ansible/inventory/prod/group_vars/k3s_workers.yml`
- Run the playbook
  ```
  ansible-playbook -i inventory/prod site.yml --limit worker1
  ```
- Scale `node-app` deployment
  ```
  kubectl scale deployment node-app --replicas 6 --kubeconfig=ansible/k3s_config
  ```
  New replicas should now provision on worker nodes.

### Cleanup:
server - `sudo /usr/local/bin/k3s-uninstall.sh`
 
worker - `sudo /usr/local/bin/k3s-agent-uninstall.sh`


### TODO:
- Add provision script for workers
- Add process to build and push image
- ArgoCD to manage manifests
- Get k3s_token automatically (no manual steps for worker nodes)
- Terraform to provision the VMs maybe?
- Add taints/tolerations to put nginx on its own node pool
- Use ansible vault for secrets
- HTTPS + TLS headers for nginx incl set ciphers
- CSP Headers
- fix rate limit status code
- variable management needs improving
- Add network policy to allow ingress to only send to nginx
- Add podsecurity policy to harden pod permissions
