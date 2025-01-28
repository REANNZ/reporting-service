# frozen_string_literal: true

Rails.configuration.to_prepare { StaticErrors.write_public_error_files } unless Rails.env.production?
