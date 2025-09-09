# AKI의 AWS Ansible 프로젝트 계획

## 1. 프로젝트 목표

Terraform을 사용하여 고가용성 AWS 인프라를 코드로 구축하고, Ansible을 사용하여 해당 인프라에 Docker 기반의 모니터링 시스템(Prometheus, Grafana)을 배포 및 관리한다. 최종적으로 **모니터링 서버(프라이빗 서브넷)**에 위치한 Grafana 대시보드에 SSH 터널링을 통해 안전하게 접속하는 것을 목표로 한다.

---

## 2.1. 프로젝트 디렉터리 구조

- **`IaC/`**: 모든 인프라 자동화(IaC) 관련 코드를 포함합니다.
  - `TERRAFORM/`: AWS 인프라 정의
  - `ANSIBLE/`: 서버 설정 및 소프트웨어 배포
- **`APP/`**: 배포될 애플리케이션 소스 코드 (예: `my-python-app/`)
- **`LOAD_TESTING/`**: 부하 테스트 시나리오 스크립트 (예: `k6-scripts/`)
- **`scripts/`**: SSH 터널링과 같은 보조 스크립트

## 2.2. 현재 아키텍처 (Terraform으로 정의됨)

- **VPC**: 1개
- **가용 영역 (AZ)**: 2개 (ap-northeast-2a, ap-northeast-2c)
- **서브넷**: 총 4개
  - 퍼블릭 서브넷 2개 (각 AZ에 1개씩)
  - 프라이빗 서브넷 2개 (각 AZ에 1개씩)
- **EC2 인스턴스**: 총 4대 (t3.micro, Ubuntu 22.04)
  - **배스천 호스트 1대**: 외부 SSH 접속 관문, Ansible 제어 노드, 부하 테스트 시작점
  - **애플리케이션 서버 2대**: 샘플 애플리케이션 실행
  - **모니터링 서버 1대**: Docker 기반 모니터링 시스템(Prometheus/Grafana) 실행

---

## 3. Phase 1: 모니터링 시스템 구축 (완료)

1.  **Terraform 프로젝트 구조 설정**: `main.tf`, `network.tf`, `security.tf`, `ec2.tf`, `variables.tf`로 기능별 파일 분리 완료.
2.  **Terraform 코드로 인프라 정의 완료**: 위의 아키텍처에 해당하는 모든 리소스(VPC, Subnet, IGW, NAT GW, RT, EC2, SG) 코드 작성 완료.
3.  **Ansible 설정 및 역할 분리**: `inventory.ini`, `ansible.cfg`, `group_vars` 및 `roles` 구조 설정 완료.
4.  **모니터링 시스템 배포 완료**: `deploy-monitoring.yml` 플레이북을 통해 모든 서버에 Node Exporter, 모니터링 서버에 Prometheus/Grafana 배포 및 검증 완료.
5.  **Grafana 접속 확인**: `connect_monitoring_tunnel.sh` 스크립트를 통해 SSH 터널링 접속 및 대시보드 기본 설정(데이터 소스 추가, 대시보드 Import) 완료.

---

## 4. Phase 2: 샘플 앱 배포 및 부하 테스트 (완료)

1.  **프로젝트 구조 개선**: 소스 코드 관리를 위해 루트에 `APP` 및 `LOAD_TESTING` 디렉터리를 추가하고, 그 안에 `my-python-app/`, `k6-scripts/`와 같이 종류별로 하위 디렉터리를 구성하여 모듈화를 강화함.
2.  **샘플 앱 Dockerize**: CPU 부하를 유발하는 Python Flask 앱(`app.py`)을 작성하고, `Dockerfile` 및 `requirements.txt`를 통해 컨테이너 이미지로 빌드할 수 있도록 구성함.
3.  **Docker Compose 앱 정의**: `docker-compose.app.yml` 파일을 작성하여 Dockerize된 앱의 실행 방식을 정의함.
4.  **Ansible 배포 플레이북 작성**: `deploy-app-docker.yml`을 작성하여 `app_servers` 그룹 전체에 Docker 기반 앱을 배포하도록 구현함. (사용자의 제안에 따라 기존 계획을 더 나은 방식으로 수정)
5.  **부하 테스트 도구 설치**: `k6` 설치 플레이북(`install-k6.yml`)을 작성하고, 여러 번의 GPG 키 오류를 해결하며 최종적으로 배스천 호스트에 `k6` 설치를 완료함.
6.  **부하 테스트 준비 및 실행**: `prepare-load-test.yml`을 통해 테스트 스크립트를 배스천 호스트에 복사하고, 실제 부하 테스트를 실행하여 Grafana 대시보드에서 `app_servers`의 CPU 사용량 변화를 관찰함.
7.  **Ansible 코드 모듈화**: 배포 과정을 일반화하기 위해 `deploy_compose_stack`이라는 재사용 가능한 역할을 생성함. 여러 번의 디버깅을 통해 `docker_container` 모듈을 사용하여 기존 컨테이너를 안정적으로 제거하는 로직을 구현하며 리팩토링을 완료함.
8.  **전체 배포 오케스트레이션**: `deploy-all.yml` 플레이북을 생성하여 모든 개별 배포 플레이북을 단일 명령으로 실행할 수 있도록 통합함. (실행 스크립트: `deploy.sh`)

---

## 5. 향후 개선 방안

### 5.1. Grafana 접속 방식 개선

현재 Grafana 대시보드는 SSH 터널링으로 접속합니다. 향후 다음과 같은 대안을 고려할 수 있습니다.

1.  **AWS Systems Manager (SSM) 포트 포워딩**
2.  **VPN (Virtual Private Network) 구축**
3.  **Application Load Balancer (ALB) 또는 Reverse Proxy**

### 5.2. CI/CD 파이프라인 구축

- GitHub Actions와 같은 도구를 사용하여, `APP` 디렉터리의 코드가 변경되면 자동으로 Docker 이미지를 빌드하고 Amazon ECR과 같은 레지스트리에 푸시한 후, Ansible 또는 다른 배포 도구를 트리거하여 자동으로 앱을 업데이트하는 파이프라인을 구축할 수 있습니다.

### 5.3. Ansible Vault를 이용한 민감 정보 관리

- 현재는 키 파일 경로 등이 코드로 노출되어 있습니다. Ansible Vault를 사용하여 암호나 API 키와 같은 민감한 정보를 암호화하여 안전하게 관리할 수 있습니다.