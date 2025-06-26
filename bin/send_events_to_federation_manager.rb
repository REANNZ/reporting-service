#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../config/environment'

id_file = ENV.fetch('IDS_FILE', nil)
ids = []
if id_file.present?
  # expecting a file with unique IDs, separated by spaces
  ids = File.read(id_file).split(' ')
end

SendEventsToFederationManager.new.perform(ids:)
