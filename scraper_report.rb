require 'mail'

require_relative 'mail_config'

class ScraperReport
  def initialize
    @date = Time.now.strftime('%F')
    @number_records_gathered = 'Unknown (never set by scraper)'
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

  attr_reader :date, :number_records_gathered

  def body
    <<-REPORT_BODY
    Makler.Ge Scraper: Scrape Report

    Date: #{date}
    Number of records gathered: #{number_records_gathered}
    REPORT_BODY
  end
end
