git clone https://github.com/oracle-quickstart/oci-hpc
mv oci-hpc/variable.tf oci-hpc/variable.orig
cp hpc_variable.tf oci-hpc/variable.tf
rm $ROOT_DIR/src/terraform/*.tf
mv oci-hpc/* $ROOT_DIR/src/terraform/.
cd $ROOT_DIR/src/terraform
./apply.sh

