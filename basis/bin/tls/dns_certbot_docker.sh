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


