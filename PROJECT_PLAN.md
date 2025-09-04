# AKI의 AWS Ansible 프로젝트 계획

## 1. 프로젝트 목표

Terraform을 사용하여 고가용성 AWS 인프라를 코드로 구축하고, Ansible을 사용하여 해당 인프라에 Docker 기반의 모니터링 시스템(Prometheus, Grafana)을 배포 및 관리한다. 최종적으로 **모니터링 서버(프라이빗 서브넷)**에 위치한 Grafana 대시보드에 SSH 터널링을 통해 안전하게 접속하는 것을 목표로 한다.

---

## 2. 현재 아키텍처 (Terraform으로 정의됨)

- **VPC**: 1개
- **가용 영역 (AZ)**: 2개 (ap-northeast-2a, ap-northeast-2c)
- **서브넷**: 총 4개
  - 퍼블릭 서브넷 2개 (각 AZ에 1개씩)
  - 프라이빗 서브넷 2개 (각 AZ에 1개씩)
- **게이트웨이**:
  - 인터넷 게이트웨이 1개
  - NAT 게이트웨이 1개 (비용 효율성을 위해 AZ A에만 위치)
- **라우팅**:
  - 퍼블릭 라우팅 테이블 1개 (인터넷 게이트웨이 경로 포함)
  - 프라이빗 라우팅 테이블 1개 (NAT 게이트웨이 경로 포함)
- **EC2 인스턴스**: 총 4대 (t3.micro, Ubuntu 22.04)
  - **배스천 호스트 1대 (Terraform 리소스: `aws_instance.public_bastion`)**
    - **위치:** 퍼블릭 서브넷 A (`public_a`)
    - **역할:** 외부 SSH 접속을 위한 관문(Bastion), Ansible 제어 노드
  - **애플리케이션 서버 2대 (Terraform 리소스: `aws_instance.private_app_a`, `aws_instance.private_app_b`)**
    - **위치:** 각각 프라이빗 서브넷 A와 B (`private_a`, `private_b`)에 1대씩
    - **역할:** 외부에서 직접 접근 불가능한 내부 애플리케이션 또는 데이터베이스 서버. Ansible의 최종 관리 대상.
  - **모니터링 서버 1대 (Terraform 리소스: `aws_instance.private_monitoring`)**
    - **위치:** 프라이빗 서브넷 A (`private_a`)
    - **역할:** Docker 기반 모니터링 시스템(Prometheus/Grafana) 실행. 배스천 호스트를 통해서만 접근 가능.
- **보안 그룹**: 1개
  - 모든 IP로부터 HTTP (80) 허용
  - 지정된 IP(`var.my_ip`)로부터 SSH (22) 허용
  - 동일 보안 그룹 내 SSH (22), Grafana (3000), Prometheus (9090) 허용
- **키페어**: `rog_ally_key` (사용자가 AWS 콘솔에 수동으로 등록)

---

## 3. 현재까지 진행 상황 (Progress)

1.  **Terraform 프로젝트 구조 설정**:
    - `main.tf`, `network.tf`, `security.tf`, `ec2.tf`, `variables.tf`로 기능별 파일 분리 완료.
2.  **Terraform 코드 작성 완료**:
    - 위의 아키텍처에 해당하는 모든 리소스(VPC, Subnet, IGW, NAT GW, RT, EC2, SG) 코드 작성 완료.
    - 프로젝트 이름(`AKI`) 및 태그 대문자화 등 커스터마이징 반영 완료.
3.  **Terraform 계획 검증**:
    - `terraform plan`을 통해 모든 리소스가 정상적으로 생성될 계획임을 확인.
4.  **Terraform 및 Ansible 설정 개선 (고정 IP 문제 해결)**:
    - `ec2.tf`에 탄력적 IP(`aws_eip`) 리소스를 추가하여 배스천 호스트가 고정 IP를 갖도록 수정.
    - `ec2.tf`에 `output`을 추가하여 `apply` 시 배스천 호스트의 IP가 화면에 출력되도록 설정.
    - Ansible의 `group_vars/app_servers.yml`에서 하드코딩된 IP를 동적 변수(`hostvars`)로 교체하여 `inventory.ini`만 수정하면 되도록 리팩토링 완료.
5.  **모범 사례 아키텍처로의 전환 및 Ansible 설정 통합**:
    - 모니터링 서버를 프라이빗 서브넷에 별도 EC2 인스턴스(`private_monitoring`)로 분리하여 모범 사례 아키텍처 적용.
    - `ec2.tf`에 `private_monitoring` 인스턴스 추가 및 프라이빗 IP 고정(변수화) 설정.
    - `security.tf`에 배스천-모니터링 간 SSH, Grafana, Prometheus 포트 통신 규칙 추가.
    - Ansible `group_vars` 리팩토링: `ansible_ssh_common_args`를 `group_vars/private_servers.yml`로 통합.
    - Ansible 인벤토리(`inventory.ini`)에 `[private_servers:children]` 그룹 추가 및 `monitoring-host` 정의.
    - 모든 서버(배스천, 앱 서버, 모니터링 서버)에 대한 Ansible 연결 테스트 성공 확인.

