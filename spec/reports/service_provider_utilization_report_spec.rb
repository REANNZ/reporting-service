# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ServiceProviderUtilizationReport do
  let(:type) { 'service-provider-utilization' }
  let(:header) { [%w[Name Sessions]] }
  let(:title) { 'Service Provider Utilization Report' }
  let(:output_title) { title + ' (Discovery Service)' }

  subject { ServiceProviderUtilizationReport.new(start, finish, 'DS') }

  context 'Service Provider Utilization report #Generate' do
    let(:object_type) { :service_provider }
    let(:target) { :initiating_sp }

    it_behaves_like 'Utilization Report'
  end
end
