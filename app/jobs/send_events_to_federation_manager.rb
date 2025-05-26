# frozen_string_literal: true

class SendEventsToFederationManager
  def perform
    DiscoveryServiceEvent.in_batches(of: 10) { |events| send_events(events:) }
  end

  private

  def send_events(events:)
    jwe =
      JSON::JWT
        .new({ 'iss' => 'reporting-service', 'events' => events.map { |event| event.to_json(except: [:id]) } })
        .sign(key, :RS256)
        .encrypt(key)
    sqs_client.send_message(queue_url:, message_body: jwe.to_s)
  end

  def sqs_client
    @sqs_client ||= Aws::SQS::Client.new(endpoint: sqs_config[:endpoint], region: sqs_config[:region])
  end

  def sqs_config
    Rails.application.config.reporting_service.sqs
  end

  def queue_url
    sqs_config[:queues][:federation_manager]
  end

  def key
    @key ||= OpenSSL::PKey::RSA.new(Base64.decode64(sqs_config[:encryption_key]))
  end
end
