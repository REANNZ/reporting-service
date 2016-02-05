class FederationReportsController < ApplicationController
  before_action :set_range

  def federation_growth
    public_action

    @data = Rails.cache.fetch('public/federation-growth') do
      report = FederationGrowthReport.new(@start, @end)
      JSON.generate(report.generate)
    end
  end

  def federated_sessions
    public_action

    @data = Rails.cache.fetch('public/federated-sessions') do
      report = FederatedSessionsReport.new(@start, @end, 10)
      JSON.generate(report.generate)
    end
  end

  def daily_demand
    public_action

    @data = Rails.cache.fetch('public/daily-demand') do
      report = DailyDemandReport.new(@start, @end)
      JSON.generate(report.generate)
    end
  end

  private

  def set_range
    @start = 1.year.ago.utc.beginning_of_day
    @end = Time.now.utc.tomorrow.beginning_of_day
  end
end
