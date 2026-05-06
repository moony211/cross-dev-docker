# 이미지 버전 관리 및 배포 자동화 전략

## 1. 개요

본 문서는 단일 저장소(Monorepo) 구조에서 여러 도커 이미지의 버전을 독립적으로 관리하고, GitHub Actions를 통해 효율적으로 배포하기 위한 전략을 설명합니다.

## 2. 핵심 관리 원칙

### 2.1 디렉토리별 `VERSION` 파일 관리

각 도커 이미지 프로젝트 디렉토리에 독립적인 `VERSION` 파일을 유지하여 컴포넌트별 생명주기를 완전히 분리합니다.

- **구조 예시:**
  ```text
  qt-host/
  ├── 6.7.3/
  │   ├── Dockerfile
  │   └── VERSION      # 내용: v1.0
  └── 6.8.3/
      ├── Dockerfile
      └── VERSION      # 내용: v1.1
  ```
- **운영 방식:** 개발자가 `VERSION` 파일의 내용을 수정하고 커밋하는 행위 자체가 "새로운 버전을 릴리스하겠다"는 명시적인 신호로 간주됩니다.

### 2.2 태깅 전략 (Tagging Strategy)

Git 태그에만 의존하는 방식 대신, 파일 시스템 기반의 버전을 조합하여 명확한 이미지 식별을 보장합니다.

- **Naming Convention:** `{이미지명}:{버전}`
  - 예: `qt-host:6.7.3-v1.0`
- **불변 태그 사용:** 특정 시점의 빌드를 고유하게 식별하기 위해 `VERSION` 파일의 내용과 필요 시 Git Commit SHA를 조합하여 태깅합니다.

## 3. 배포 자동화 (GitHub Actions)

### 3.1 `on.push.paths` 트리거 활용

GitHub Actions의 `paths` 필터를 사용하여 변경이 발생한 컴포넌트만 정확히 타겟팅하여 빌드 및 배포를 수행합니다.

- **워크플로우 설정 예시:**
  ```yaml
  on:
    push:
      branches: [main]
      paths:
        - "qt-host/6.7.3/VERSION"
        - "qt-host/6.7.3/**" # 해당 디렉토리 내 모든 변경 감지
  ```

### 3.2 전략적 이점

1.  **독립적인 배포 주기 (Decoupling):** `cross-build` 이미지의 수정이 상관없는 `qt-host` 이미지의 재빌드를 유발하지 않습니다.
2.  **리소스 최적화:** Self-hosted Runner 자원을 필요한 빌드에만 집중적으로 할당하여 효율성을 극대화합니다.
3.  **버전 관리의 명확성:** 소스 코드 수정 단계와 릴리스(Version Update) 단계를 분리하여 워크플로우 제어가 용이합니다.

## 4. 권장 워크플로우

1.  **개발 단계:** `Dockerfile` 및 소스 코드를 수정하고 PR을 통해 검증을 진행합니다.
2.  **릴리스 결정:** 배포 준비가 완료되면 해당 디렉토리의 `VERSION` 파일을 업데이트합니다.
3.  **자동 배포:** `VERSION` 파일 변경을 감지한 GitHub Actions가 동작하여 해당 버전 번호로 이미지를 빌드하고 레지스트리에 푸시합니다.

---

**참고 문서:**

- [GitHub Actions - Workflow syntax: paths](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions#onpushpull_requestpull_request_targetpaths)
- 프로젝트 내 `@raw` 자료 (Git 태그 미의존 전략, Monorepo 구조 제안 등)
