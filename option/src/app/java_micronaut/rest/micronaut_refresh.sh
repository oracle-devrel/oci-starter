echo "Refresh the sample Micronaut application"
echo 
mkdir orig
mv * orig
curl --location --request GET 'https://launch.micronaut.io/create/default/com.example.demo?lang=JAVA&build=MAVEN&test=JUNIT&javaVersion=JDK_17&features=data-jdbc&features=jdbc-hikari&features=oracle' --output demo.zip
unzip demo.zip
mv demo/* .
mv demo/.* .
rmdir demo
cp orig/*.sh .
cp orig/openapi_spec.yaml .
cp orig/k8s_app.yaml .
cp orig/src/main/java/com/example/Dept* src/main/java/com/example/.
cp orig/Docker* .
cp orig/src/main/resources/application.properties src/main/resources/.
rm src/test/java/com/example/DemoTest.java
rm src/test/resources/application-test.properties

# Missing redo the .j2 customisation for DeptRepository.java and pom.xml