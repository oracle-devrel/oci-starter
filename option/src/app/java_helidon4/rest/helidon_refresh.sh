echo "Refresh the sample Helidon application"
echo 
mkdir orig
mv * orig
curl "https://helidon.io/api/starter/4.0.0/generate?flavor=mp&app-type=database&db.server=oracledb&groupId=helidon&artifactId=helidon&package=helidon" --output helidon.zip
unzip helidon.zip
mv helidon/* .
mv helidon/.* .
rmdir helidon
rm src/main/java/helidon/Pokemon*
cp orig/*.sh .
cp orig/openapi_spec.yaml 
cp orig/k8s_app.yaml .
cp orig/openapi_spec.yaml .
cp orig/microprofile-config.properties.tmpl .
cp orig/src/main/resources/META-INF/persistence.xml src/main/resources/META-INF/.
cp orig/src/main/java/me/opc/mp/database/Dept* src/main/java/helidon/.
rm src/main/resources/META-INF/init_script.sql
rm src/main/resources/META-INF/microprofile-config.properties
sed -i "s/me.opc.mp.database.Dept/helidon.Dept/" src/main/resources/META-INF/persistence.xml 
sed -i "s/package me.opc.mp.database/package helidon/" src/main/java/helidon/Dept*
