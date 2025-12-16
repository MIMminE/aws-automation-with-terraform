[ 테라폼 기초 ]
---
`테라폼의 첫 단계 - AWS 설정`

AWS에서 인스턴스를 하나 띄우는 간단한 예제를 통해 테라폼 사용법을 알아본다.
그를 위해 AWS 계정을 생성하고 AWS API를 사용할 수 있는 IAM 사용자를 만들어야 한다.
IAM 사용자를 만들 때는 프로그래밍 방식 액세스를 활성화하고, 적절한 권한(예: AdministratorAccess)을 부여한다.
사용자 생성 후에는 액세스 키 ID와 비밀 액세스 키를 반드시 기록해둔다.
이 키들은 테라폼이 AWS 리소스를 관리하는 데 필요하다.

1. IAM 사용자 생성
   Identity and Access Management(IAM) 콘솔로 이동하여 새 사용자를 생성하고 새 그룹(terraform-admin)을 만든다.
   그룹에 부여할 권한은 AdministratorAccess로 설정한다. 이는 학습의 편의를 위해 강력한 권한을 부여하는 것이며, 실제 운영 환경에서는 최소 권한 원칙에 따라 필요한 권한만 부여해야 한다.
   Access Key ID와 Secret Access Key 를 발급받아 별도로 기록해둔다. 이 키는 테라폼의 AWS Provider 자격 증명으로 사용된다.

2. 보안 그룹 생성
   새 계정의 경우 하나의 기본 VPC와 기본 보안 그룹이 자동으로 생성되어 있다.
   내 IP 에서의 접근 허용 규칙을 추가하는 것이 편리하므로, 기본 보안 그룹을 수정한다.
   EC2 콘솔로 이동하여 네트워크 및 보안 > 보안 그룹 메뉴에서 기본 보안 그룹을 선택한 후, 인바운드 규칙 편집을 클릭하여 내 IP에서의 SSH(포트 22) 접근을 허용하는 규칙을 추가한다.

---
first-step 패키지

```bash
   terraform init
   terraform apply
```

```terraform
provider "aws" {
  region = "ap-northeast-2"
}

resource "aws_instance" "example" {
  ami = "ami-0b818a04bc9c2133c" // AMI 를 하드코딩하는 경우에는 절대 없을 것이다.
  instance_type = "t3.micro"
}
```

.tf 파일이 있는 디렉토리에서 위 명령어를 실행하면 테라폼이 초기화되고, 정의된 인프라가 프로비저닝된다.  
aws 키 설정은 asw cli를 통해 설정하는 것을 권장한다. 키는 권한이 있는 IAM 사용자를 통해 발급받아야 한다.

---

AMI ID 는 리전마다 다르고 시간이 지나면 업데이트되므로, 직접 코드에 적는 대신 **Data Source**를 통해 AWS에서 정보를 조회하여 사용하는 것이 일반적이다.

- **Resource** : aws 인프라를 생성하는 역할을 수행한다. (예: aws_instance)
- **Data Source** : aws 인프라의 정보를 조회하는 역할을 수행한다. (예: aws_ami)

---

테라폼은 AWS 뿐 아니라 Azure, DigitalOcean, GCP 등 다양한 클라우드 제공업체를 지원한다.
이를 가능하게 하는 것이 바로 **Provider** 개념이다.
어떤 클라우르를 쓰더라도 해당 클라우드에 맞는 Provider를 설정(IAM 사용자, API KEY 등)해주면 된다.

## 핵심 명령어 워크플로우

1. `terraform init` : 현재 디렉토리를 테라폼 작업 디렉토리로 초기화한다. 필요한 플러그인(Provider 등)을 다운로드한다.
2. `terraform apply` : 설정 파일에 정의된 인프라를 생성, 수정, 삭제한다. 변경 사항을 미리 보여주고 사용자에게 확인을 요청한다.
3. `terraform destroy` : 설정 파일에 정의된 인프라를 모두 삭제한다. 삭제할 리소스 목록을 미리 보여주고 사용자에게 확인을 요청한다.'
4. `terraform plan` : 설정 파일에 정의된 인프라 변경 사항을 미리 보여준다. 실제로 적용하지는 않는다. 변경 사항을 검토하는 데 유용하다.

