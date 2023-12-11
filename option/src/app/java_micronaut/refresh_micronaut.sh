echo "Refresh the sample Micronaut application"
echo 
mkdir orig
mv * orig



curl --location --request GET 'https://launch.micronaut.io/create/default/com.example.demo?lang=JAVA&build=MAVEN&test=JUNIT&javaVersion=JDK_17&features=oracle&features=netty-server&features=hibernate-jpa&features=validation&features=jackson-databind&features=annotation-api&features=data-jpa' --output demo.zip
unzip demo.zip
mv demo/* .
mv demo/.* .
rmdir demo

cp orig/*.sh .
cp orig/openapi_spec.yaml .
cp orig/app.yaml .
cp orig/src/main/java/com/example/Dept* src/main/java/com/example/.
vi src/main/resources/application.properties

cp orig/microprofile-config.properties.tmpl .
cp orig/src/main/resources/META-INF/persistence.xml src/main/resources/META-INF/.
cp orig/src/main/java/me/opc/mp/database/Dept* src/main/java/helidon/.
rm src/main/resources/META-INF/init_script.sql
rm src/main/resources/META-INF/microprofile-config.properties
sed -i "s/me.opc.mp.database.Dept/helidon.Dept/" src/main/resources/META-INF/persistence.xml 
sed -i "s/package me.opc.mp.database/package helidon/" src/main/java/helidon/Dept*
