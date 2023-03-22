locals{
    name = "gitlab-server"
    name1 = "bastion-host"
    env = "dev"
}
module "vpc" {
  source = "/home/azubuike/terraform-modules/vpc"
  vpc_cidr = "10.10.0.0/16"
  azs = ["us-east-1a","us-east-1b"]
  env = local.env
  name = local.name
  subnets_cidr = {
    public = ["10.10.0.0/20"]
    private = ["10.10.16.0/20"]
  }
  instance_tenancy = "default"

}
#an A type record route53 
module route53 {
    source = "/home/azubuike/terraform-modules/route53"
    record = "gitlab.azubuikeokom.com"
    ip_address = module.gitlab_server.private_ip
}
module acm {
    source = "/home/azubuike/terraform-modules/acm"
    env = local.env
    name = local.name
}
module client_vpn{
    source = "/home/azubuike/terraform-modules/client-vpn"
    env = local.env
    name = local.name
    vpc_id = module.vpc.vpc
    client_cidr = "10.0.0.0/16"
    server_cert = module.acm.server_cert
    client_cert = module.acm.client_cert
    security_group = module.vpc.client_vpn_sg_id
    # private_subnet_1a = module.vpc.private_subnet_1a
    public_subnet_1a = module.vpc.public_subnet_1a
    authorized_network = "10.10.0.0/16"
}

module gitlab_server{
    source = "/home/azubuike/terraform-modules/ec2"
    env = local.env
    name = local.name
    security_group = module.vpc.allow_vpn_sg_id
    subnet_id = module.vpc.private_subnet_1a
    key_name = "cloud-key"
    associate_public_address = false
    instance_type = "t2.medium"
    ami = "ami-005f9685cb30f234b"
    private_ip = "10.10.16.10"
    user_data  = "./data/gitlab-script"
}
module bastion_host{
    source = "/home/azubuike/terraform-modules/ec2"
    env = local.env
    name = local.name1
    security_group = module.vpc.access_bastion_host_sg_id
    subnet_id = module.vpc.public_subnet_1a
    key_name = "cloud-key"
    associate_public_address = true
    instance_type = "t2.micro"
    ami = "ami-005f9685cb30f234b"
    private_ip = "10.10.0.10"
    user_data  = "./data/dummy"

}
