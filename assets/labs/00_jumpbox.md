

## EC2 instance for workshop
1. AWS EC2 home page 에서 ec2 instance 를 하나 상성한다. (ubuntu image)
2. key pair를 생성하거나 기존것을 선택하여 인스턴스에 접속할 수 있다
3. 필요한 cli 설치
  - aws
  - confluent
  - terraform

```
## repo update
sudo apt update && sudo apt install -y curl unzip apt-transport-https ca-certificates gnupg lsb-release

## aws cli
curl "https://awscli.amazonaws.com/awscli-bundle.zip" -o "awscli-bundle.zip"
unzip awscli-bundle.zip
sudo ./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws
aws --version

## confluent cli
curl -sL https://packages.confluent.io/deb/1.1/archive.key | sudo gpg --dearmor -o /usr/share/keyrings/confluent.gpg
sudo sh -c 'echo "deb [arch=amd64 signed-by=/usr/share/keyrings/confluent.gpg] https://packages.confluent.io/deb/1.1 stable main" > /etc/apt/sources.list.d/confluent.list'
sudo apt update && sudo apt -y install confluent-cli

## Terraform
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update
sudo apt install -y terraform
```
