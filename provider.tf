provider "aws" {
  region  = "ap-northeast-1"
  profile = "sandbox"

  default_tags {
    tags = {
      Type = "demo"
    }
  }
}