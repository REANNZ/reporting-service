module ApplicationHelper
  include Lipstick::Helpers::LayoutHelper
  include Lipstick::Helpers::NavHelper
  include Lipstick::Helpers::FormHelper

  VERSION = '0.0.1'

  def permitted?(action)
    @subject.try(:permits?, action)
  end

  def environment_string
    Rails.application.config.reporting_service.environment_string
  end
end
