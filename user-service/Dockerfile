# file: user-service/Dockerfile

# Stage 1: Build
FROM eclipse-temurin:21-jdk-alpine AS builder
WORKDIR /workspace
COPY mvnw .
COPY .mvn .mvn
COPY pom.xml .
COPY src src
RUN ./mvnw package -DskipTests

# Stage 2: Production
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app
# Port đã thống nhất
EXPOSE 8080
COPY --from=builder /workspace/target/*.jar app.jar
CMD ["java", "-jar", "app.jar"]