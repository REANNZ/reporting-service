# frozen_string_literal: true

FactoryBot.define do
  factory :automated_report_subscription do
    subject
    automated_report
    identifier { SecureRandom.urlsafe_base64 }
  end
end
