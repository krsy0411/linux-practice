# ---------------------------------------------------------
# 1단계: 빌드 스테이지 (이름을 'builder'라고 정의)
# ---------------------------------------------------------

# --platform=linux/amd64 -> Apple Silicon(M1, M2) 맥 환경에서도 인텔/AMD 서버용 이미지를 생성하도록 강제
FROM --platform=linux/amd64 gradle:8.4-jdk17 AS builder

# 컨테이너 내에서 명령어가 실행될 기본 디렉토리를 /workspace로 설정
WORKDIR /workspace

# --chown=gradle:gradle: 보안을 위해 파일 권한을 gradle 사용자에게 부여하며 복사
# . /workspace: 현재 내 컴퓨터의 프로젝트 소스 전체를 컨테이너의 /workspace로 복사
COPY --chown=gradle:gradle . /workspace

# ./gradlew bootJar: 스프링 부트 실행 파일(JAR)을 빌드함
# -x test: 빌드 시 테스트 과정을 생략해서 시간을 단축함
# --no-daemon: 컨테이너 환경이므로 일회성 빌드를 위해 데몬 프로세스를 띄우지 않음
RUN ./gradlew bootJar -x test --no-daemon

# ---------------------------------------------------------
# 2단계: 실행 스테이지 (최종 이미지)
# ---------------------------------------------------------

# eclipse-temurin:17-jre-jammy: 빌드 도구(Gradle)는 빼고, 실행에 필요한 JRE만 포함된 가벼운 이미지 사용
FROM eclipse-temurin:17-jre-jammy

# 컨테이너 내 실행 디렉토리를 /app으로 설정
WORKDIR /app

# --from=builder: 위에서 정의한 'builder' 스테이지에서 생성된 파일만 가져옴
# /workspace/build/libs/*.jar: 빌드 결과물인 JAR 파일을
# app.jar: 현재 위치(/app)에 app.jar라는 이름으로 복사 (빌드용 찌꺼기는 버리고 결과물만 챙김)
COPY --from=builder /workspace/build/libs/*.jar app.jar

# 컨테이너가 8080 포트를 사용한다는 것을 문서화함 (실제 포트 개방은 실행 시 -p 옵션 필요)
EXPOSE 8080

# 컨테이너가 시작될 때 실행할 명령어: "java -jar app.jar"
ENTRYPOINT ["java","-jar","app.jar"]