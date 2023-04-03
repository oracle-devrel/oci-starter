# oci-starter

## Usage:
### 1. Website 

Go to: [starter.oracloud.be](https://starter.oracloud.be/)

- Make your choices.
- Generate. You will get a zip file. ( ex:starter.zip )
- Upload the zip file in OCI Shell. Then
- Still in OCI Shell:

```
unzip starter.zip
cd starter
./build.sh
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
./build.sh
Then click on the UI_URL at then end of the build
```

To destroy:
```
cd output
./destroy.sh
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

