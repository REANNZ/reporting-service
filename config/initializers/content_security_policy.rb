# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header

Rails.application.config.content_security_policy do |policy|
  policy.frame_ancestors :none
  policy.default_src :self
  policy.object_src :none
  policy.frame_src :self
  font_src = %i[self data]
  img_src = %i[self data blob]
  media_src = %i[self data]
  script_src = %i[self]
  connect_src = %i[self]
  style_src = [
    :self,
    '\'unsafe-hashes\'',
    # hash for FontAwesome hidden svg symbols
    '\'sha256-biLFinpqYMtWHmXfkA1BPeCY0/fNt46SAZ+BBk5YUog=\''
  ]

  if (asset_host = Rails.configuration.action_controller.asset_host)
    font_src << asset_host
    img_src << asset_host
    script_src << asset_host
    style_src << asset_host
  end

  sentry_dsn = ENV.fetch('SENTRY_DSN', 'https://12345@o12345.ingest.us.sentry.io/12345')
  connect_src << "https://#{sentry_dsn.gsub('https://', '').split('@').last.split('/').first}"

  if Rails.env.production?
    connect_src << "wss://#{ENV.fetch('SERVICE_HOSTNAME', nil)}"
    policy.upgrade_insecure_requests true
  end

  # Necessary for Webpack development builds
  script_src << '\'unsafe-eval\'' if Rails.env.development?

  policy.font_src(*font_src)
  policy.img_src(*img_src.uniq)
  policy.media_src(*media_src)
  policy.script_src(*script_src)
  policy.style_src(*style_src)
  policy.connect_src(*connect_src)
end

# If you are using UJS then enable automatic nonce generation
Rails.application.config.content_security_policy_nonce_generator = ->(_request) { SecureRandom.base64(16) }

# Set the nonce only to specific directives
Rails.application.config.content_security_policy_nonce_directives = %w[script-src style-src]

# Report CSP violations to a specified URI
# For further information see the following documentation:
# https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy-Report-Only
# Rails.application.config.content_security_policy_report_only = true