프로덕션 환경에서는 destroy 명령어를 신중히 사용해야 한다. 실수로 중요한 리소스를 삭제할 수 있기 때문이다.

--- 

## 입력 변수 (Input Variables)

코드 내에 값을 하드코딩하지 않고, 외부에서 값을 주입받아 사용할 수 있게 해주는 기능이다.
하나의 테라폼 코드로 개발, 테스트, 운영 환경 등 다양한 환경에 맞게 인프라를 구성할 수 있다.

```terraform 
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "AMIS" {
  type = map(string)
  default = {
    us-east-1 = "ami-13be557e"
    us-west-2 = "ami-06b94666"
    eu-west-1 = "ami-0d729a60"
  }
}

```

관례적으로 **variables.tf** 또는 **vars.tf** 파일에 변수들을 정의한다.

테라폼 코드 측에서 사용할 떄는 다음과 같이 사용하면 된다.

```terraform
resource "aws_instance" "example" {
  instance_type = var.instance_type
}

```

환경 별로 여러 변수 파일을 만들어 두었다가, -var-file 옵션을 통해 적용할 수 있다.

```bash
terraform apply -var-file="dev.tfvars"
```

명령어 인자 자체의 값을 지정할 수도 있다.

```bash
terraform apply -var="instance_type=t3.large"
```

---

## 속성 출력

테라폼이 인프라를 생성한 후, 사용자가 확인해야 하는 중요 정보들을 터미널 출력으로 보여줄 수 있다.
예로, EC2 인스턴스를 생성한 후, 접속에 필요한 public IP 주소를 출력하도록 설정할 수 있다.
이후 **모듈**을 사용할 때, 모듈 간에 데이터를 전달하는 **반환 값** 역할을 하는 중요한 개념이다.

aws instance 의 각 리소스가 어떤 정보를 제공하는지는 공식 문서를 참고한다.

```terraform
output "public_ip" {
  description = "생성된 EC2 인스턴스의 공인 IP 주소"
  value       = aws_instance.example.public_ip
}
```

관례적으로 **outputs.tf** 파일에 출력 속성들을 정의한다. 마찬가지로 terraform apply 명령어를 실행한 후, 출력 값을 확인할 수 있다.

```bash
Apply complete! Resources: 1 added, 0 changed, 0 destroyed. 
Outputs:
public_ip = "3.39.226.100"
```

--- 

## 상태 파일 (terraform.tfstate)

테라폼이 관리하는 현재 인프라 상태를 기록하는 파일이다. 생성된 리소스의 속성, 메타데이터, 종속성 정보 등이 포함되어 있다.
이 파일을 통해 테라폼은 현재 인프라 상태를 파악하고, 변경 사항을 적용할 수 있다.
기본적으로 작업 디렉토리에 **terraform.tfstate** 파일로 저장된다.

apply이나 plan 명령어를 수행할 때, 테라폼 코드 파일, 상태 파일, 실제 클라우드 환경을 비교하여 변경 사항을 결정한다.

### mv 명령어

테라폼 코드에서 리소스의 이름을 변경할 때, 단순히 코드에서만 변경하면 테라폼은 기존 리소스를 삭제하고 새로 생성하려고 한다.
이때는 `terraform mv` 명령어를 사용하여 상태 파일 내에서 리소스의 이름을 변경해야 한다.

```bash
terraform state mv aws_instance.old_name aws_instance.new_name
```

### 주요 State 명렁어

State 파일은 JSON 형식으로 되어 있어 직접 수정하는 것은 권장되지 않는다. 대신 다음 명령어들을 사용한다.

- `terraform state list` : 현재 상태 파일에 기록된 리소스 목록을 출력한다.
- `terraform state show <리소스_이름>` : 특정 리소스의 상세 정보를 출력한다.
- `terraform state mv <현재_리소스_이름> <새로운_리소스_이름>` : 상태 파일 내에서 리소스의 이름을 변경한다.
- `terraform state rm <리소스_이름>` : 상태 파일에서 특정 리소스를 제거한다. 실제 리소스는 삭제되지 않는다.

