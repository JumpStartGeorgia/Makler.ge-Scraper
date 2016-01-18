require 'mail'

require_relative 'mail_config'

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
