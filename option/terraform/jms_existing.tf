var fleet_ocid {}

# JMS Fleet
data oci_jms_fleet starter_fleet {
  fleet_id = var.fleet_ocid
}

output fleet_ocid {
  value=oci_jms_fleet.starter_fleet.id
}

