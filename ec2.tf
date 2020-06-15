provider "aws" {
   region = "ap-south-1"
   profile = "Terraformuser"
}


#For creating Key pair 

resource "aws_key_pair" "deploy" {
  key_name   = "mykeypair"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAAgQDFFkGBpeH1RXiBf+IPlHq57KOy7S5l2azGSk8uLcg7+BiH1GMCmpLr3YrpX2lV72ihopOVZGLIsx+1U6obNcP5ghDop0p2m7n+QvjeH6sOtEN9M4XKoSDAqnk6iU1KSrCekE3DwuqbXTfcbDCXC775LJKI54RsBLGoGZofsKqGcw=="
} 


#For creating security group

resource "aws_security_group" "examplesg" {
  name = "My  Security Group"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
 ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
}
egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#For creating ec2 instance

resource "aws_instance" "myenv" {
  ami           = "ami-0b44050b2d893d5f7"
  instance_type = "t2.micro"
  key_name = aws_key_pair.deploy.key_name
  security_groups = [aws_security_group.examplesg.name]
  user_data = file("install_apache.sh")
  tags = {
    Name = "MyFirstos"
  }
}

#For creating ebs volume

resource "aws_ebs_volume" "myebsvol" {
  availability_zone = aws_instance.myenv.availability_zone
  size              = 1
  tags = {
    Name = "myebsvol"
  }
}

#For attaching that ebs volume

resource "aws_volume_attachment" "ebs_att" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.myebsvol.id
  instance_id = aws_instance.myenv.id
}

#for Creating aws_s3 bucket 

resource "aws_s3_bucket" "mybucket" {
  bucket = "myraghavbucket"
  acl    = "public-read"

  tags = {
    Name = "My bucket"
  }
}


#For creating cloudFront Distribution

resource "aws_cloudfront_distribution" "mycloudfrontdistribution" {
  origin {
    domain_name = aws_s3_bucket.mybucket.bucket_regional_domain_name
    origin_id   = "mybucketid"
  }

  enabled             = true
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "mybucketid"

    forwarded_values {
      query_string = true

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }


  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}