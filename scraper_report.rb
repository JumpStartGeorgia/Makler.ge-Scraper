require 'mail'
require_relative 'mail_config'

# Shares statistics about scraper run
class ScraperReport
  def initialize(statistics_sheet)
    @date = Time.now.strftime('%F')
    @statistics_sheet = statistics_sheet
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

  attr_reader :date, :number_records_gathered, :statistics_sheet

  def body
    <<-REPORT_BODY
    Makler.Ge Scraper: Scrape Report
    Date: #{date}

    Number of records gathered: #{statistics_sheet.number_records_gathered.to_s}
    REPORT_BODY
  end
end
