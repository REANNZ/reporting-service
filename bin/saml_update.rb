#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../config/environment'

class SamlUpdateCLI
  def self.perform
    UpdateFromSamlService.perform
  end
end

SamlUpdateCLI.perform(*ARGV) if $PROGRAM_NAME == __FILE__
