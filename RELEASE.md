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