--- 

## Module 를 통한 VPC 생성

AWS VPC를 테라폼 코드로 생성하는 것은 매우 복잡할 수 있다. 서브넷, 라우팅 테이블, 게이트웨이 등 수많은 리소스를 일일이 정의해야 하기 떄문이다.
이미 잘 만들어진 모듈 **(terraform-aws-modules/vpc/aws)** 을 사용하면 몇 줄의 코드로 VPC를 생성할 수 있다.

```terraform
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"

  name               = "my-vpc"
  cidr               = "10.0.0.0/16"
  azs = ["ap-northeast-2a", "ap-northeast-2c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  enable_nat_gateway = false
  enable_vpn_gateway = false

  map_public_ip_on_launch = true
}
```

관례적으로 **vpc.tf** 파일에 vpc 모듈 관련 코드를 정의한다. 모듈을 처음 사용하는 경우에는 `terraform init` 명령어를 통해 모듈을 다운로드해야 한다.

- VPC 의 이름으로 my-vpc 로 지정되며, CIRR 블록으로 10.0.0.0/16 을 사용한다.
- 가용 영역은 ap-northeast-2a 와 ap-northeast-2c 두 곳을 사용한다.
- 퍼블릭 서브넷과 프라이빗 서브넷을 각각 3 개씩 정의한다. (보통 AZ 당 하나씩의 서브넷이 생성되도록 숫자를 맞추는 것을 권장한다.)
- NAT 게이트웨이와 VPN 게이트웨이는 비활성화한다.
- 퍼블릭 서브넷에 생성되는 인스턴스에 대해 퍼블릭 IP 주소를 자동으로 할당하도록 설정한다.

---

## Security Group, SSH Key

테라폼 코드를 써서 보안 그룹을 만드는 방식이다. ingress 와 egress 규칙을 통해 인바운드, 아웃바운드 트래픽을 제어할 수 있다.

```terraform
resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic and all outbound traffic"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_ssh"
  }
}
```

보안 그룹을 생성한 후, EC2 인스턴스를 생성할 때 해당 보안 그룹을 연결해주어야 한다.

### SSH Key Pair 생성

SSH로 인스턴스에 접속하기 위해서는 키 페어가 필요하다. 로컬 환경에서 별도의 RSA, Ed25519 키 쌍을 생성한 후, 퍼블릭 키를 AWS에 등록하는 방식을 사용할 수 있다.
AWS 콘솔 상에서는 별도로 키 페어를 생성할 수도 있다.

```terraform
resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIArSxyOkZryj0M6oAhcD2p8KCHeMfSBmlF0YJGbU2uIT secureletter@DESKTOP-M2P7CSN"
}

```

퍼블릭 키를 등록해주고 개인키를 이용해 인스턴스에 접속할 수 있다.

```terraform
resource "aws_instance" "example" {
  ami           = "ami-0b818a04bc9c2133c"
  instance_type = "t3.micro"
  subnet_id     = module.vpc.public_subnets[0]
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]  // 보안 그룹 연결 
  key_name      = aws_key_pair.deployer.key_name              // SSH 키 페어 연결
}
```

### 내장 함수 (Built-in Functions)

테라폼은 다양한 내장 함수를 제공하여 문자열 조작, 수학 연산, 컬렉션 처리 등을 수행할 수 있다.
테라폼 코드 내에 긴 문자열(SSH 공개 키 등)을 직접 작성하는 대신, 파일에서 읽어오는 함수를 사용할 수 있다.

- `file(path)` : 지정된 경로의 파일 내용을 문자열로 읽어온다.
- `templatefile(path, vars)` : 지정된 경로의 템플릿 파일을 읽어와 변수들을 치환한 후 문자열로 반환한다.

파일을 읽을 때 경로를 정확하게 지정하기 위해 테라폼의 참조 표현식을 사용한다.

