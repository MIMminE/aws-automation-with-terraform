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
  azs                = ["ap-northeast-2a", "ap-northeast-2c"]
  private_subnets    = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets     = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
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