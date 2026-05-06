효율적인 도커 이미지 관리와 GitHub Runner 연동을 위해 **단일 저장소(Monorepo) 구조**를 제안한다. 4가지 이미지의 역할이 다르더라도, cross-build 환경과 Qt 설정은 서로 의존성을 가지는 경우가 많기 때문이다.

---

## 1. 저장소 디렉토리 구조

각 이미지의 역할을 명확히 분리하고, Qt 버전별 차이를 관리하기 위해 아래와 같은 구조를 권장한다.

```text
docker-dev-env/
├── .github/
│   └── workflows/          # GitHub Actions 정의
├── base/                   # 공통 기반 이미지 (OS, 필수 패키지)
├── cross-build/            # Toolchain 기반 이미지
├── target-rootfs/          # Target 시스템 라이브러리 및 환경
├── qt-host/                # Qt Host 빌드 도구 (6.7.3, 6.8.3 등)
│   ├── 6.7.3/
│   └── 6.8.3/
└── qt-target/              # Qt Target 빌드용 이미지
    ├── 6.7.3/
    └── 6.8.3/
```

---

## 2. 이미지 의존성 및 계층화

이미지 간의 상속 관계를 설정하여 중복 빌드를 줄이고 일관성을 유지해야 한다.

- **Layer 1 (Base):** 공통 OS 패키지 설치.
- **Layer 2-A (Cross-build):** Base를 상속받아 호스트용 컴파일러(GCC/Clang) 및 Cross-toolchain 설치.
- **Layer 2-B (Target-rootfs):** Target 보드에서 추출하거나 구성한 rootfs 이미지.
- **Layer 3-A (Qt-Host):** Cross-build를 상속받아 특정 버전의 Qt 소스를 호스트 환경에 맞게 빌드/설치.
- **Layer 3-B (Qt-Target):** Target-rootfs와 Cross-build를 연동하여 Qt 라이브러리를 Target용으로 교차 컴파일한 결과물 포함.

---

## 3. GitHub Actions 및 Self-hosted Runner 활용 전략

### Matrix Strategy 사용

Qt 6.7.3과 6.8.3처럼 버전만 다른 경우, GitHub Actions의 `matrix` 기능을 활용하면 하나의 워크플로우 파일로 여러 이미지를 동시 빌드할 수 있다.

```yaml
jobs:
  build-qt:
    runs-on: self-hosted
    strategy:
      matrix:
        version: [6.7.3, 6.8.3]
    steps:
      - name: Build Qt Host Image
        run: |
          docker build -t my-reg/qt-host:${{ matrix.version }} ./qt-host/${{ matrix.version }}
```

### Self-hosted Runner 최적화

1.  **Local Cache 활용:** `actions/cache` 대신 Runner 서버의 로컬 디스크 용량이 충분하다면, Docker의 내장 캐시 기능을 그대로 사용하여 빌드 속도를 높인다.
2.  **Docker Registry 운영:** 빌드된 이미지는 GitHub Packages(GHCR) 또는 사내 Private Registry에 업로드하여 Runner 간 공유가 가능하게 한다.
3.  **병렬 빌드 제어:** Self-hosted Runner의 CPU/RAM 리소스가 한정적이라면 `concurrency` 설정을 통해 동시 빌드 개수를 제한한다.

---

## 4. 버전 관리 및 태그 전략

이미지 태그는 명시적으로 관리하여 혼선을 방지해야 한다.

- **Naming Convention:** `{이미지명}:{버전}-{날짜/해시}`
  - 예: `qt-host:6.7.3-20260506`
  - 예: `qt-target:6.8.3-v1.0`
- **Latest 태그 주의:** `latest` 태그는 항상 가장 최근에 성공한 stable 빌드를 가리키도록 자동 업데이트하되, 개발 환경에서는 고정된 버전 태그를 사용하는 것이 안전하다.

---

## 5. 관리 포인트 제언

- **Dockerfile 템플릿화:** Qt 버전별로 Dockerfile 내용이 거의 같다면, `ARG` 명령어를 적극 활용하여 하나의 Dockerfile에서 빌드 시점에 버전 번호를 주입받도록 구성하는 것이 유지보수에 유리하다.
- **의존성 트리거:** `base` 이미지가 변경되었을 때 하위 이미지(`cross`, `qt`)들이 자동으로 재빌드되도록 `on: push: paths:` 설정을 세밀하게 조정해야 한다.

이 구조를 적용하면 Qt 버전 확장이 용이하고, Self-hosted Runner를 통해 대규모 빌드 리소스를 효율적으로 제어할 수 있다. 구체적인 Dockerfile 작성 예시나 CI 스크립트가 필요한 부분이 있다면 추가 정보를 요청하기 바란다.
