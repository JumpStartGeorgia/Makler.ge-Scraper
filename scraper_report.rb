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
    end

    mail[:body] = body

    mail.deliver!
  end

  private

  def body
    <<-REPORT_BODY
    Makler.Ge Scraper: Scrape Report

    REPORT_BODY
  end
end
