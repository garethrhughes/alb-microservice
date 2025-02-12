resource "aws_acm_certificate" "cert" {
  domain_name       = "microsite.sandbox.mypassglobal.com"
  validation_method = "DNS"
}

resource "aws_route53_record" "dns_record" {
  zone_id = data.aws_route53_zone.hosted_zone.zone_id
  name    = "microsite.sandbox.mypassglobal.com"
  type    = "A"

  alias {
    name                   = module.alb.dns_name
    zone_id                = module.alb.zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "dns_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.hosted_zone.zone_id
}

resource "aws_acm_certificate_validation" "cert_validation" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.dns_validation : record.fqdn]
}