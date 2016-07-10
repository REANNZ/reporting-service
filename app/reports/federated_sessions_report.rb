# frozen_string_literal: true
class FederatedSessionsReport < TimeSeriesReport
  prepend ReportsSharedMethods

  report_type 'federated-sessions'
  y_label 'Sessions / hour (average)'
  units ''
  series sessions: 'Sessions'

  def initialize(start, finish, steps)
    title = 'Federated Sessions'
    create_time_instance_variables(start, finish)
    @steps = steps

    super(title, start: @start, end: @finish)
  end

  private

  def data
    per_hour_output
  end
end
