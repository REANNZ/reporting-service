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
    total = 0

    range.each_with_object(organizations: [], identity_providers: [],
                           services: []) do |time, data|
      report = active_objects time, activations
      report.each do |k, v|
        total += v
        data[k] << [time, total, v]
      end
    end
  end

  def active_objects(time, activations)
    objects = activations.select do |o|
      o.activated_at <= @start + time &&
      (o.deactivated_at.nil? || o.deactivated_at > @start + time)
    end

    data = objects.group_by(&:federation_object_type)
           .transform_values { |a| a.uniq(&:federation_object_id) }

    merged_services data
  end

  def merged_services(data)
    report = Hash.new([]).merge(data)

    { organizations: report['Organization'].count,
      identity_providers: report['IdentityProvider'].count,
      services: report['RapidConnectService'].count +
        report['ServiceProvider'].count }
  end
end
