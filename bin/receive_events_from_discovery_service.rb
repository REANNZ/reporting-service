#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../config/environment.rb'

ReceiveEventsFromDiscoveryService.new.perform
