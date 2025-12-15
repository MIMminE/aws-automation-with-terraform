output "public_ip" {
  description = "생성된 EC2 인스턴스의 공인 IP 주소"
  value = aws_instance.example.public_ip
}