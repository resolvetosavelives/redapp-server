server "ec2-13-234-38-169.ap-south-1.compute.amazonaws.com", user: "deploy", roles: %w[web app db cron]
server "ec2-13-233-73-120.ap-south-1.compute.amazonaws.com", user: "deploy", roles: %w[web app db]
server "ec2-13-235-248-148.ap-south-1.compute.amazonaws.com", user: "deploy", roles: %w[web sidekiq]
