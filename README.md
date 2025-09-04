# AWS Ansible 프로젝트: Docker 기반 모니터링 시스템 배포

## 1. 프로젝트 개요

이 프로젝트는 Terraform을 사용하여 AWS 클라우드에 고가용성 인프라를 코드로 프로비저닝하고, Ansible을 사용하여 해당 인프라에 Docker 기반의 모니터링 시스템(Prometheus, Grafana)을 배포 및 관리하는 방법을 보여줍니다.

특히, 모범 사례에 따라 모니터링 서버를 프라이빗 서브넷에 배치하고, 배스천 호스트를 통한 SSH 터널링으로 안전하게 접근하는 아키텍처를 구현합니다.

## 2. 아키텍처

- **VPC**: 1개
- **서브넷**: 퍼블릭 2개 (각 AZ에 1개), 프라이빗 2개 (각 AZ에 1개)
- **게이트웨이**: 인터넷 게이트웨이, NAT 게이트웨이
- **EC2 인스턴스**: 총 4대
  - **배스천 호스트 (퍼블릭 서브넷):** 외부 접속 관문, Ansible 제어 노드
  - **애플리케이션 서버 2대 (프라이빗 서브넷):** 내부 애플리케이션 호스팅
  - **모니터링 서버 (프라이빗 서브넷):** Prometheus/Grafana 실행
- **보안 그룹**: 필요한 포트(SSH, HTTP, Grafana, Prometheus) 허용

## 3. 사전 준비 사항

프로젝트를 시작하기 전에 다음 사항을 준비해야 합니다.

- **AWS 계정:** AWS 계정이 있어야 합니다.
- **AWS CLI 설정:** AWS CLI가 설치되어 있고, 자격 증명(credentials)이 구성되어 있어야 합니다.
- **Terraform:** Terraform이 로컬에 설치되어 있어야 합니다.
- **Ansible:** Ansible이 로컬에 설치되어 있어야 합니다.
- **SSH 키 페어:** AWS EC2에 접속할 SSH 키 페어(`test_key.pem` 또는 `rog_ally_key.pem` 등)가 생성되어 있고, 로컬 `~/.aws/key/` 디렉토리에 위치해야 합니다. `variables.tf`의 `ssh_key_name`과 일치해야 합니다.
- **내 공인 IP 확인:** `variables.tf`의 `my_ip` 변수를 자신의 현재 공인 IP로 설정하여 SSH 접속을 허용해야 합니다. (예: `curl ifconfig.me/ip`/32)

## 4. 인프라 배포 (Terraform)

1.  **Terraform 초기화:**
    프로젝트 루트 디렉토리(`AWS-ANSIBLE/TERRAFORM`)로 이동하여 Terraform을 초기화합니다.
    ```bash
    cd TERRAFORM
    terraform init
    ```
2.  **인프라 생성:**
    Terraform 계획을 확인하고 인프라를 배포합니다. `yes`를 입력하여 승인합니다.
    ```bash
    terraform plan
    terraform apply
    ```
    *주의: `terraform apply` 완료 후 출력되는 `bastion_public_ip` 값을 기록해 두세요. 이 값은 Ansible 인벤토리 업데이트에 필요합니다.*

## 5. Ansible 설정 및 실행

인프라 배포 후, Ansible을 사용하여 소프트웨어를 배포합니다.

1.  **Ansible 인벤토리 업데이트:**
    `ANSIBLE/inventory.ini` 파일을 열어 `bastion-host`의 `ansible_host`를 `terraform apply` 후 출력된 `bastion_public_ip`로 업데이트합니다. 프라이빗 서버들의 IP는 `variables.tf`에 고정되어 있습니다.
    ```ini
    # ANSIBLE/inventory.ini 예시
    [bastion]
    bastion-host ansible_host=YOUR_BASTION_PUBLIC_IP

    [private_servers:children]
    app_servers
    monitoring_servers

    [app_servers]
    app-server-a ansible_host=10.0.101.10
    app-server-b ansible_host=10.0.102.10

    [monitoring_servers]
    monitoring-host ansible_host=10.0.101.11
    ```
2.  **Ansible 연결 테스트:**
    `ANSIBLE` 디렉토리로 이동하여 모든 호스트에 대한 연결을 테스트합니다.
    ```bash
    cd ../ANSIBLE
    ansible all -m ping
    ```
    *참고: `ansible all -m ping` 명령이 프라이빗 서버에 연결되지 않는다면, `ANSIBLE_STDOUT_CALLBACK=oneline ansible all -m ping --ssh-common-args="-o ProxyCommand='ssh -i ~/.aws/key/test_key.pem -W %h:%p ubuntu@{{ hostvars['bastion-host']['ansible_host'] }}'"` 명령을 시도해 보세요.*

3.  **Docker 및 Docker Compose 배포:**
    모니터링 서버에 Docker와 Docker Compose를 설치합니다.
    ```bash
    ansible-playbook deploy-monitoring.yml
    ```
4.  **Docker 설치 검증:**
    설치가 성공했는지 확인합니다.
    ```bash
    ansible-playbook verify-docker.yml
    ```

## 6. 모니터링 시스템 배포 (Prometheus & Grafana)

모니터링 서버에 Prometheus와 Grafana를 Docker 컨테이너로 배포합니다.

```bash
ansible-playbook deploy-monitoring.yml
```
*참고: 이 플레이북은 Docker 및 Docker Compose 설치, Prometheus/Grafana 배포, 그리고 모든 설치 및 배포 검증을 포함합니다.*

## 7. SSH 터널링을 통한 Grafana 접속

Grafana 및 Prometheus 대시보드에 로컬에서 안전하게 접속하기 위해 SSH 터널링 스크립트를 사용합니다.

1.  **배스천 호스트의 퍼블릭 IP 확인:**
    `TERRAFORM` 디렉토리에서 `terraform apply`를 실행한 후 출력되는 `bastion_public_ip` 값을 확인합니다. (예: `43.203.54.160`)

2.  **터널 스크립트 실행:**
    프로젝트 루트 디렉토리(`AWS-ANSIBLE/`)에서 다음 명령어를 실행합니다.

    ```bash
    ./scripts/connect_monitoring_tunnel.sh <배스천_퍼블릭_IP>
    ```
    예시:
    ```bash
    ./scripts/connect_monitoring_tunnel.sh 43.203.54.160
    ```
    *참고: 이 스크립트는 SSH 터널을 백그라운드에서 실행합니다. 터널을 종료하려면 해당 `ssh` 프로세스를 찾아 종료해야 합니다.*

3.  **대시보드 접속:**
    *   **Grafana:** 웹 브라우저에서 `http://localhost:3000`으로 접속합니다.
    *   **Prometheus:** 웹 브라우저에서 `http://localhost:9090`으로 접속합니다.

## 8. 리소스 정리 (Terraform Destroy)

모든 작업을 마친 후, 생성된 AWS 리소스를 삭제하여 비용 발생을 막습니다.

1.  **Terraform 디렉토리로 이동:**
    ```bash
    cd ../TERRAFORM
    ```
2.  **리소스 삭제:**
    ```bash
    terraform destroy
    ```
    *주의: `yes`를 입력하여 삭제를 승인해야 합니다.*
