require 'mail'
require_relative 'mail_config'

# Shares statistics about scraper run
class ScraperReport
  def initialize(statistics_sheet, error_sheet)
    @date = Time.now.strftime('%F')
    @statistics_sheet = statistics_sheet
    @error_sheet = error_sheet
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

  attr_reader :date, :statistics_sheet, :error_sheet

  def body
    <<-REPORT_BODY
    Makler.Ge Scraper: Scrape Report
    Date: #{date}

    #{statistics_sheet.to_s}

    #{error_sheet.to_s}
    REPORT_BODY
  end
end
