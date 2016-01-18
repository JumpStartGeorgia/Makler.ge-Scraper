require 'mail'

Mail.defaults do
  delivery_method :smtp, address: "localhost", port: 1025
end

class ScraperReport
  def initialize
  end

  def send_email
    mail = Mail.new do
      from    'info@jumpstart.ge'
      to      'nathan.shane@jumpstart.ge'
      subject 'Makler.ge Scraper Report'
      body    'This is the body of the report'
    end

    mail.deliver!
  end
end
