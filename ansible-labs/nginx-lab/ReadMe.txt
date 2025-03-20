 2251  multipass launch --name master-vm --mem 3G --disk 8G --cpus 1\n
 2254  multipass launch --name worker1-vm --memory 1G --disk 5G --cpus 1\n
 2255  multipass list
 2256  sudo ls -lh /var/root/Library/Application\ Support/multipassd/qemu/vault/instances/worker1-vm/
 2257  sudo ls -lh /var/root/Library/Application\ Support/multipassd/qemu/vault/instances/master-vm/

multipass mount ~/ansible-labs/nginx-lab master-vm:~/nginx-lab

 2259* multipass shell master-vm
 2261* multipass shell worker1-vm


 2259* multipass shell master-vm

    1  sudo apt install -y ansible
    2  ansible --version

    4. Test Connection (Ping)
    5  ansible all -m ping -i ./intentory.ini

    9  ssh-keygen -t rsa -b 4096
   10  ssh-copy-id ubuntu@192.168.64.10
   11  ls ~/.ssh/id_rsa
   12  cat /home/ubuntu/.ssh/id_rsa
   13  ssh ubuntu@192.168.64.10
   14  chmod 700 ~/.ssh
   15  chmod 600 ~/.ssh/authorized_keys
   16  ssh ubuntu@192.168.64.10
   17  ansible all -m ping -i ./intentory.ini
   18  cat /home/ubuntu/.ssh/id_rsa.pub
   19  ssh ubuntu@192.168.64.10
   20  ansible all -m ping -i ./inventory.ini

   23  ansible-playbook -i inventory.ini install_nginx.yml
        OR direct
   34  ansible all -m command -a "systemctl start nginx" -i inventory.ini

   24  ansible all -m systemd -a "name=nginx state=started" -i ./inventory.ini
   27  vi check_nginx_status.yml
   28  ansible-playbook -i inventory.ini check_nginx_status.yml

   29  ansible all -m command -a "sudo systemctl status nginx" -i inventory.ini
   30  ansible all -m systemd -a "name=nginx state=stopped" -i ./inventory.ini

   33  ansible-playbook -i ./inventory.ini stop_nginx.yml
   34  ansible all -m command -a "systemctl stop nginx" -i inventory.ini
   35  ansible all -m command -a "systemctl status nginx" -i inventory.ini

   36  ssh ubuntu@worker1-vm
   37  ping 192.168.64.10
   38  ssh ubuntu@192.168.64.10
   39  ansible all -m command -a "systemctl status nginx" -i inventory.ini
   40  ansible all -m command -a "systemctl stop nginx" -i inventory.ini
sudo systemctl status nginx



5. Ansible Ad-Hoc Commands
Ansible allows you to run commands on the remote machines without creating a playbook. These are called ad-hoc commands.

For example, to install a package on all web_servers:



ansible web_servers -m apt -a "name=nginx state=present" -i inventory
Explanation:

-m apt: Use the apt module to manage packages (for Ubuntu/Debian systems).
-a "name=nginx state=present": Ensure the nginx package is installed.
-i inventory: Use the custom inventory file to target the correct servers.

ansible-playbook -i inventory copy_file.yml



--------

8. Use Roles to Organize Playbooks
As your playbooks grow, it’s a good practice to organize them into roles. A role is a way of grouping related tasks, files, and templates.

To create a role, use the following structure:



ansible-galaxy init nginx_role
This will create a directory structure like this:

css

nginx_role/
├── defaults/
├── files/
├── handlers/
├── meta/
├── tasks/
│   └── main.yml
├── templates/
└── vars/
You can place specific tasks inside nginx_role/tasks/main.yml, and then reference the role in your playbook:

yaml

---
- name: Install and configure Nginx
  hosts: web_servers
  become: yes
  roles:
    - nginx_role
9. Best Practices
Use YAML Syntax Properly: Always indent your YAML files correctly and avoid mixing tabs and spaces.
Organize Playbooks by Roles: For large-scale projects, split your tasks into roles to keep things modular and reusable.
Version Control: Store your playbooks and configuration files in a version control system like Git for better collaboration and history tracking.
Use ansible-lint: For linting and best practices in your playbooks.



