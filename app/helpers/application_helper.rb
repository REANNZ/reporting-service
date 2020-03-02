# frozen_string_literal: true

module ApplicationHelper
  include Lipstick::Helpers::LayoutHelper
  include Lipstick::Helpers::NavHelper
  include Lipstick::Helpers::FormHelper

  VERSION = '1.3.0-tuakiri3'

  def permitted?(action)
    @subject.try(:permits?, action)
  end

  def environment_string
    Rails.application.config.reporting_service.environment_string
  end
end
