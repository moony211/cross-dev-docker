## 수정된 계획

### 목표

- GitHub Runner 서버에서 Docker 이미지를 빌드하고 `docker-reg.posod.com:5000` 레지스트리에 푸시
- 빌드 시 `http://docker-reg.posod.com:8080`에서 아카이브를 직접 가져오도록 Dockerfile을 구성
- 워크플로우로 수동 실행과 반복 실행 모두 지원

### 구성

1. Dockerfile에서 HTTP `ADD` 사용
   - `qt-host`, `qt-target`, `target-rfs` Dockerfile에 `ADD http://docker-reg.posod.com:8080/<archive> ...` 추가
   - Docker 데몬이 빌드 중 URL을 직접 다운로드함

2. `scripts/build-and-push-images.sh`
   - 이미지 목록과 태그를 정의
   - 각 서브디렉터리에서 `docker build` 실행
   - `docker push`로 레지스트리에 업로드
   - `IMAGE_TAG` 기본값 `latest`, `DOCKER_USERNAME`/`DOCKER_PASSWORD`가 설정된 경우 로그인 수행
   - `DRY_RUN=1` 옵션으로 명령 확인 가능

3. `.github/workflows/docker-build-push.yml`
   - `runs-on: [self-hosted, linux]`
   - `workflow_dispatch`로 수동 실행
   - repo 체크아웃 후 스크립트 실행

### 빌드 대상

- `jetpack-cross-dev/Dockerfile`
- `qt-host/6.7.3/Dockerfile`
- `qt-host/6.8.3/Dockerfile`
- `qt-target/6.7.3/Dockerfile`
- `qt-target/6.8.3/Dockerfile`
- `target-rfs/Dockerfile`

### 핵심 고려 사항

- `ADD http://...`는 Docker 데몬이 직접 HTTP에서 파일을 다운로드함
- 빌드 호스트가 `docker-reg.posod.com:8080`에 접근 가능해야 함
- 레지스트리에 푸시하기 위해 `docker-reg.posod.com:5000` 접근 필요
- 빌드 캐시 갱신이 필요하면 `--no-cache` 또는 `DRY_RUN` 확인 후 옵션 추가

### 검증

- `DRY_RUN=1 IMAGE_TAG=test ./scripts/build-and-push-images.sh` 로 명령 흐름 확인
- 실제 빌드/푸시 실행은 Runner에서 `workflow_dispatch` 또는 스크립트 직접 실행
