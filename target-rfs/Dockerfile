# 1. 이미 rootfs가 포함된 베이스 이미지 사용
FROM docker-reg.posod.com:5000/deepstream7.1-arm:v0.1

# 2. 추가 패키지(업데이트분)만 복사
# 만약 libssl_update.tar.gz 내부에 targetfs/ 로 시작하는 경로가 있다면 아래와 같이 사용
ADD libssl_dev_arm.tar.gz /l4t/

# 3. 기존 볼륨 및 커맨드 유지
VOLUME ["/l4t/targetfs"]
CMD ["/"]