# Introduction

Source files for my Airpair workshop [containerizing production applications](https://www.airpair.com/devops/workshops/containerizing-production-app)

# Getting started

## Install Terraform

Find the appropriate [Terraform package](https://terraform.io/downloads.html) for your system and download it. 

After downloading Terraform, unzip the package into a directory where Terraform will be installed. The directory will contain a set of binary programs, such as `terraform`, `terraform-provider-aws`, etc. The final step is to make sure the directory you installed Terraform to is on the PATH. See [this page](http://stackoverflow.com/questions/14637979/how-to-permanently-set-path-on-linux) for instructions on setting the PATH on Linux and Mac. [This page](http://stackoverflow.com/questions/1618280/where-can-i-set-path-to-make-exe-on-windows) contains instructions for setting the PATH on Windows.

After installing Terraform, verify the installation worked by opening a new terminal session and checking that terraform is available. Execute `terraform` and you should see available commands.
