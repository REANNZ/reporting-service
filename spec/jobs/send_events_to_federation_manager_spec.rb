# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SendEventsToFederationManager, type: :job do
  describe '#perform' do
    subject(:run) { described_class.new.perform }

    let(:client) { double(Aws::SQS::Client) }
    let(:rsa_key_string) { <<~RAWCERT }
        -----BEGIN RSA PRIVATE KEY-----
        MIIBOwIBAAJBANXI+YMTbremHgVLuc/AbaZTKeqvXgs32Em6OOCbE7P+flb3qAMO
        t2SgUCSFYZAOGk8SUoO3ffj6n30cfRA/weUCAwEAAQJAJ+eYs1/INd17Ew/8ggvw
        K7CwTU8opb1p0PFCtqIbvmf2QkljOnT9AvC9HXEi+f3soy2Nas8u0x9DfV2AStl4
        YQIhAO3LMGvPvLqLq/1gg9smR7RnjhcIMoP5RkOjMhXry4jpAiEA5ic14uiAb5If
        KOMObaIHYlg5sufDIy1CwRU5Exz3k50CIQDhRL0RVVIAEvMS7Mzc3i3NnNCBxzU7
        yvkieEapd6BwiQIhAMkHns3f/690lrsD+OpSCNkh7uQSBCSJuDEm9H95YdcRAiBY
        GGUfLfsFNdNhxp69xipHXoL6od4h/fWWrjZhu1/aiQ==
        -----END RSA PRIVATE KEY-----
      RAWCERT
    let(:key) { OpenSSL::PKey::RSA.new(rsa_key_string) }

    let(:sqs_config) do
      {
        fake: false,
        region: 'dummy',
        endpoint: Faker::Internet.url,
        encryption_key: Base64.encode64(rsa_key_string),
        queues: {
          discovery: Faker::Internet.url
        }
      }
    end

    let(:events) { create_list(:discovery_service_event, count) }

    let(:count) { 1000 }

    before do
      events
      allow(Rails.application.config.reporting_service).to receive(:sqs).and_return(sqs_config)

      allow(Aws::SQS::Client).to receive(:new).with(sqs_config.slice(:endpoint, :region)).and_return(client)

      allow(client).to receive(:send_message).with(
        { message_body: anything, queue_url: sqs_config[:queues][:federation_manager] }
      ).and_return(anything)
    end

    it 'creates the events' do
      run
      expect(client).to have_received(:send_message).exactly(count / 10).times
    end
  end
end
