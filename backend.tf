terraform {
#   required_version = ">= 1.0"

#   required_providers {
#     aws = {
#       source = "hashicorp/aws"
#     }
#   }

  backend "remote" {
    organization = "kevindemos"

    workspaces {
      name = "javaperks-aws-k8s"
    }
  }
}
