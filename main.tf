provider "aws" {
  region = "us-east-2"
}

resource "aws_security_group" "multi-container" {
  name        = "multi-container"
  description = "Traffic for services in multi-docker app"

  ingress {
    from_port   = 5432
    to_port     = 6379
    protocol    = "tcp"
    self        = true
  }

  tags = {
    Name = "multi-container-security-group"
  }
}

resource "aws_elastic_beanstalk_application" "multi-container" {
  name        = "multi-container"
  description = "Multi-container docker application"
}

resource "aws_elastic_beanstalk_environment" "MultiContainer-env" {
  name                = "MultiContainer-env"
  application         = "${aws_elastic_beanstalk_application.multi-container.name}"
  solution_stack_name = "64bit Amazon Linux 2018.03 v2.11.9 running Multi-container Docker 18.06.1-ce (Generic)"
  
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "REDIS_HOST"
    value     = "${aws_elasticache_cluster.redis.cache_nodes.0.address}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "REDIS_PORT"
    value     = "${aws_elasticache_cluster.redis.port}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "PGUSER"
    value     = "${aws_db_instance.postgres_db.username}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "PGPASSWORD"
    value     = "${aws_db_instance.postgres_db.password}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "PGHOST"
    value     = "${aws_db_instance.postgres_db.address}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "PGDATABASE"
    value     = "${aws_db_instance.postgres_db.name}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "PGPORT"
    value     = "${aws_db_instance.postgres_db.port}"
  }
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = "aws-elasticbeanstalk-ec2-role"
  }
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "SecurityGroups"
    value     = "${aws_security_group.multi-container.name}"
  }
}


resource "aws_db_instance" "postgres_db" {

  parameter_group_name    = "default.postgres10"
  vpc_security_group_ids  = ["${aws_security_group.multi-container.id}"]

  instance_class          = "db.t2.micro"
  allocated_storage       = 20
  engine                  = "postgres"
  engine_version          = "10.6"
  port                    = "5432"
  
  backup_window           = "03:00-06:00"
  maintenance_window      = "Mon:00:00-Mon:03:00"
  apply_immediately       = "true"
  
  name                    = "fibvalues"
  identifier              = "fibvalues"
  username                = "postgres"
  password                = "postgres_password"

}


resource "aws_elasticache_cluster" "redis" {
  
  cluster_id           = "mc-redis"
  engine               = "redis"
  node_type            = "cache.t2.micro"
  num_cache_nodes      = "1"
  parameter_group_name = "default.redis5.0"
  engine_version       = "5.0.3"
  port                 = "6379"
  security_group_ids   = ["${aws_security_group.multi-container.id}"]
  apply_immediately    = "true"

}