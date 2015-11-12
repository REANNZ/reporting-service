class FederationGrowthReport < TimeSeriesReport
  report_type 'federation-growth-report'

  y_label ''

  series organizations: 'Organizations',
         identity_providers: 'Identity Providers',
         services: 'Services'

  units ''

  def initialize(title, start, finish)
    super(title, start, finish)
    @start = start
    @finish = finish
  end

  private

  def range
    start = @start.beginning_of_day
    finish = @finish.beginning_of_day
    (0..(finish.to_i - start.to_i)).step(1.day)
  end

  def data
    activations = Activation.where('activated_at <= ?', @finish)

    range.each_with_object(organizations: [], identity_providers: [],
                           services: []) do |time, data|
      report = data_report activations
      total = 0

      report.each do |k, v|
        total += v
        data[k] << [time, total, v]
      end
    end
  end

  def data_report(activations)
    data = activations.group_by(&:federation_object_type)
           .transform_values { |a| a.uniq(&:federation_object_id) }

    merged_report data
  end

  def merged_report(data)
    report = Hash.new([]).merge(data)

    { organizations: report['Organization'].count,
      identity_providers: report['IdentityProvider'].count,
      services: report['RapidConnectService'].count +
        report['ServiceProvider'].count }
  end
end
