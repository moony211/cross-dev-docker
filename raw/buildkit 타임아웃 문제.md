`docker buildx inspect --bootstrap` 과정에서 발생한 `context deadline exceeded` 에러는 **BuildKit 전용 컨테이너를 생성하고 구동하는 과정에서 타임아웃이 발생**했음을 의미합니다.

주로 Self-hosted Runner의 리소스 부족, Docker 데몬의 일시적 응답 지연, 또는 외부 이미지(`moby/buildkit`)를 다운로드하는 속도가 느릴 때 발생합니다.

하지만, **호스트(`/etc/docker/daemon.json`)에 이미 `insecure-registries` 설정이 되어 있는 것을 확인했습니다.** 이 경우 굳이 복잡한 `buildx` 컨테이너 빌더를 별도로 생성하지 않고, **호스트의 Docker 엔진을 직접 사용하는 것이 훨씬 빠르고 안정적**입니다.

### 해결책: 레거시 빌더(Legacy Builder) 사용

가장 확실하고 간단한 방법은 Docker 24.x에서 기본으로 켜져 있는 BuildKit을 끄고 빌드하는 것입니다. 이렇게 하면 호스트의 `daemon.json` 설정을 100% 참조하며, 타임아웃 에러도 발생하지 않습니다.

---

### 수정된 GitHub Actions YAML (최종 안정화 버전)

`Set up Docker Buildx` 단계를 삭제하고, 빌드 명령 앞에 `DOCKER_BUILDKIT=0`을 추가했습니다.

```yaml
name: Docker Build and Push

on:
  push:
    branches: [main]
    paths:
      - "jetpack-cross-dev/VERSION"
      - "qt-host/6.7.3/VERSION"
      - "qt-host/6.8.3/VERSION"
      - "qt-target/6.7.3/VERSION"
      - "qt-target/6.8.3/VERSION"
      - "target-rfs/VERSION"
  workflow_dispatch:
    inputs:
      image-tag:
        description: "Default image tag (if VERSION file is missing)"
        required: false
        default: "latest"

jobs:
  build:
    runs-on: [self-hosted, linux]
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4
        with:
          # Git diff 시 'bad object' 에러를 방지하기 위해 전체 히스토리를 가져옵니다.
          fetch-depth: 0

      - name: Build and push images
        run: |
          chmod +x scripts/build-and-push-images.sh

          TARGETS=""
          if [ "${{ github.event_name }}" == "push" ]; then
            # 이전 커밋과 현재 커밋을 비교하여 변경된 디렉토리를 찾습니다.
            CHANGED_FILES=$(git diff --name-only ${{ github.event.before }} ${{ github.event.after }} | grep 'VERSION$' || true)
            if [ -n "$CHANGED_FILES" ]; then
              for file in $CHANGED_FILES; do
                TARGETS="$TARGETS $(dirname $file)"
              done
            fi
          elif [ "${{ github.event_name }}" == "workflow_dispatch" ]; then
            export IMAGE_TAG="${{ github.event.inputs.image-tag }}"
          fi

          echo "Target directories to build: $TARGETS"

          # DOCKER_BUILDKIT=0 설정을 통해 호스트의 daemon.json 설정을 그대로 사용하도록 합니다.
          # 이는 'server gave HTTP response' 에러와 'context deadline exceeded' 에러를 동시에 해결합니다.
          DOCKER_BUILDKIT=0 ./scripts/build-and-push-images.sh $TARGETS
        env:
          REGISTRY_HOST: docker-reg.posod.com:5000
          DOCKER_USERNAME: ${{ secrets.DOCKER_USERNAME }}
          DOCKER_PASSWORD: ${{ secrets.DOCKER_PASSWORD }}
```

---

### 왜 이 방법이 더 좋은가요?

1.  **안정성:** `buildx create`처럼 새로운 컨테이너를 띄우는 과정이 없으므로 타임아웃(`context deadline exceeded`)이 발생하지 않습니다.
2.  **설정 공유:** 이미 호스트 머신에 `daemon.json`으로 `insecure-registries` 설정을 하셨기 때문에, `DOCKER_BUILDKIT=0` 모드에서는 이 설정을 즉시 인식하여 HTTP 통신을 수행합니다.
3.  **속도:** 빌드 엔진을 초기화하기 위해 외부 이미지를 풀링할 필요가 없어 빌드 시작 시간이 단축됩니다.

### 주의사항

- `DOCKER_BUILDKIT=0`을 사용하면 BuildKit의 고급 기능(병렬 빌드 최적화 등)은 사용할 수 없지만, 현재 시도하시는 일반적인 이미지 빌드와 푸시 작업에는 전혀 지장이 없습니다.
- 만약 여전히 `fatal: bad object` 에러가 발생한다면, 이는 푸시한 브랜치 히스토리가 꼬였을 때 발생할 수 있습니다. 그럴 때는 `git diff` 대상 범위를 조정하는 로직이 필요할 수 있으나, 우선 위 YAML로 테스트해보시길 권장합니다.
