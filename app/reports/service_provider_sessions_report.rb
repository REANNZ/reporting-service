class ServiceProviderSessionsReport < TimeSeriesReport
  prepend TimeSeriesSharedMethods

  report_type 'service-provider-sessions'
  y_label ''
  units ''
  series sessions: 'Rate/h'

  def initialize(entity_id, start, finish, steps)
    @service_provider = ServiceProvider.find_by(entity_id: entity_id)
    title = "Service Provider Sessions for #{@service_provider.name}"
    @start = start
    @finish = finish
    @steps = steps

    super(title, start: @start, end: @finish)
  end

  private

  def data
    per_hour_output sp_sessions
  end
end