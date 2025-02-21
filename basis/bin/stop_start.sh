#!/bin/bash
if [ "$PROJECT_DIR" == "" ]; then
  echo "ERROR: PROJECT_DIR undefined. Please use starter.sh terraform apply"
  exit 1
fi  
cd $PROJECT_DIR

ACTION=$1
. starter.sh env -silent

if [ "$ACTION" != "start" ] && [ "$ACTION" != "stop" ] && [ "$ACTION" != "list" ]; then
  error_exit "stop_start.sh ACTION unknown ($ACTION): stop / start / list"
fi  

function loop_resource() {
    RESOURCE_TYPE=$1
    for OCID in `cat $STATE_FILE | jq -r ".resources[] | select(.type==\"$RESOURCE_TYPE\" and .mode==\"managed\") | .instances[].attributes.id"`;
    do
        if [ "$ACTION" == "start" ] || [ "$ACTION" == "stop" ]; then
            title "$OCID"
            if [ "$RESOURCE_TYPE" == "oci_analytics_analytics_instance" ]; then
                oci analytics analytics-instance $ACTION --analytics-instance-id $OCID
            elif [ "$RESOURCE_TYPE" == "oci_core_instance" ]; then
                oci compute instance action --action $ACTION --instance-id $OCID
            elif [ "$RESOURCE_TYPE" == "oci_database_autonomous_database" ]; then
                oci db autonomous-database $ACTION --autonomous-database-id $OCID
            elif [ "$RESOURCE_TYPE" == "oci_database_db_system" ]; then
                COMPARTMENT_ID=`oci db system get --db-system-id $OCID | jq -r '.data["compartment-id"]'`
                NODES=$(oci db node --all --compartment-id $COMPARTMENT_ID --db-system-id $OCID | jq -r '.data[].id')
                for NODE in $NODES
                do            
                    oci db node stop --db-node-id $NODE
                done            
            elif [ "$RESOURCE_TYPE" == "oci_datascience_notebook_session" ]; then
                if [ "$ACTION" == "start" ]; then
                    oci data-science notebook-session activate --notebook-session-id $OCID
                else
                    oci data-science notebook-session deactivate --notebook-session-id $OCID
                fi
            elif [ "$RESOURCE_TYPE" == "oci_integration_integration_instance" ]; then
                oci integration integration-instance $ACTION --id $OCID
            elif [ "$RESOURCE_TYPE" == "oci_mysql_mysql_db_system" ]; then
                oci mysql db-system $ACTION --db-system-id $OCID --shutdown-type innodb_fast_shutdown 
            elif [ "$RESOURCE_TYPE" == "oci_oda_oda_instance" ]; then
                oci oda instance $ACTION --oda-instance-id $OCID
            fi
        else
            echo "Instance $OCID"
        fi
    done;
}

loop_resource oci_analytics_analytics_instance
loop_resource oci_core_instance
loop_resource oci_database_autonomous_database
loop_resource oci_database_db_system
loop_resource oci_datascience_notebook_session
loop_resource oci_integration_integration_instance
loop_resource oci_mysql_mysql_db_system
loop_resource oci_oda_oda_instance

# loop_resource oci_objectstorage_bucket

