# 1. 가장 가벼운 베이스 선택
FROM scratch

# 2. 파일 서버에서 압축 파일을 다운로드하며 해제
# 만약 tar 내부에 'Qt/' 폴더가 바로 있다면 아래 경로가 맞습니다.
ADD http://docker-reg.posod.com:8080/qt_6.7.3_arm_backup.tar.gz /l4t/targetfs/opt/

# 3. 중요: 이 경로를 다른 컨테이너가 '볼륨'으로 인식하도록 선언
VOLUME ["/l4t/targetfs/opt/Qt"]

# 4. 'docker create' 에러 방지를 위한 더미 명령
CMD ["/"]