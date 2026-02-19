FROM maven:3-eclipse-temurin-21-alpine AS builder
WORKDIR /app
COPY pom.xml .
RUN mvn dependency:go-offline

COPY src ./src
RUN mvn clean package -DskipTests

FROM eclipse-temurin:21-jre-alpine AS runner
WORKDIR /app
COPY --from=builder /app/target/worker-jar-with-dependencies.jar app.jar

RUN addgroup -S jre && adduser -S jre -G jre
USER jre

ENTRYPOINT ["java", "-jar", "app.jar"]
