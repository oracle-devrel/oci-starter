SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR/..
. env.sh -silent
. $BIN_DIR/tls_dns/dns_shared_function.sh

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
