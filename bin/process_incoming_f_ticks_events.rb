#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../config/environment'

ProcessIncomingFTicksEvents.new.perform
