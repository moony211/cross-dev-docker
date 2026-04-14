# 1. 가장 가벼운 베이스 선택
FROM scratch

# 2. 압축 파일을 복사하며 해제
# 만약 tar 내부에 'Qt/' 폴더가 바로 있다면 아래 경로가 맞습니다.
ADD jetson_orin_nx_rfs_1.tar.gz /l4t/

# 3. 중요: 이 경로를 다른 컨테이너가 '볼륨'으로 인식하도록 선언
VOLUME ["/l4t/targetfs"]

# 4. 'docker create' 에러 방지를 위한 더미 명령
CMD ["/"]