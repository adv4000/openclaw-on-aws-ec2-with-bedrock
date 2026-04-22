output "openclaw_public_ip" {
  value = aws_instance.openclaw.public_ip
}

output "ssh_allowed_from_ip" {
  value = chomp(data.http.my_ip.response_body)
}

output "token" {
  value     = random_string.token.result
  sensitive = false
}

output "zenjoy" {
  value = "Login to OpenClaw EC2 and run: openclaw tui --token=${random_string.token.result}"
}
