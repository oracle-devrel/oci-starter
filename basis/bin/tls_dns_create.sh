SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR/..
. env.sh -silent
. $BIN_DIR/tls/dns_shared_function.sh

# Start Certbot in Backgroud (since it has not OCI CLI access)
$BIN_DIR/tls/dns_oci_background.sh & 

if [ "$TF_VAR_dns_name" == "" ]; then
  echo "ERROR: TF_VAR_dns_name not defined"
  exit 1
fi

mkdir -p $TARGET_DIR/letsencrypt
mkdir -p $TARGET_DIR/certbot_shared

cp $BIN_DIR/tls/dns* $TARGET_DIR/certbot_shared/.

docker run -it --rm --name certbot \
            -v "$TARGET_DIR/letsencrypt:/etc/letsencrypt" \
            -v "$TARGET_DIR/certbot_shared:/certbot_shared" \
            certbot/certbot -d $TF_VAR_dns_name --agree-tos --register-unsafely-without-email --manual --preferred-challenges dns \
            --manual-auth-hook /certbot_shared/dns_challenge.sh --manual-cleanup-hook /certbot_shared/dns_challenge_clean.sh \
            --disable-hook-validation --force-renewal certonly
