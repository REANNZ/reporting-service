FactoryGirl.define do
  factory :automated_report do
    report_class 'DailyDemandReport'
    interval 'monthly'
  end
end