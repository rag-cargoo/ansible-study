# AWS, Ansible, Terraform 프로젝트: 모니터링 시스템 및 부하 테스트

## 1. 프로젝트 개요

이 프로젝트는 Terraform을 사용하여 AWS 클라우드에 고가용성 인프라를 코드로 프로비저닝하고, Ansible을 사용하여 다음 두 가지를 배포 및 관리하는 방법을 보여줍니다.

1.  **Docker 기반 모니터링 시스템 (Prometheus, Grafana)**
2.  **부하 테스트를 위한 샘플 애플리케이션**

모범 사례에 따라 모든 서비스(모니터링, 앱)를 프라이빗 서브넷에 배치하고, 배스천 호스트를 통해 안전하게 접근하고 제어하는 아키텍처를 구현합니다.

## 2. 프로젝트 구조

이 프로젝트는 역할에 따라 다음과 같이 디렉터리를 분리합니다.

- **`IaC/TERRAFORM/`**: AWS 인프라(VPC, EC2, 보안 그룹 등)를 정의하는 코드.
- **`IaC/ANSIBLE/`**: 서버 설정 및 소프트웨어 배포를 자동화하는 코드.
- **`APP/`**: 배포될 애플리케이션 소스 코드를 종류별로 관리합니다.
  - `my-python-app/`: 샘플 Python 웹 애플리케이션 (현재)
- **`LOAD_TESTING/`**: 부하 테스트 시나리오 스크립트를 도구별로 관리합니다.
  - `k6-scripts/`: `k6` 부하 테스트 스크립트 (현재)
- **`scripts/`**: SSH 터널링과 같은 보조 스크립트.

## 3. 아키텍처 및 배포 구성

이 프로젝트는 다음 EC2 인스턴스에 각 구성 요소를 배포합니다:

- **배스천 호스트 (Public Subnet):**
  - Ansible 제어 노드
  - `k6` 부하 테스트 도구
  - SSH 터널링 시작점

- **애플리케이션 서버 2대 (Private Subnet):**
  - 샘플 Python 웹 애플리케이션 (Docker 컨테이너)
  - Node Exporter (시스템 지표 수집)

- **모니터링 서버 (Private Subnet):**
  - Prometheus (모니터링 데이터 저장)
  - Grafana (대시보드 시각화)
  - Node Exporter (시스템 지표 수집)

## 4. 사전 준비 사항

- AWS 계정 및 AWS CLI 설정
- Terraform, Ansible 로컬 설치
- EC2 접속용 SSH 키 페어 (`~/.aws/key/` 디렉터리에 위치)
- `IaC/TERRAFORM/variables.tf`의 `my_ip` 변수를 자신의 공인 IP로 설정

## 5. 인프라 배포 (Terraform)

`IaC/TERRAFORM` 디렉터리로 이동 후, 다음을 실행합니다.

```bash
terraform init
terraform apply
```

*주의: `apply` 완료 후 출력되는 `bastion_public_ip` 값을 기록해 두세요.*

## 6. Ansible을 이용한 소프트웨어 배포

`terraform apply` 후, `IaC/ANSIBLE` 디렉터리로 이동하여 다음 단계를 진행합니다.

### 6.1. Ansible 인벤토리 업데이트

`IaC/ANSIBLE/inventory.ini` 파일을 열어 `bastion-host`의 `ansible_host`를 위에서 기록한 `bastion_public_ip`로 업데이트합니다.

### 6.2. Ansible 연결 테스트

```bash
ansible -i inventory/inventory.ini all -m ping
```

### 6.3. 모니터링 시스템 배포

Prometheus, Grafana, Node Exporter를 모니터링 서버 및 각 대상 서버에 배포합니다.

```bash
ansible-playbook playbooks/deploy-monitoring.yml
```

### 6.4. 샘플 애플리케이션 배포

`app_servers` 그룹(`a`, `b` 서버)에 Dockerize된 샘플 Python 앱을 배포합니다.

```bash
ansible-playbook playbooks/deploy-app-docker.yml
```

## 7. 부하 테스트 실행 (k6)

배스천 호스트에서 `k6`를 사용하여 프라이빗 서브넷의 앱 서버로 부하를 발생시킵니다.

### 7.1. k6 설치

배스천 호스트에 `k6`를 설치합니다.

```bash
ansible-playbook playbooks/install-k6.yml
```

### 7.2. 테스트 스크립트 준비

로컬의 `LOAD_TESTING/load-test.js` 스크립트를 배스천 호스트로 복사합니다.

```bash
ansible-playbook playbooks/prepare-load-test.yml
```

### 7.3. 테스트 실행 및 대시보드 관찰

이제 모든 준비가 끝났습니다. **Grafana 대시보드를 열어둔 상태**에서, **새로운 터미널**을 열어 배스천 호스트에 접속한 후 아래 명령어를 실행하여 부하 테스트를 시작합니다.

1.  **배스천 호스트 접속:**
    ```bash
    ssh -i ~/.aws/key/test_key.pem ubuntu@<BASTION_PUBLIC_IP>
    ```

2.  **부하 테스트 시작:**
    ```bash
    k6 run /home/ubuntu/load_test/load-test.js
    ```

테스트가 실행되는 동안 Grafana 대시보드에서 `app-server-a`와 `app-server-b`의 CPU 사용률이 급증하는 것을 실시간으로 관찰할 수 있습니다.

## 8. Grafana 대시보드 접속

프라이빗 서브넷의 Grafana에 접속하기 위해 로컬 PC에서 SSH 터널링 스크립트를 실행합니다.

```bash
./scripts/connect_monitoring_tunnel.sh <BASTION_PUBLIC_IP>
```

스크립트 실행 후, 웹 브라우저에서 `http://localhost:3000`으로 접속합니다.

## 9. 리소스 정리 (Terraform Destroy)

모든 작업을 마친 후, `IaC/TERRAFORM` 디렉터리로 이동하여 리소스를 삭제합니다.

```bash
terraform destroy
```