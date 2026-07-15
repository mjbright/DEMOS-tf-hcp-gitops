# This is a simple EC2 instance to demonstrate the workflow.
# You can replace this with any infrastructure you like.

resource "aws_instance" "demo" {
  ami           = "ami-0c55b159cbfafe1f0" # Amazon Linux 2
  instance_type = "t3.micro"

  tags = {
    Name        = "HCP-Demo-Instance"
    Environment = "GitOps"
    ManagedBy   = "Terraform"
    Force       = "Force HCP Terraform run at 8am"
  }
}

output "instance_id" {
  description = "The ID of the EC2 instance"
  value       = aws_instance.demo.id
}

output "instance_public_ip" {
  description = "The public IP of the EC2 instance"
  value       = aws_instance.demo.public_ip
}
