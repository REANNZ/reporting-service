#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../config/environment'

id_file = ENV.fetch('UNIQUE_IDS_FILE', nil)
unique_ids = []
if id_file.present?
  # expecting a file with unique IDs, separated by spaces
  unique_ids = File.read(id_file).split(' ')
end

SendEventsToFederationManager.new.perform(unique_ids:)
