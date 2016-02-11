Rails.application.configure do
  app_config = YAML.load(Rails.root.join('config/reporting_service.yml').read)
  config.reporting_service = OpenStruct.new(app_config.deep_symbolize_keys)

  if Rails.env.test?
    config.reporting_service.ide = {
      host: 'ide.example.edu',
      cert: 'spec/api.crt',
      key: 'spec/api.key',
      admin_entitlement: 'urn:mace:aaf.edu.au:ide:internal:aaf-admin',
      federation_object_entitlement_prefix: 'urn:mace:aaf.edu.au:ide:internal'
    }

    config.reporting_service.federationregistry = {
      host: 'manager.example.edu',
      secret: 'abcdef'
    }

    config.reporting_service.rapidconnect = {
      host: 'rapid.example.edu',
      secret: 'fedcba'
    }

    config.reporting_service.sqs = {
      fake: false,
      region: 'dummy',
      endpoint: 'https://dummy.sqs.example.edu',
      encryption_key: 'spec/encryption_key.pem',
      queues: {
        discovery: 'https://dummy.sqs.example.edu/queue/discovery-service-test'
      }
    }

    Aws::SQS::Client.remove_plugin(Aws::Plugins::SQSQueueUrls)
    Aws.config.update(stub_responses: true)
  end

  sqs_config = config.reporting_service.sqs
  if sqs_config[:fake]
    begin
      Aws::SQS::Client.remove_plugin(Aws::Plugins::SQSQueueUrls)

      sqs_client = Aws::SQS::Client.new(region: sqs_config[:region],
                                        endpoint: sqs_config[:endpoint])

      sqs_config[:queues].each do |_, url|
        queue_name = url.split('/').last
        sqs_client.create_queue(queue_name: queue_name)
      end
    rescue
      :ok
    end
  end
end