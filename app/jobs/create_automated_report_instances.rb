# frozen_string_literal: true
class CreateAutomatedReportInstances
  def initialize
    @base_url = Rails.application.config
                     .reporting_service
                     .url_options[:base_url]
  end

  def perform
    create_instances
    return if @instances.blank?

    @instances.each do |instance|
      subs = instance.automated_report
                     .automated_report_subscriptions

      send_email(subs, instance)
    end
  end

  private

  def create_instances
    @instances = []

    return if select_reports.blank?

    select_reports.each do |report|
      start = range_start(report.interval)

      next if instance_exists?(report, start)

      instance = create_instance_with(report, start)
      @instances += [instance]
    end
  end

  def create_instance_with(report, start)
    AutomatedReportInstance
      .create!(identifier: SecureRandom.urlsafe_base64,
               automated_report: report,
               range_start: start)
  end

  def instance_exists?(report, start)
    AutomatedReportInstance.find_by(range_start: start,
                                    automated_report: report)
  end

  def select_reports
    [monthly, quarterly, yearly].compact.reduce(&:+)
  end

  def reports_with_intervals
    AutomatedReport
      .preload(:automated_report_subscriptions)
      .select { |r| !r.automated_report_subscriptions.blank? }
      .group_by(&:interval)
  end

  def monthly
    reports_with_intervals['monthly']
  end

  def quarterly
    return unless [1, 4, 7, 10].include?(time.month)

    reports_with_intervals['quarterly']
  end

  def yearly
    return unless time.month == 1

    reports_with_intervals['yearly']
  end

  def time
    Time.zone.now
  end

  def range_start(interval)
    intervals = {
      'monthly' => 1,
      'quarterly' => 3,
      'yearly' => 12
    }.freeze

    start_time = time - intervals[interval].months
    start_time.beginning_of_month
  end

  def send_email(subscriptions, instance)
    subscriptions.each do |subscription|
      Mail.deliver(to: subscription.subject.mail,
                   from: Rails.application.config
                              .reporting_service.mail[:from],
                   subject: 'AAF Reporting Service - New Report Generated',
                   body: email_message(instance).render,
                   content_type: 'text/html; charset=UTF-8')
    end
  end

  def email_message(instance)
    Lipstick::EmailMessage.new(title: 'AAF Reporting Service',
                               image_url: image_url('email_banner.png'),
                               content: email_body(instance))
  end

  def email_body(instance)
    opts = { report_url: report_url(instance),
             report_class: instance.automated_report
                                   .report_class
                                   .titleize }

    format(EMAIL_BODY, opts)
  end

  def report_url(instance)
    identifier = instance.identifier
    path = '/automated_reports/'

    @base_url + path + identifier
  end

  def image_url(image)
    (@base_url + ActionController::Base.helpers.image_path(image)).to_s
  end

  FILE = 'app/views/layouts/email_template.html.erb'.freeze
  EMAIL_BODY = File.read(Rails.root.join(FILE)).freeze

  private_constant :EMAIL_BODY, :FILE
end
