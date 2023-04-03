FROM ##DOCKER_IMAGE##
COPY target/demo-0.0.1-SNAPSHOT.jar /app/app.jar
WORKDIR /app
ENTRYPOINT ["java","-jar","app.jar"]