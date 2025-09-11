# frozen_string_literal: true

require 'net/http'

module QueryAPI
  def organization_objects
    @org_objects ||= api_data(organizations_url)[:organizations]
    Enumerator.new { |y| @org_objects.each { |o| y << api_org_to_fr_org(o) } }
  end

  def api_org_to_fr_org(o)
    # Make the object look like it was returned by FR export API
    {
      id: o[:id],
      domain: o[:organizationInfoData][:en][:OrganizationName],
      display_name: o[:organizationInfoData][:en][:OrganizationDisplayName],
      created_at: DateTime.parse(o[:memberSince]),
      updated_at: o[:active] ? DateTime.parse(o[:memberSince]) : DateTime.parse(o[:notMemberAfter]),
      functioning: o[:active]
    }
  end

  def api_data(endpoint)
    response = Net::HTTP.get_response(endpoint)
    response.value
    ImplicitSchema.new(JSON.parse(response.body.to_s, symbolize_names: true))
  end

  def organizations_url
    URI(api_config[:organizations_url])
  end

  def api_config
    Rails.application.config.reporting_service.api
  end
end
