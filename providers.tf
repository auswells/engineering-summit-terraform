terraform {
  required_version = "~> 0.14.8"
  backend "remote" {
    workspaces { name = "awells-eng-summit" }
    hostname     = "app.terraform.io"
    organization = "actian-awells"
  }
}
 
