SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR/..
. env.sh -silent

wait_file {
    echo "Waiting File $1"
    x=12
    until [ -f $1 ]
    do
        x=$(( $x - 1 ))
        if [ $x -eq 0 ]; then
          echo "ERROR: $1 not found"
          exit 1
        fi
        echo "Waiting 5 secs"
        sleep 5
    done
    echo "File found"
}

# Start Certbot in Backgroud (since it has not OCI CLI access)
$BIN_DIR/tls/docker_certbot.sh > $TARGET_DIR/docker_certbot.log 2>&1 & 

# Wait that Certbot create the validation token
wait_file $TARGET_DIR/certbot_shared/CERBOT_DOMAIN ]

export CERBOT_DOMAIN=`cat $TARGET_DIR/certbot_shared/CERBOT_DOMAIN`
export CERTBOT_VALIDATION=`cat $TARGET_DIR/certbot_shared/CERTBOT_VALIDATION`
export TF_VAR_dns_acme_challenge=_acme-challenge.${CERBOT_DOMAIN}
export TF_VAR_dns_data=$CERTBOT_VALIDATION
oci dns record rrset update --force --zone-name-or-id $TF_VAR_dns_zone_name --domain $TF_VAR_dns_acme_challenge --rtype 'TXT' --items '[{"domain":"'$TF_VAR_dns_acme_challenge'", "rdata":"'$TF_VAR_dns_data'", "rtype":"TXT","ttl":300}]' --wait-for-state ACTIVE --wait-for-state FAILED

# Wait that Certbot create the validation token
wait_file $TARGET_DIR/certbot_shared/CERTBOT_DOMAIN_CLEAN ]
oci dns record rrset delete --force --zone-name-or-id $TF_VAR_dns_zone_name --domain $TF_VAR_dns_acme_challenge --rtype 'TXT' --wait-for-state ACTIVE --wait-for-state FAILED


x_max=5
x=$x_max
while [ $x -gt 0 ]
do
  nslookup $TF_VAR_dns_name
  sudo certbot --agree-tos --nginx --email $CERTIFICATE_EMAIL -d $TF_VAR_dns_name
  RESULT=$?
  if [ $RESULT -eq 0 ]; then
    echo "Success - certbot"
    x=0
  else 
    echo
    echo "WARNING"
    echo "Cerbot failed - Retrying $x/${x_max} - Waiting 120 secs for the DNS entry to propagate to the verification servers"
    sleep 120  
    x=$(( $x - 1 ))
    if [ $x -eq 0 ]; then
      echo "ERROR"
      exit 1
    fi