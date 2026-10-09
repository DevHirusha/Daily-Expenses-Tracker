FROM eclipse-temurin:21-jdk-jammy AS build

WORKDIR /app

COPY .mvn/ .mvn/
COPY mvnw pom.xml ./
RUN chmod +x mvnw
RUN ./mvnw -B dependency:go-offline

COPY src/ src/
RUN ./mvnw -B clean package -DskipTests

FROM eclipse-temurin:21-jre-jammy

WORKDIR /app

COPY --from=build /app/target/*.jar /app/app.jar

ENV JAVA_OPTS="-XX:MaxRAMPercentage=75.0"
EXPOSE 8080

ENTRYPOINT ["sh", "-c", "exec java $JAVA_OPTS -Dserver.port=${PORT:-8080} -jar /app/app.jar"]
