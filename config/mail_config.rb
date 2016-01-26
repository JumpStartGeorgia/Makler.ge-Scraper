if environment_is_production
  Mail.defaults do
    delivery_method :smtp,
                    address: 'smtp.gmail.com',
                    port: '587',
                    user_name: ENV['FEEDBACK_FROM_EMAIL'],
                    password: ENV['FEEDBACK_FROM_EMAIL_PASSWORD'],
                    authentication: :plain,
                    enable_starttls_auto: true
  end
else
  Mail.defaults do
    delivery_method :smtp,
                    address: 'localhost',
                    port: 1025
  end
end
