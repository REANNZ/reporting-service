# frozen_string_literal: true

class SubscriberReports < ApplicationController
  include Steps

  before_action { permitted_objects(model_object) }
  before_action :requested_entity
  before_action :set_range_params
  before_action :access_method

  private

  def requested_entity
    return if params[:entity_id].blank?

    @entity = @entities.detect do |entity|
      entity.entity_id == params[:entity_id]
    end
  end

  def output(report_type, steps = nil)
    report = generate_report(report_type, steps)
    JSON.generate(report.generate)
  end

  def generate_report(report_type, steps = nil)
    @entity_id = params[:entity_id]

    return report_type.new(@entity_id, start, finish, steps) if steps
    report_type.new(@entity_id, start, finish)
  end

  def access_method
    return public_action if params[:entity_id].blank?
    check_access! permission_string(@entity)
  end

  def permission_string(entity)
    "objects:organization:#{entity.organization.identifier}:report"
  end

  def permitted_objects(model)
    active_objects = model.preload(:organization).active

    @entities = active_objects.select do |sp|
      subject.permits? permission_string(sp)
    end
  end
end
