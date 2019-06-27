# KubeDeploy

################
# Requirements #
################
Install --> Ansible (latest)
            pip install apache-libcloud (Both Python2 and Python3)
            git
            google-chrome (testing virtual hosts)

**Executables like Terraform and Packer are also packed up in the repo to avoid problems**
################
#Repo Structure#
################
Base Repo#
@@@@@@@@@@
.
├── 1. Bake_Image               (Packer Makking Image)
│   ├── k8s.sh                  (Script to run in VM to install packages)
│   ├── packer                  (Packer Exexutable)
│   ├── pak.json                (Packer config)
│   └── run.sh                  (Script to bake Image)
├── 2. Deploy_Instances         (Terraform Infrastructure Deployment)
│   ├── main.tf
│   ├── terraform
│   ├── terraform.tfstate
│   └── terraform.tfstate.backup
├── 3. Make_Cluster             (Ansible Make Cluster and deploy services)
│   ├── ansible.cfg             (Configured cfg for playbooks)
│   ├── efk_deploy.yml          (Playbook to deploy Elastsearch, Kibana and Fluentd)
│   ├── files                   (Playbook requirements)
│   │   ├── elasticsearch.yaml
│   │   ├── fluentd-daemonset.yaml
│   │   ├── fluentd-rbac.yaml
│   │   ├── istio-demo.yaml
│   │   └── kibana.yaml
│   ├── get.sh                  (Flush Inventory folder)
│   ├── inventory
│   │   ├── gce.ini             (Edit to specify GCP Credentials)
│   │   └── gce.py              (Dynamic inventory file)
│   ├── istio_deploy.yaml       (Deploy Istio and Promethus and Grafana)
│   ├── jenkins_deploy.yml      (Deploy Helm and Jenkins )
│   ├── master_deploy.yml       (Setup Master Node)
│   ├── nodes_deploy.yml        (Join other nodes to cluster)
│   ├── promethus_deploy.yml    (Deploy Promethus Opertor in montoring namespace) (NOT RECOMMENDED)
│   ├── rbac-config.yaml        (Helm RBAC Config)
│   └── refresh.sh              (Refresh Dynamic Inventory)
│   
├── GuestBook-1561564932360.json(Grafana Application Chart)
└── README.md
#######################
Chart && Pipeline Repo@
@@@@@@@@@@@@@@@@@@@@@@@
.
├── bluegreen.py            (BlueGreenDeployment file)
├── canary.py               (Canary Deployment file)
├── Deployment
│   ├── istio-canary.yaml   (Specifying Weights for canary)
│   ├── istio-gateway.yaml  (Istio Gateway for ingress)
│   └── istio-vs.yaml       (VirtualService after Deployment)
├── first.py                (Simple first deployment)
├── guest-book              (Helm FontEnd Chart)
│   ├── charts
│   ├── Chart.yaml
│   ├── templates
│   │   ├── _helpers.tpl
│   │   ├── phpRedis-deployment.yaml
│   │   ├── phpRedis-service.yaml
│   │   └── tests
│   └── values.yaml
├── Jenkinsfile             (Jenkins file for pipeline)
├── php-redis               (FrontEnd DockerImageBuild Folder)
│   ├── controllers.js
│   ├── Dockerfile
│   ├── guestbook.php
│   ├── index.html
│   ├── Makefile
│   └── README.md
├── README.md
├── rediscluster            (Helm Chart to deploy backend)
│   ├── charts
│   ├── Chart.yaml
│   ├── templates
│   │   ├── _helpers.tpl
│   │   ├── redisMaster-deployment.yaml
│   │   ├── redisMaster-service.yaml
│   │   ├── redisSlave-deployment.yaml
│   │   ├── redisSlave-service.yaml
│   │   └── tests
│   └── values.yaml
└── redis-slave             (Backend DockerImage Build Folder)
    ├── Dockerfile
    ├── Makefile
    ├── README.md
    └── run.sh
