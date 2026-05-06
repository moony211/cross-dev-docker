# Docker 이미지 빌드 및 푸시 워크플로우

이 문서는 `scripts/build-and-push-images.sh` 스크립트의 동작 방식과 Docker 이미지 빌드 및 배포 워크플로우를 설명합니다.

## 개요

이 스크립트는 프로젝트 내의 여러 Docker 이미지를 자동으로 빌드하고 지정된 Docker 레지스트리에 푸시하는 역할을 합니다.

## 주요 설정 (환경 변수)

스크립트는 다음과 같은 환경 변수를 사용하여 동작을 제어합니다.

- `REGISTRY_HOST`: 이미지가 푸시될 Docker 레지스트리 주소 (기본값: `docker-reg.posod.com:5000`)
- `IMAGE_TAG`: 이미지에 부여할 태그 (기본값: `latest`)
- `DOCKER_USERNAME`: 레지스트리 인증을 위한 사용자 이름
- `DOCKER_PASSWORD`: 레지스트리 인증을 위한 비밀번호
- `DRY_RUN`: `1` 또는 `true`로 설정 시 실제 명령을 실행하지 않고 출력만 수행

## 워크플로우 단계

### 1. 초기화 및 모드 설정
- `DRY_RUN` 변수를 확인하여 실제 실행(`dry_run=false`) 또는 테스트 출력(`dry_run=true`) 모드를 결정합니다.

### 2. 레지스트리 인증
- `DOCKER_USERNAME`과 `DOCKER_PASSWORD`가 제공된 경우, `docker login`을 통해 지정된 `REGISTRY_HOST`에 인증을 시도합니다.

### 3. 빌드 타겟 정의
- 스크립트 내부에 빌드할 이미지 목록(`build_targets`)이 정의되어 있습니다. 각 항목은 `[소스 디렉토리 경로] [레지스트리 리포지토리 이름]` 형식을 가집니다.
- 현재 정의된 타겟:
  - `jetpack-cross-dev`
  - `qt-host` (6.7.3, 6.8.3)
  - `qt-target` (6.7.3, 6.8.3)
  - `target-rfs`

### 4. 반복 빌드 및 푸시
정의된 각 타겟에 대해 다음 과정을 반복합니다.

1. **이미지 이름 생성**: `REGISTRY_HOST/repo:IMAGE_TAG` 형식으로 전체 이미지 이름을 생성합니다.
2. **Docker 빌드**: 해당 경로의 `Dockerfile`을 사용하여 이미지를 빌드합니다. `--pull` 옵션을 사용하여 항상 최신 베이스 이미지를 가져옵니다.
3. **Docker 푸시**: 빌드된 이미지를 원격 레지스트리에 업로드합니다.

## 실행 예시

```bash
# 기본 설정으로 빌드 및 푸시
./scripts/build-and-push-images.sh

# 특정 태그와 레지스트리 사용
REGISTRY_HOST=my-registry.com IMAGE_TAG=v1.0.0 ./scripts/build-and-push-images.sh

# 드라이 런 모드로 확인만 수행
DRY_RUN=1 ./scripts/build-and-push-images.sh
```
