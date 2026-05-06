## 1. 구문 분석 및 작동 원리

이 트리거의 각 요소가 의미하는 바는 다음과 같습니다.

- **`on: push`**: 저장소에 `git push` 이벤트(직접 푸시 또는 PR 머지)가 발생할 때 트리거를 감지합니다.
- **`paths:`**: 푸시된 커밋들에 포함된 **파일 변경 내역(diff)**을 확인하라는 조건입니다.
- **`['qt-host/6.7.3/VERSION']`**: 변경된 파일 목록 중 정확히 이 경로의 파일이 포함되어 있어야만 워크플로우가 실행됩니다.

---

## 2. 왜 이 방식을 사용하는가? (전략적 이점)

### 독립적인 배포 주기 (Decoupling)

`cross-build` 이미지의 소스를 수정했을 때, 전혀 상관없는 `qt-host/6.8.3` 이미지가 다시 빌드될 필요는 없습니다. `paths` 필터를 사용하면 **수정된 컴포넌트만 정확히 빌드**할 수 있습니다.

### 리소스 최적화

Self-hosted runner를 사용하신다면 하드웨어 자원이 한정적일 것입니다. 모든 푸시마다 4~5개의 도커 이미지를 동시에 빌드하는 대신, 필요한 이미지만 빌드하여 Runner의 부하를 줄이고 큐 대기 시간을 단축합니다.

### 버전 관리의 명확성

`VERSION` 파일의 내용을 수정하고 커밋하는 행위 자체가 "새로운 버전을 릴리스하겠다"는 명시적인 신호가 됩니다. 소스 코드를 수정 중일 때는 빌드를 건너뛰고, 최종적으로 `VERSION` 파일만 업데이트하여 최종 이미지를 생성하는 워크플로우 제어가 가능합니다.

---

## 3. 확장된 패턴 매칭 (Wildcards)

단일 파일 외에도 다양한 패턴을 사용할 수 있습니다.

- **특정 디렉토리 전체 감지:** `qt-host/6.7.3/**` (해당 폴더 내 어떤 파일이 바뀌어도 빌드)
- **특정 확장자 제외:** `!qt-host/6.7.3/*.md` (문서 파일 수정은 빌드에서 제외)
- **다중 경로 설정:**
  ```yaml
  paths:
    - "qt-host/6.7.3/VERSION"
    - "qt-host/6.7.3/Dockerfile"
    - "common/scripts/**"
  ```

---

## 4. 실전 워크플로우 구성 예시

`qt-host/6.7.3/VERSION`이 변경되었을 때, 해당 파일의 내용을 읽어 도커 태그로 사용하는 전체 예시입니다.

```yaml
name: Build Qt Host 6.7.3

on:
  push:
    branches: [main]
    paths:
      - "qt-host/6.7.3/VERSION"

jobs:
  build:
    runs-on: self-hosted
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Get Version
        id: get_version
        run: echo "VERSION=$(cat qt-host/6.7.3/VERSION)" >> $GITHUB_OUTPUT

      - name: Build and Push Docker Image
        run: |
          docker build -t my-registry/qt-host:${{ steps.get_version.outputs.VERSION }} ./qt-host/6.7.3
          docker push my-registry/qt-host:${{ steps.get_version.outputs.VERSION }}
```

---

## 5. 주의사항

1.  **Tag Push와의 관계:** `on: push: tags:`와 `paths:`를 동시에 사용하면 두 조건이 **OR**가 아닌 **AND**로 작동할 수 있으므로, 태그 기반 빌드와 경로 기반 빌드는 별도의 워크플로우 파일로 분리하는 것이 관리하기 편합니다.
2.  **경로 정확성:** 경로는 저장소 루트(Root)를 기준으로 합니다. 오타가 발생하면 워크플로우가 아예 실행되지 않으므로 주의가 필요합니다.
3.  **대량 푸시:** 여러 디렉토리를 동시에 수정하여 푸시하면, 각 디렉토리에 해당하는 모든 워크플로우가 병렬로 실행됩니다.

---

> **참고 자료:** [GitHub Actions 공식 문서 - Workflow syntax: on.push.paths](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions#onpushpull_requestpull_request_targetpaths)

이 `VERSION` 파일 관리 방식을 적용할 때, 혹시 `qt-host` 이미지 빌드 전 단계에서 `cross-build` 이미지의 최신 상태를 체크해야 하는 의존성 로직도 필요하신가요?

```

```