---------
❯ multipass stop worker1-vm
❯ multipass stop master-vm
❯ multipass delete worker1-vm
❯ multipass delete master-vm
❯ multipass purge



--------------

Check the disk:

You can check the current partition sizes with:

lsblk

Or use df -h to see the available disk space.

----------


Steps to Troubleshoot and Fix the SSH Connection Issue:
Check SSH Key Authentication:

Verify SSH Keys: Ansible uses SSH to connect to remote machines. By default, it will look for SSH keys in ~/.ssh/id_rsa or another path specified by your inventory.ini or via the ansible_ssh_private_key_file variable.
If you haven’t already, make sure you have generated an SSH key pair for the user ubuntu on your local machine (or the machine from where you are running Ansible).
Use ssh-keygen if you haven't generated one yet:


ssh-keygen -t rsa -b 4096
Ensure the Key is Available on the Remote VM:

The public key must be in the ~/.ssh/authorized_keys file of the remote user (ubuntu) on the remote machine.
You can copy the public key to the remote machine using the following command:


ssh-copy-id ubuntu@192.168.64.10
If you're unable to use ssh-copy-id, you can manually add the public key to the authorized_keys file on the remote machine.
Check SSH User:

Ensure the SSH user (ubuntu) exists on the remote machine. You can check this by logging in directly to the VM:


ssh ubuntu@192.168.64.10
If the user doesn’t exist or isn’t the correct user, adjust the inventory.ini file to reflect the correct user for the VM.
Permissions Issue:

Ensure the permissions on the ~/.ssh directory and files are correct on both the local machine and remote machine.
On the local machine:


chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_rsa
On the remote machine:


chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
Verify the Ansible Inventory File:

Double-check that the IP address and user are correct in your inventory.ini file.
Example inventory.ini file:
ini

[workers]
worker1-vm ansible_host=192.168.64.10 ansible_user=ubuntu
Ensure that you specify the correct private key file if it’s not the default ~/.ssh/id_rsa:
ini

[workers]
worker1-vm ansible_host=192.168.64.10 ansible_user=ubuntu ansible_ssh_private_key_file=path_to_your_private_key
Test SSH Connection Manually:

Before running the Ansible playbook, ensure you can SSH manually to the remote machine using the same credentials:


ssh -i /path/to/private/key ubuntu@192.168.64.10
If the SSH connection works manually, then Ansible should also work. If not, troubleshoot any SSH errors.
Disable SSH Strict Host Key Checking (if needed):

Sometimes, SSH may fail because it doesn’t recognize the remote host's key, especially if it’s a fresh VM. To bypass this, you can add this to your inventory.ini file or set it in your ansible command:
ini

[workers]
worker1-vm ansible_host=192.168.64.10 ansible_user=ubuntu ansible_ssh_private_key_file=path_to_your_private_key ansible_ssh_common_args='-o StrictHostKeyChecking=no'
Alternatively, you can disable strict host key checking globally by editing the ansible.cfg file:
ini

[defaults]
host_key_checking = False



--------

Review System Resources
Ensure that there are no system resource issues (e.g., CPU, memory, disk space) that are causing the service to fail. You can check the resources on the node with:

top
or
free -h

You can run a find command to check if any processes are currently using it:
lsof | grep .ollama


Obtain IPs of Nodes: Inside the control node, find the IP addresses of the managed nodes. You can use the following command to list all VMs' IP addresses (they should be on the private network):

ip a

----------

Modify PATH variable and apply changes to the system using ansible playbook:


Playbook
yaml
---
- name: Modify .bashrc and source it
  hosts: all
  tasks:
    - name: Add custom path to .bashrc
      lineinfile:
        path: "~/.bashrc"
        line: 'export PATH="/custom/path:$PATH"'
        state: present

    - name: Source the .bashrc to apply changes
      shell: source ~/.bashrc && echo "Sourced .bashrc"
      # The `changed_when` is used to avoid this task always being marked as changed.
      changed_when: false

----------