**path.module** 은 현재 작성 중인 테라폼 코드가 위치한 파일 시스템 경로를 지칭한다. 주로 읽기 작업에서 사용이 권장된다.

```terraform
resource "aws_key_pair" "deployer" {
  key_name = "deployer-key"
  public_key = file("../mykey.pub" //  file("${path.module}/../mykey.pub") 과 동일
    }
```

--- 

### User Data 를 통한 초기 설정 스크립트

테라폼으로 생성한 인스턴스에 대해 초기 설정 스크립트를 자동으로 실행하도록 할 수 있다. 이를 **프로비저닝(provisioning)** 이라고 한다.
전통적인 방식은 SSH 접속 후 수동으로 설정하는 것이지만, 테라폼에서는 **user_data** 속성을 통해 초기화 스크립트를 전달할 수 있다.

user_data 는 인스턴스가 최초로 시작될 때 단 한 번 실행되는 스크립트이다.
이를 이용하면 SSH 키 설정, 네트워크 접근 권한 설정 등 없이 자동으로 초기 설정을 수행할 수 있다.

이는 보안상 유리하며, CI/CD 파이프라인에 적합한 방식이다.

```shell
#!/bin/bash

apt-get update
apt-get install -y nginx
echo "Region: ${region}" > /tmp/region.txt
```

관례적으로 **templates** 폴더를 만들어 초기화 스크립트를 템플릿 파일로 저장한다.

```terraform
resource "aws_instance" "example" {

  user_data = templatefile("${path.module}/templates/web.tpl", {
    region = "ap-northeast-2"
  })

}
```

user_data 속성에 templatefile 함수를 사용하여 템플릿 파일을 읽어오고, 필요한 변수를 치환한다.

실행 결과는 aws 인스턴스의 /tmp/region.txt 파일에서 확인할 수 있다.

### 레거시 프로비저너 (Legacy Provisioner)

과거 온프레미스 환경에서 Ansible 등을 연동할 때 많이 사용되었으나, 현재는 클라우드 네이티브 방식에 밀려 사용이 권장되지 않는다.
이는 테라폼이 생성된 인스턴스에 직접 SSH로 접속하여 명령어를 실행하는 방식이다.

`aws_instance` 리소스에 **provisioner** 블록을 추가하여 사용할 수 있다.'

```terraform
resource "aws_instance" "example" {

  connection {
    type = "ssh"
    user = "ubuntu"
    private_key = file("mykey")  # 로컬에 있는 개인 키 파일 필요
    host = self.public_ip # 생성된 인스턴스의 공인 IP
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get -y install nginx"
    ]
  }
}
```

remote-exec 프로비저너는 SSH 접근이 필요하므로 인스턴스의 보안 그룹 설정에서 SSH 접근이 허용되어 있어야 한다.
또한, 개인 키 파일이 필요하며, 테라폼 상태 파일(State file)이 프로비저닝 성공 여부를 추적한다는 점에서 관리가 번거로울 수 있다.

현대적 흐름은 인스턴스를 직접 설치하기보다 Docker, Kubernetes 을 사용하여 애플리케이션을 배포하는게 추세이다.
레거시 프로비저너는 사용이 거의 사라져가는 추세이고, user_data 방식은 도커, 쿠버네티스 실행을 위한 Bootstrap 스크립트 실행에 주로 사용된다.

```shell
# 컨테이너 실행 환경만 구성함
apt-get install docker
docker run my-app:v1  # 앱은 도커가 실행
# 또는 쿠버네티스 클러스터에 합류
kubeadm join <master-node-ip>
```

### 테라폼 원격 상태 (Remote State)

기본적으로 테라폼은 terraform.tfstate 파일을 로컬에 저장한다. 그러나, 팀 단위로 협업할 때는 원격 상태 저장소를 사용하는 것이 좋다.
원격 상태 저장소를 사용하면 여러 사용자가 동시에 작업하더라도 상태 파일이 일관되게 유지된다.

이를 해결하기 위한 방안으로 상태 파일을 AWS S3 같은 원격 저장소에 저장하고 공유하는 것이다.