########################################
            DEPLOYMENT
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

**The below setups are consdering that the viewer has an existing project**
**Use Same Zone and Project name and credentials everywhere**

Q1. Kubernetes Deployment on GCP
The process is broken in 3 parts :-
(a) Baking Image using Packer
(b) Deploying Infrastructure using Terraform
(c) Setting up cluster and other stuff using Ansible


One needs to first setup a service account with required priviledges for the task:-
1. Go to google cloud console --> IAM & admin --> Service Accounts
2. Create a Service Account with unique name and Attach following roles :-
        Compute Admin
        Compute Storage Admin
        Editor
        Service Account User

3. Create and downlad the JSON key for the service account


##############################
(a) Baking Image using Packer
##############################
The files are stored in folder "1. Bake_Image".
1. Place the service account credentials in the folder
2. Change the "ProjectName", "Zone", "serviceAccountCredentialsFileName" in the file run.sh
3. Extract the packer.tar.xz in the folder or run "./get_packer.sh" to get packer executable
4. Execute run.sh to bake the base VM Image.(ImageName: Kubespinner, OS: centos-7)
One can manually check the image in the Google Compute Engine --> Images

**NOTE** If stuck on issue like compute.zone.get not permitted ...
Then run in a proper OS with defaut packages, (faced similar problem with Centos-Minimal)

#################################################
(b) Deploying the infrastructure using Terraform
#################################################
The files are stored in the folder "2. Deploy_Instances"
1. Place the Credentials file here
2. Edit lines 2-5 in main.tf specifying the GCP details and the credentials file name
3. Further definfition can be changed as below :-
        Line 11: k8s cluster instance type
        Line 41: number of worker nodes
        Line 46: jenkins instance type
        Line 61,27: SSH keys to be used (Should not be tampered)
4. Extract "terraform.tar.xz" or run "./get_terraform.sh". Then run "./terrform init"
5. Then run "./terraform plan" to get a view of the infrastructure defined
6. Finally run "./terrform apply" then type yes to approve and build
7. At the end note the IP Address of Jenkins VM in a seperate notepad

**NOTE** Use n1-standard-1 VMs in cluster to run the EFK Stack else Elasticsearch fails and node may become notReady

##################################################
(c) Deploying The cluster and stuff
##################################################
The files are placed in folder "3. Make_Cluster"
1. Navigate to "3. Make_Cluster/inventory"
2. Place the credentials file here
3. Edit the file gce.ini in the inventory folder ("3. Make_Cluster/inventory/gce.ini") :-
        Line 47: gce_service_account_email_address  --> from client_email in credentials.json
        Line 48: gce_service_account_pem_file_path  --> Provide the FULL ABSOLUTE PATH to credentials.json
        Line 49: gce_project_id                     --> same as in (b)
        Line 50: zone                               --> same as in (b)

**NOTE** Don't add  " " to the values, else dynamic inventory will fail

4. Ensure that the file "3. Make_Cluster/inventory/gce.py" is executable
5. Verify Ansible Dynamic inventory by running "./gce.py --list" in the folder

**NOTE** ALL PLAYBOOKS MUST BE RUN FROM "3. Make_Cluster" FOLDER

6. Run the Playbook "master_deploy.yml" to deploy the master --> "ansible-playbook master_deploy.yml"
7. Run the Playbook "nodes_deploy.yml" to deploy k8s nodes --> "ansible-playbook nodes_deploy.yml"

Now the cluster is deployed, but we need to run some more playbooks in the specified order to setup
services properly

8. Run the playbook "istio_deploy.yaml" to deploy istio --> "ansible-playbook istio_deploy.yaml"
ALSO NOTE THE NODEPORT AT THE END OF PLAYBOOK

9. Run the playbook "jenkins_deploy.yml" to deloy Helm, Kubectl config(on jenkins node), and finally JenkinsServer
10. Take a note of the Jenkins default admin password at the end of playbook

