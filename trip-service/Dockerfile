# file: trip-service/Dockerfile

# Stage 1: Build
FROM maven:3.9-eclipse-temurin-21-alpine AS builder
WORKDIR /workspace
COPY pom.xml .
COPY src src
RUN mvn package -DskipTests

# Stage 2: Production
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app
# Port đã thống nhất
EXPOSE 8081
COPY --from=builder /workspace/target/*.jar app.jar
CMD ["java", "-jar", "app.jar"]