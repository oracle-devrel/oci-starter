FROM ##DOCKER_IMAGE##
COPY target/demo-0.1.jar /app/app.jar
WORKDIR /app
ENTRYPOINT ["java","-jar","app.jar"]