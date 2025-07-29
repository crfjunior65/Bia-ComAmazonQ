# --- AWS ---

provider "aws" {
  # Configuration options
  #alias = "us-east-1"
  #profile = crfjunior072024
  region = "us-east-1"
  default_tags {
    tags = {
      Terraform   = "true"
      Environment = "Formacao_AWS"
      Management  = "Terraform"
    }
  }
}