11. Run the playbook "efk_deploy.yml" to deploy the EFK Stack --> "ansible-playbook efk_deploy.yml"
12. Note the exposed port of elasticsearch and kibana at the end of playbook to access the logging

**NOTE** You need to manually check(GCP Console) the masters external IP for accessing NodePort Services

Q 1,5,10 have been completed

####################################################
Q2,3,4,6,11 (Jenkins)(Helm)(Canary/BLueGreen)(Istio)
####################################################
1. Go to the Jenkins IP on port 8080
2. Use the noted password to unlock Jenkins
3. Click on "Install suggested plugins" (wait Patiently as it takes time for next page to load)
4. Create a user if required, else continue as admin and setup the IP Address as pre-written in jenkins

5. Create a github repo and copy and push the contents of this repo --> "https://github.com/crazystylus/Pipeline"

This repo contains the guestbook app divided into 2 charts (frontend,backend), the Jenkins file and Dockerfiles
for 2 images and required files for Canary and blueGreen Deployment.

7. Create 2 public dockerhub repos with names --> "phpredis" and "redisslave"
8. Edit Jenkins file from the above Repo Line number 8,9 for correct USERNAME
9. Correct image repostory name(USERNAME ONLY) in JenkinsFile Line 35 --> "phpRedis.image.repository=kartiksharma522/phpredis"

**NOTE** Don't forget to push the update back to your repo

10. Create global credential in Jenkins --> with id "docker-hub-credentials" specifying dockerhub username and password
11. Create Jenkins Pipeline as follows --> NewItem --> Give a name and Select Pipeline --> Select GitHub Project and "YourClonedID" -->
        GithubHookCheckoutSCM
        Then under Jenkins file --> SCM --> Git and Specify the same github url from above

12. Apply and Save and manually start the first BUILD
13. Go to your clone github repo --> Setting --> webhook --> add Webhook --> "http://JENKINS_IP:8080/github-webhook/" Then save
14. Any further push will automatically trigger a build

15. Although guestbook is exposed through nodeport, but IstioGateway must be used to see the Canary and BlueGreen Deployments
16. To verify the VirtualHosts in GoogleChrome use the following plugin -->
"https://chrome.google.com/webstore/detail/virtual-hosts/aiehidpclglccialeifedhajckcpedom?hl=en"

        Here specify the VHostDomain as --> "guestbook.example.com", VHostIP --> "k8s_master_IP"
        Then check enable

17. Visit URL "http://guestbook.example.com:31380" in google chrome to view the Guestbook App

The Deployment is by default "BlueGreen"

18. To switch Deployment to CANARY, Comment line 41 and Uncomment line 38 for Canary and vice-versa for BlueGreen
19. The effect can be see by refreshing page at above url.
20. To edit the html go to "(cloned_repo)/php-redis/index.html" and add 'style="background-color:powderblue;"' to line 9 in bodytag
21. Commit and push the image. Watch the Jenkins Pipeline, in the DeployApplication Stage, one can refresh page and check for canary

#################################################
Q 7,8,9 (Monitoring)
#################################################
The monitoring automatically get installed under Istio BUT under the namespace istio-system
So there is no need to install promethus and grafana again, BUT one can do so by running the ansible playbook "efk_deploy.yaml"
in same folder as other playbooks. This will setup monitoring namespace too. BUT NOT RECOMMENDED TO DO SO

1. Use the nodeport PORT and Master's IP to access Promethus and Grafana
2. In grafana, password is disbaled, but its recommended to setup password.
3. Create a dashboard and then click on upload .json and select the "GuestBook-1561564932360.json" from base repo.
4. One can then view particular guestbook related graph and pod resource consumption

#################################################
Q 10 (EFK)(Logging)
#################################################
Use the master's IP and noted port for elastic search and Kibana
to access the service



