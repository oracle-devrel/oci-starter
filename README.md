# oci-starter

## Usage:
### 1. Website 

Go to: [www.ocistarter.com](https://www.ocistarter.com/)

- Make your choices.
- Generate. You will get a zip file. ( ex:starter.zip )
- Upload the zip file in OCI Shell. Then
- Still in OCI Shell:

```
unzip starter.zip
cd starter
./starter.sh build
Then click on the UI_URL at then end of the build
```

### 2. Cloud Shell / Command Line 

- Go to OCI Home page.
- Start "Cloud Shell" icon on top/right

```
git clone https://github.com/MarcGueury/oci-starter 
cd oci-starter
./oci_starter.sh -prefix test -language java -deploy compute -db_password LiveLab__12345 
cd output
./starter.sh build
Then click on the UI_URL at then end of the build
```

To destroy:
```
cd output
./starter.sh destroy
> Do you really want to destroy all resources? yes
```


Best practice: 
- Run the command in compartment
    - Go to menu "Identity & Security"
    - Compartment
        - Find or create your compartment_id
```
...
./oci_starter.sh -compartment_ocid ocid1.compartment.oc1..xxx -prefix test -language java -deploy compute -db_password LiveLab__12345 
...
```

## 3. "Deploy to Oracle Cloud"

[ ![Deploy to Oracle Cloud](https://oci-resourcemanager-plugin.plugins.oci.oraclecloud.com/latest/deploy-to-oracle-cloud.svg)](https://cloud.oracle.com/resourcemanager/stacks/create?zipUrl=https://github.com/MarcGueury/oci-starter/archive/refs/heads/main.zip)

Just follow the wizard. (Not tested lately)

## License
Copyright (c) 2024 Oracle and/or its affiliates.

Licensed under the Universal Permissive License (UPL), Version 1.0.

See [LICENSE](LICENSE) for more details.

ORACLE AND ITS AFFILIATES DO NOT PROVIDE ANY WARRANTY WHATSOEVER, EXPRESS OR IMPLIED, FOR ANY SOFTWARE, MATERIAL OR CONTENT OF ANY KIND CONTAINED OR PRODUCED WITHIN THIS REPOSITORY, AND IN PARTICULAR SPECIFICALLY DISCLAIM ANY AND ALL IMPLIED WARRANTIES OF TITLE, NON-INFRINGEMENT, MERCHANTABILITY, AND FITNESS FOR A PARTICULAR PURPOSE.  FURTHERMORE, ORACLE AND ITS AFFILIATES DO NOT REPRESENT THAT ANY CUSTOMARY SECURITY REVIEW HAS BEEN PERFORMED WITH RESPECT TO ANY SOFTWARE, MATERIAL OR CONTENT CONTAINED OR PRODUCED WITHIN THIS REPOSITORY. IN ADDITION, AND WITHOUT LIMITING THE FOREGOING, THIRD PARTIES MAY HAVE POSTED SOFTWARE, MATERIAL OR CONTENT TO THIS REPOSITORY WITHOUT ANY REVIEW. USE AT YOUR OWN RISK. 

