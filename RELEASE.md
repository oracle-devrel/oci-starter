1.3
---
Change of the directory structure

1.4 
---
Date: 2022-12-17
- added JSP (as user interface - it is another way to choose Tomcat that was there before)
- added PHP (as user interface and backend)
- added None as database
- added Pluggable as database. This is another way to choose a DB System that was there before also (you need an existing DB System) -> The idea here is for my exadata customers who uses these PDB all the time
- the container instance first working version (still issue with OCI Cloud Shell)

1.5 
---
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

2.0
---
Date: 8-02-24
- The code is smaller than before, what makes a lot easier to add additional DB Types.
- New DB Types: PostgreSQL, OpenSearch and NoSQL. All works except PHP+NoSQL, no driver ? (or I did not found it)
- In Advanced, HTTPS option (=DNS+TLS),
  - OCI Certificates (existing TLS certificate in OCI)
  - Let's encrypt DNS-01 (<- this is a really interesting feature of Let's Encrypt)
  - Compute only: Let's encrypt TLS-01 (=certbot)
  - Kubernetes only: Let's encrypt TLS-01 (using K8s cert-manager, K8s External DNS, Nginx Ingress Controller)
- K8s cert-manager is installed via the OKE Addons using terraform with some other add-ons.

2.1
---
Date: 13-03-24
- new type of Cloud Shell on ARM
- ARM is available now for Kubernetes/Container Instance/Functions/Instance Pools
- Idem for AMD FreeTier
- Surprinsingly, it works for everything...  for all languages, all db types, etc..
- Several improvements on the NoSQL samples (performance improvement, use of Jakarta NoSQL in Helidon)
- Java Sprinboot default implementation is now using Spring Data to acccess Oracle/MySQL/Postgress and Spring Data nosql for NoSQL

2.2
---
Date : 6-Apr-2024
- ocir region with key 