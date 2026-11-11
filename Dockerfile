# ---- Development ----
FROM eclipse-temurin:21-jdk-alpine AS development

WORKDIR /app

# Cache dependencies in their own layer
COPY .mvn/ .mvn/
COPY mvnw pom.xml ./
RUN chmod +x mvnw
RUN --mount=type=cache,target=/root/.m2 ./mvnw -B dependency:go-offline

COPY . .

EXPOSE 4000

# Source is bind-mounted by docker-compose for live reload
CMD ["./mvnw", "spring-boot:run"]


# ---- Build ----
FROM eclipse-temurin:21-jdk-alpine AS builder

WORKDIR /app

COPY .mvn/ .mvn/
COPY mvnw pom.xml ./
RUN chmod +x mvnw
RUN --mount=type=cache,target=/root/.m2 ./mvnw -B dependency:go-offline

COPY src ./src
RUN --mount=type=cache,target=/root/.m2 ./mvnw -B clean package -DskipTests


# ---- Production ----
FROM eclipse-temurin:21-jre-alpine AS production

WORKDIR /app

RUN addgroup --system --gid 1001 spring \
    && adduser --system --uid 1001 --ingroup spring spring

# The single executable jar (Flyway migrations are packaged inside it)
COPY --from=builder /app/target/*.jar app.jar

USER spring

EXPOSE 4000

HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
  CMD wget -qO- http://localhost:4000/api/actuator/health || exit 1

ENTRYPOINT ["java", "-XX:MaxRAMPercentage=75", "-jar", "app.jar"]