---

## 4. 다음 진행할 내용 (Next Steps)

1.  **`terraform apply` 실행 및 인벤토리 업데이트 (완료)**:
    - **주의:** 아래 명령어들은 사용자가 직접 실행해야 합니다.
    - **1단계: 인프라 생성**
      - 터미널에서 `TERRAFORM` 디렉토리로 이동 후 `terraform apply` 명령어를 실행합니다.
    - **2단계: IP 확인 및 복사**
      - 실행 완료 후 `Outputs:` 섹션에 표시되는 `bastion_public_ip` 값을 복사합니다.
      - 예: `bastion_public_ip = "54.180.123.45"`
    - **3단계: Ansible 인벤토리 수정**
      - `ANSIBLE/inventory.ini` 파일을 열어 `[bastion]` 그룹의 `ansible_host` 값을 위에서 복사한 IP로 수정합니다.
      - `[app_servers]` 및 `[monitoring_servers]` 그룹의 `ansible_host`는 `variables.tf`에 정의된 고정 IP를 사용합니다.
2.  **Ansible 연결 테스트 (완료)**:
    - Ansible `ping` 모듈을 사용하여 배스천 호스트 및 프라이빗 앱 서버들과 정상적으로 통신이 되는지 확인합니다.
    - 예: `ansible -m ping all`
3.  **모니터링 시스템 배포 (완료)**:
    - **Docker 설치 및 검증 플레이북 대상 변경:** `install-docker.yml`과 `verify-docker.yml`의 `hosts` 대상을 `bastion`에서 `monitoring-host`로 변경 완료.
    - 모니터링 서버에 Docker 및 `docker-compose` 설치 완료.
    - Prometheus/Grafana를 위한 `docker-compose.yml` 파일 작성 완료.
    - Node Exporter 설치 및 Prometheus 설정 업데이트 완료.
    - `deploy-monitoring.yml` 플레이북을 통해 모니터링 시스템 배포 및 검증 완료.
4.  **SSH 터널링을 통한 Grafana 접속 (완료)**:
    - `connect_monitoring_tunnel.sh` 스크립트를 통해 배스천 호스트를 경유하여 모니터링 서버의 Grafana 및 Prometheus 대시보드에 안전하게 접속하는 방법 구현 및 확인 완료.
    - Prometheus 'Targets' 페이지에서 모든 Node Exporter 타겟(로컬 및 원격)이 'UP' 상태임을 확인 완료.

---

## 5. 고려 사항 및 향후 개선 방안

### 5.1 Grafana 접속 방식 개선

현재 Grafana 대시보드는 모니터링 서버(프라이빗 서브넷)에 배포되어 있으며, 배스천 호스트를 통한 SSH 터널링으로 접속합니다. 이는 터미널 세션이 유지되어야 한다는 제약이 있습니다. 향후 다음과 같은 대안을 고려할 수 있습니다.

1.  **AWS Systems Manager Session Manager (SSM) 포트 포워딩:**
    *   **문제점:** SSH 연결을 유지해야 함.
    *   **개선 방안:** SSM은 SSH 포트를 외부에 노출하지 않고도 안전하게 인스턴스에 접속하고 포트 포워딩을 할 수 있는 AWS 네이티브 서비스입니다.
    *   **필요 사항:** 모니터링 서버에 SSM 에이전트 설치 및 IAM 역할 설정.

2.  **VPN (Virtual Private Network) 구축:**
    *   **문제점:** 개별 SSH 터널링 설정의 번거로움.
    *   **개선 방안:** VPC 내부에 VPN 서버를 구축하여 VPN을 통해 VPC 네트워크에 직접 접속하는 방식입니다. 한 번 VPN에 연결되면 모든 프라이빗 리소스에 직접 접근 가능합니다.
    *   **필요 사항:** VPN 서버(예: OpenVPN) 배포 및 관리.

3.  **Application Load Balancer (ALB) 또는 Reverse Proxy:**
    *   **문제점:** Grafana를 외부에 노출하지 않으려는 보안 목표.
    *   **개선 방안:** ALB나 Nginx와 같은 리버스 프록시를 퍼블릭 서브넷에 배치하여 Grafana에 대한 접근을 제어할 수 있습니다. 이 경우, 보안 그룹 및 WAF(Web Application Firewall) 등을 통해 접근 제어를 강화해야 합니다.
    *   **필요 사항:** ALB/Reverse Proxy 배포, DNS 설정, 추가 보안 강화.
