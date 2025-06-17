# frozen_string_literal: true

class SendEventsToFederationManager
  START_ID_KEY = 'send_fm_events_start_id'
  BATCH_SIZE = 200

  def perform(unique_ids: [])
    discovery_events =
      (
        if unique_ids.any?
          DiscoveryServiceEvent.where(unique_id: unique_ids)
        else
          DiscoveryServiceEvent.where(id: start_id..)
        end
      )
    # max sqs payload is 256kb
    discovery_events.in_batches(of: BATCH_SIZE) { |events| send_events(events:) }
    # reset the start_id if used unique_id
    redis.set(START_ID_KEY, 0) if unique_ids.any?
  end

  private

  def send_events(events:)
    redis.set(START_ID_KEY, events.first.id - 1)
    jwe =
      JSON::JWT
        .new({ 'iss' => 'reporting-service', 'events' => events.as_json(except: [:id]) })
        .sign(key, :RS256)
        .encrypt(key)
    sqs_client.send_message(queue_url:, message_body: jwe.to_s)
  end

  def sqs_client
    @sqs_client ||= Aws::SQS::Client.new(endpoint: sqs_config[:endpoint], region: sqs_config[:region])
  end

  def redis
    @redis ||= Rails.application.config.redis_client
  end

  def start_id
    env_start_id = ENV.fetch(START_ID_KEY.upcase, nil)
    return env_start_id.to_i if env_start_id.present?
    redis.get(START_ID_KEY).to_i
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
