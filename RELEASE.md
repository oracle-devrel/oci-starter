## 1.3
Change of the directory structure

## 1.4 
Date: 2022-12-17
- added JSP (as user interface - it is another way to choose Tomcat that was there before)
- added PHP (as user interface and backend)
- added None as database
- added Pluggable as database. This is another way to choose a DB System that was there before also (you need an existing DB System) -> The idea here is for my exadata customers who uses these PDB all the time
- the container instance first working version (still issue with OCI Cloud Shell)

## 1.5 
Date: 2022-01-12
- Removed JSP (Backend: Java - Tomcat)
- Added API Only (if APIGW is there, create a API spec, new file src/app/openapi_spec.yaml)
- Added the "Group" options in advanced
  - it allows to create a common resources that can be reused by later projects
    Typically, Network, OKE, DB, APIGW, ...
    - group_common
    - starter_app1
    - starter_app2
    ...

## 2.0
Date: 8-02-24
- The code is smaller than before, what makes a lot easier to add additional DB Types.
- New DB Types: PostgreSQL, OpenSearch and NoSQL. All works except PHP+NoSQL, no driver ? (or I did not found it)
- In Advanced, HTTPS option (=DNS+TLS),
  - OCI Certificates (existing TLS certificate in OCI)
  - Let's encrypt DNS-01 (<- this is a really interesting feature of Let's Encrypt)
  - Compute only: Let's encrypt TLS-01 (=certbot)
  - Kubernetes only: Let's encrypt TLS-01 (using K8s cert-manager, K8s External DNS, Nginx Ingress Controller)
- K8s cert-manager is installed via the OKE Addons using terraform with some other add-ons.

## 2.1
Date: 13-03-24
- new type of Cloud Shell on ARM
- ARM is available now for Kubernetes/Container Instance/Functions/Instance Pools
- Idem for AMD FreeTier
- Surprinsingly, it works for everything...  for all languages, all db types, etc..
- Several improvements on the NoSQL samples (performance improvement, use of Jakarta NoSQL in Helidon)
- Java Sprinboot default implementation is now using Spring Data to acccess Oracle/MySQL/Postgress and Spring Data nosql for NoSQL

## 2.2
Date : 6-Apr-2024
- ocir region with key 

# 3.3
Date: 21-Feb-2025
- Split of the bin directory and the rest of oci-starter project
    $PROJECT/starter.sh is just a proxy to an oci_starter.sh that could be anywhere in the path or in $PROJECT/bin
    auto_env.sh calls env.sh and not the opposite
- New name
    for the compute: NEW: starter_compute / OLD: starter_instance
    NEW: public_compute OLD: shared_compute
    NEW: private_compute OLD: compute
- Python
    version 3.11
    use Virtual env to install package (not root anymore)
    use HTTP server, use Flask Waitress for production version
- Known issues:
    OCI terraform bug to create PDBs
    OCI terraform bug to create Instance Pools

# 3.4
Date: 11-Feb-2025
- Config.sh - title
- Config.sh - LICENSE_MODEL
- Reapply caused change in terraform because of automatics shemas ignore_changes
    lifecycle {
       ignore_changes = [ schemas ]
    }
- ATP DB23ai 1OCPU 1TB -> 2ECPU 128GB


## 3.5
Date: 21-Feb-2025
- Replaced docker login by oci raw-request --region
    -> Removed need for AUTH_TOKEN
- Fix: config TF_VAR_license_model
- New ./starter.sh start / stop to start stop the resource in terraform.tfstate
- Fix: wget -nv

## 3.6
Date 7-Apr-2025
- ./starter build request to approve change in the second build.
- ./starter destroy remove the .terraform cache after destroy ( 250Mb big...)
- file_replace_variables for ##XXX## app/env.sh and compute (not used yet per default)
- upgrade.sh improved
- default Oracle Linux in case of no access to images list : Oracle-Linux-8.10-2025.03.18-0
- ords fix using not the ADMIN schema anymore
- python 3.11 -> 3.12
- terraform lifecycle / ignore_changes for Linux image name new version, etc..

## 3.7
Date 14-Apr-2025
- done.sh splitted in done.sh and test_after_done.sh
- upgrade.sh 2.0 -> 3.x 

## 3.8
Date 13-May-2025
- container repository in compartment (repository.tf) for Kubernetes, Container Instance, Function
- container repository random prefix

## 3.9
Date 21-June-2025
- guess_available_shape. scan all availability domain to use or VM.Standard.E6.Flex/E5/E4 is available as default shape.
- TF_VAR_namespace also for compute and object storage
- next to greenlab of LiveLab - Lunalab auto-detection and find of compartment_ocid + TF_VAR_instance_shape
- config for TF_VAR_vault_ocid
- rename target directory after successful destroy to avoid people doing multiple build / delete and reusing previous settings. terraform precheck. Before to run the 1rst build. Run terraform plan and check if there are not existing bucket with the same name already to avoid error in the middle when several people install the same lab with the same prefix on the same tenancy
- starter.sh rebuild, start/stop, upgrade fixes
- compute
    - allow now to have several start_xxx.sh in the app directory. For ex to have 1 python, 1 java and 1 node service in the same directory.
    - app contains now, init.sh, start_xxx.sh and restart.sh (new)

    