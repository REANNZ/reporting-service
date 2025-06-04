# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SendEventsToFederationManager, type: :job do
  describe '#perform' do
    subject(:run) { described_class.new.perform }

    let(:sqs_client) { double(Aws::SQS::Client) }
    let(:redis_client) { Rails.application.config.redis_client }
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
    let(:expect_count) { count / described_class::BATCH_SIZE }

    before do
      events
      allow(Rails.application.config.reporting_service).to receive(:sqs).and_return(sqs_config)

      allow(Aws::SQS::Client).to receive(:new).with(sqs_config.slice(:endpoint, :region)).and_return(sqs_client)

      allow(redis_client).to receive(:set).and_call_original
      allow(redis_client).to receive(:get).and_call_original

      allow(sqs_client).to receive(:send_message).with(
        { message_body: anything, queue_url: sqs_config[:queues][:federation_manager] }
      ).and_return(anything)
    end

    it 'creates the events, doesn\'t after the first run' do
      run
      expect(sqs_client).to have_received(:send_message).exactly(expect_count).times
      expect(redis_client).to have_received(:set).exactly(expect_count).times
      expect(redis_client.get(described_class::START_ID_KEY)).to match(
        (events.last(described_class::BATCH_SIZE).first.id - 1).to_s
      )
      RSpec::Mocks.space.proxy_for(redis_client).reset
      RSpec::Mocks.space.proxy_for(sqs_client).reset

      allow(redis_client).to receive(:set).and_call_original
      allow(redis_client).to receive(:get).and_call_original
      allow(sqs_client).to receive(:send_message).with(
        { message_body: anything, queue_url: sqs_config[:queues][:federation_manager] }
      ).and_return(anything)
      run
      expect(sqs_client).not_to have_received(:send_message)
      expect(redis_client).not_to have_received(:set)
    end

    context 'when START_ID is set' do
      before do
        redis_client.set(described_class::START_ID_KEY, events.last(offset).first.id)
        RSpec::Mocks.space.proxy_for(redis_client).reset
        allow(redis_client).to receive(:set).and_call_original
      end

      let(:offset) { described_class::BATCH_SIZE * 2 }
      let(:expect_count) { offset / described_class::BATCH_SIZE }

      it 'starts from the specified ID' do
        run
        expect(sqs_client).to have_received(:send_message).exactly(expect_count).times
        expect(redis_client).to have_received(:set).exactly(expect_count).times
        expect(redis_client.get(described_class::START_ID_KEY)).to match(
          (events.last(described_class::BATCH_SIZE).first.id - 1).to_s
        )
      end
    end

    context 'when START_ID ENV is set' do
      before do
        allow(ENV).to receive(:fetch).with(described_class::START_ID_KEY.upcase, nil).and_return(
          events.last(offset).first.id.to_s
        )
      end

      let(:offset) { described_class::BATCH_SIZE * 2 }
      let(:expect_count) { offset / described_class::BATCH_SIZE }

      it 'starts from the specified ID, calls set an extra time' do
        run
        expect(sqs_client).to have_received(:send_message).exactly(expect_count).times
        expect(redis_client).to have_received(:set).exactly(expect_count).times
        expect(redis_client.get(described_class::START_ID_KEY)).to match(
          (events.last(described_class::BATCH_SIZE).first.id - 1).to_s
        )
      end
    end
  end
end
