server "ec2-13-235-33-14.ap-south-1.compute.amazonaws.com", user: "deploy", roles: %w(web app db sidekiq cron whitelist_phone_numbers seed)
server "ec2-3-6-89-39.ap-south-1.compute.amazonaws.com", user: "deploy", roles: %w(web app db)
