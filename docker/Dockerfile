# Build stage
FROM maven:3.9.9-eclipse-temurin-17 AS builder
WORKDIR /workspace
COPY app/pom.xml ./pom.xml
COPY app/src ./src
RUN mvn -B -DskipTests package

# Runtime stage
FROM eclipse-temurin:17-jre-jammy
WORKDIR /app
RUN groupadd --system appgroup && useradd --system --gid appgroup appuser
COPY --from=builder --chown=appuser:appgroup /workspace/target/k8s-demo-app.jar app.jar
USER appuser
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
