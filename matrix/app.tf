variable "ami" {
  default = "ami-a1c216cc"
}

variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "aws_key_name" {}

variable "aws_region" {
    default = "cn-north-1"
}

provider "aws" {
    access_key = "${var.aws_access_key}"
    secret_key = "${var.aws_secret_key}"
    region = "${var.aws_region}"
}


resource "aws_security_group" "sg_elb" {
  name = "prod-cn-discussions"

  ingress {
      from_port = 80
      to_port = 80
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
  }

  vpc_id = "vpc-116d7b74"
}

resource "aws_elb" "elb_web" {
  name = "prod-cn-discussions"

  listener {
    instance_port = 80
    instance_protocol = "http"
    lb_port = 80
    lb_protocol = "http"
  }

  health_check {
    healthy_threshold = 3
    unhealthy_threshold = 2
    timeout = 10
    target = "HTTP:80/srv/status"
    interval = 30
  }

  cross_zone_load_balancing = true
  idle_timeout = 60
  subnets         = ["subnet-1de98a78", "subnet-d34ca5a4"]
  security_groups = ["${aws_security_group.sg_elb.id}"]

  tags {
    Name = "prod-cn-discussions"
  }
}

resource "aws_launch_configuration" "lc_app" {
  name_prefix = "prod-cn-discussions-"
  image_id = "${var.ami}"
  key_name = "${var.aws_key_name}"
  instance_type = "t2.medium"

  # Our Security group to allow HTTP and SSH access
  security_groups = ["sg-72397e17"]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "asg_app" {

  # spread the app instances across the availability zones
  availability_zones = ["cn-north-1a", "cn-north-1b"]

  # interpolate the LC into the ASG name so it always forces an update
  name = "${aws_launch_configuration.lc_app.name}"
  max_size = 5
  min_size = 1
  # wait_for_elb_capacity = 1
  desired_capacity = 1
  health_check_grace_period = 300
  # health_check_type = "ELB"
  launch_configuration = "${aws_launch_configuration.lc_app.name}"
  load_balancers = ["${aws_elb.elb_web.id}"]
  vpc_zone_identifier = ["subnet-12e98a77", "subnet-d24ca5a5"]

  tag {
    key = "Name"
    value = "prod-cn-discussions"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

# database instance setup
resource "aws_security_group" "sg_db" {
  name = "prod-cn-discussions-db"

  ingress {
      from_port = 0
      to_port = 0
      protocol = -1
      cidr_blocks = ["10.0.0.0/16"]
  }

  vpc_id = "vpc-116d7b74"
}

resource "aws_db_parameter_group" "default" {
    name = "cn-discussions"
    family = "postgres9.4"
    description = "postgres9.4 for cn-discussions"
    parameter {
      name = "max_connections"
      value = 50
    }
}

resource "aws_db_subnet_group" "db_subnet" {
    name = "cn-discussions"
    description = "cn-discussions-db-subgroup"
    subnet_ids = ["subnet-12e98a77", "subnet-d24ca5a5"]
    tags {
        Name = "cn-discussions"
    }
}


resource "aws_db_instance" "default" {
    identifier = "prod-cn-discussions"
    allocated_storage = 5
    engine = "postgres"
    engine_version = "9.4.5"
    instance_class = "db.t1.micro"
    name = "discourse"
    username = "udacity"
    password = "hqGg3fHhRd3cNtCFHJvLnGidJBLKUHyQ"
    vpc_security_group_ids = ["${aws_security_group.sg_db.id}"]
    db_subnet_group_name = "${aws_db_subnet_group.db_subnet.name}"
    parameter_group_name = "${aws_db_parameter_group.default.name}"
    storage_type = "gp2"
    apply_immediately = true
}

# redis setup
resource "aws_security_group" "sg_redis" {
  name = "prod-cn-discussions-redis"

  ingress {
      from_port = 0
      to_port = 0
      protocol = -1
      cidr_blocks = ["10.0.0.0/16"]
  }

  vpc_id = "vpc-116d7b74"
}

resource "aws_elasticache_parameter_group" "default" {
    name = "cn-discussions"
    family = "redis2.8"
    description = "redis 2.8 parameter group"
}

resource "aws_elasticache_subnet_group" "redis_subnet" {
    name = "cn-discussions"
    description = "cn-discussions-redis-subgroup"
    subnet_ids = ["subnet-12e98a77", "subnet-d24ca5a5"]
}

resource "aws_elasticache_cluster" "cn_discussions" {
    cluster_id = "prod-cn-discussions"
    engine = "redis"
    node_type = "cache.t2.micro"
    port = 6379
    num_cache_nodes = 1
    security_group_ids = ["${aws_security_group.sg_redis.id}"]
    subnet_group_name = "${aws_elasticache_subnet_group.redis_subnet.name}"
    parameter_group_name = "${aws_elasticache_parameter_group.default.name}"
    apply_immediately = true
}
