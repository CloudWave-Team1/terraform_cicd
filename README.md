**TFC 프로덕션 아키텍처 정의 문서**

**1. AWS 설정**
- 리전(region): ap-northeast-2
- AWS 인증을 위한 변수 설정: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY

**2. VPC 설정**
- VPC 이름: TFC-PRD-VPC
- CIDR 블록: 10.3.0.0/16

**3. 서브넷 설정**
- 총 6개의 서브넷이 생성됨
- 가용 영역: ap-northeast-2a, ap-northeast-2c
- 각 서브넷의 CIDR 범위: 
    - 10.3.1.0/24
    - 10.3.2.0/24
    - 10.3.11.0/24
    - 10.3.12.0/24
    - 10.3.13.0/24
    - 10.3.14.0/24

**4. Elastic IP 및 NAT 게이트웨이 설정**
- 총 2개의 EIP 생성됨
- 2개의 NAT 게이트웨이가 각각의 EIP와 연결됨

**5. EC2 설정**
- 인스턴스 타입: t2.micro
- AMI: ami-055179a7fc9fb032d
- 사용자 데이터(user data): “userdata.sh” 파일에 기반
- 보안 그룹: TFC_PRD_EC2_SG

**6. 보안 그룹 설정**
- EC2 보안 그룹: TFC_PRD_EC2_SG
- ALB 보안 그룹: TFC_PRD_ELB_SG

**7. Application Load Balancer(ALB) 설정**
- 내부 ALB: 아님
- 연결 서브넷: TFC-PRD-sub-pub-01, TFC-PRD-sub-pub-02

**8. ALB 리스너 설정**
- 포트: 80 (HTTP)
- Default action: TFC-PRD-TG 대상 그룹으로 전달

**9. 자동 확장 그룹(Auto Scaling Group) 설정**
- 원하는 용량(desired capacity): 2
- 최대 크기: 5
- 최소 크기: 1
- 연결 서브넷: TFC-PRD-sub-pri-01, TFC-PRD-sub-pri-02

**10. 라우팅 테이블 설정**
- Private 서브넷용 라우팅 테이블: TFC-PRD-Private-RT01, TFC-PRD-Private-RT02
- Public 서브넷용 라우팅 테이블: TFC-PRD-Public-RT01, TFC-PRD-Public-RT02
- 모든 트래픽(0.0.0.0/0)은 각 NAT 게이트웨이 또는 인터넷 게이트웨이를 통해 라우팅됨

**11. 인터넷 게이트웨이 설정**
- VPC에 연결: TFC-PRD-VPC
- 이름: TFC-PRD-IG