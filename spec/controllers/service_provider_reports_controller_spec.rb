require 'rails_helper'
require 'controllers/subscriber_reports_controller'

RSpec.describe ServiceProviderReportsController, type: :controller do
  let(:prefix) { 'service' }

  include_context 'a Subscriber Report'

  context 'Service Provider Source Identity Providers' do
    let(:report_path) { :source_identity_providers_report }
    let(:template) { 'service-provider-source-identity-providers' }
    it_behaves_like 'Report Controller'
  end
end