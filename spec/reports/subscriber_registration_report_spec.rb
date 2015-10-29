require 'rails_helper'

RSpec.describe SubscriberRegistrationReport do
  let(:header) { [['Name', 'Registration Date']] }
  let(:type) { 'subscriber-registrations' }

  let(:organization) { create(:organization) }
  let(:identity_provider) { create(:identity_provider) }
  let(:service_provider) { create(:service_provider) }
  let(:rapid_connect_service) { create(:rapid_connect_service) }

  subject { SubscriberRegistrationReport.new(report_type) }

  shared_examples 'a report which lists federation objects' do
    it 'returns an array' do
      expect(subject.rows).to be_an(Array)
    end

    it 'produces title, header and type' do
      expect(subject.generate).to include(title: title,
                                          header: header, type: type)
    end

    context '#subscribers_list' do
      objects = { 'organizations' => Organization.all,
                  'identity_providers' => IdentityProvider.all,
                  'service_providers' => ServiceProvider.all,
                  'rapid_connect_services' => RapidConnectService.all,
                  'services' => ServiceProvider.all + RapidConnectService.all }
      it 'matches all objects' do
        expect(subject.subscribers_list)
          .to match_array(objects[report_type])
      end
    end

    context 'when all objects are activated' do
      let!(:activations) do
        [*reported_objects, *excluded_objects]
          .map { |o| create(:activation, federation_object: o) }
      end

      it 'includes reported objects' do
        reported_objects.each do |o|
          activated_date = o.activations(true)
                           .flat_map(&:activated_at).min
          expect(subject.rows).to include([o.name, activated_date])
          expect(subject.select_activated_subscribers)
            .to include(o)
        end
      end
    end

    context 'when all objects are deactivated' do
      let!(:activations) do
        [*reported_objects, *excluded_objects]
          .map { |o| create(:activation, :deactivated, federation_object: o) }
      end

      it 'excludes all objects' do
        [*reported_objects, *excluded_objects].each do |o|
          expect(subject.rows).not_to include([o.name, anything])
          expect(subject.select_activated_subscribers)
            .not_to include(o)
        end
      end
    end
  end

  context 'report generation' do
    context 'for an Organization' do
      let(:report_type) { 'organizations' }
      let(:title) { 'Registered Organizations' }
      let(:reported_objects) { [organization] }
      let(:excluded_objects) do
        [identity_provider, service_provider, rapid_connect_service]
      end

      it_behaves_like 'a report which lists federation objects'
    end

    context 'for an Identity Provider' do
      let(:report_type) { 'identity_providers' }
      let(:title) { 'Registered Identity Providers' }
      let(:reported_objects) { [identity_provider] }
      let(:excluded_objects) do
        [organization, service_provider, rapid_connect_service]
      end

      it_behaves_like 'a report which lists federation objects'
    end

    context 'for a Service Provider' do
      let(:report_type) { 'service_providers' }
      let(:title) { 'Registered Service Providers' }
      let(:reported_objects) { [service_provider] }
      let(:excluded_objects) do
        [organization, identity_provider, rapid_connect_service]
      end

      it_behaves_like 'a report which lists federation objects'
    end

    context 'for a Rapid Connect Service' do
      let(:report_type) { 'rapid_connect_services' }
      let(:title) { 'Registered Rapid Connect Services' }
      let(:reported_objects) { [rapid_connect_service] }
      let(:excluded_objects) do
        [organization, identity_provider, service_provider]
      end

      it_behaves_like 'a report which lists federation objects'
    end

    context 'for a Service' do
      let(:report_type) { 'services' }
      let(:title) { 'Registered Services' }
      let(:reported_objects) { [service_provider, rapid_connect_service] }
      let(:excluded_objects) { [organization, identity_provider] }

      it_behaves_like 'a report which lists federation objects'
    end
  end
end
