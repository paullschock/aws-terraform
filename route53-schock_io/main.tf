provider "aws" {
  region = "${var.aws-region}"
}


resource "aws_route53_zone" "schock_io" {
  name = "schock.io"

  tags {
    terraform = "true"
  }
}

output "nameservers" {
  value = ["${aws_route53_zone.schock_io.name_servers}"]
}

output "zone-id" {
  value = "${aws_route53_zone.schock_io.zone_id}"
}
