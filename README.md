# ls_assesment

### Stack:

I used my proxmox lab to run this stack.

Docker image has been built and pushed to sporn/ls_assesment:latest

2 Debian VM's - server1 and worker1

k3s for orchestration

ingress-nginx as proxy/LB

ansible for provisioning

What you need to run this stack

kubectl
ansible

What you need to change
- Add the IPs the k3s server and worker(optional) hosts in  `ls_assesment/ansible/inventory/prod/hosts.yml`
- Adjust the ssh user and auth according to your environment.

Provision stack

- Docker image has been built and pushed to sporn/ls_assesment:latest
- Provision k3s server
  `ansible-playbook -i ansible/inventory/prod site.yml --limit server1`
  Note: Take note of the k3s_token, this is required for worker nodes.
- install ingress-nginx
  `kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.1.2/deploy/static/provider/cloud/deploy.yaml`
- Wait around 90s for nginx-admission to come up.
- Apply orchestration manifests
  `kubectl apply -f k3s/app.yaml`

Optional: Provision worker node
- set `k3s_token` to server1's token, 
 `ansible-playbook -i inventory/prod site.yml --limit worker1`


sudo /usr/local/bin/k3s-uninstall.sh
sudo /usr/local/bin/k3s-agent-uninstall.sh
