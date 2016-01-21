class StatisticsSheet
  def initialize
    @number_records_gathered = 0
  end

  def increase_number_records_gathered_by_1
    @number_records_gathered += 1
  end

  attr_reader :number_records_gathered
end
