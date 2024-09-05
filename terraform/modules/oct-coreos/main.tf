terraform {
  required_providers {
    ct = {
      source  = "poseidon/ct"
      version = "0.7.1"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

data "ct_config" "config" {
  content = file("config.yaml")
  strict = true
}

resource "aws_instance" "fcos_instance" { 
	ami = "${var.ami}" 
	instance_type = "${var.instance_type}"
	user_data     = data.ct_config.config.rendered
	tags = {
		Name = "${var.tags_name}"
	}
}
