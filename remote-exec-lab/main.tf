
locals {
  my_tags = {
    Name  = "prod-unit"
    Owner = "anilji"
  }
}


resource "aws_instance" "prod" {
  ami           = "ami-008b85aa3ff5c1b02"
  instance_type = "t2.micro"
  tags          = local.my_tags
  key_name      = "kyeapnew"

  provisioner "remote-exec" {
    inline = [
      "sudo yum install httpd unzip -y",
      "sudo systemctl enable httpd",
      "sudo yum install wget -y",
      "sudo wget -P /tmp/site https://www.free-css.com/assets/files/free-css-templates/download/page294/primecare.zip",
      "cd /tmp/site",
      "sudo unzip primecare.zip",
      "sudo rm -rf *.zip",
      "sudo cp -R /tmp/site/primecare-html/* /var/www/html",
      "sudo systemctl restart httpd"
    ]
  }

  connection {
    type        = "ssh"
    user        = "ec2-user"
    host        = self.public_ip
    private_key = file("kyeapnew.pem")
    timeout     = "12m"
  }
}