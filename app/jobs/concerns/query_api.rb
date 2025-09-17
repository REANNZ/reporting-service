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

  # rubocop:disable Metrics/AbcSize
  def attribute_objects
    @attr_objects ||= api_data("#{attributes_base_url}/attributes.json")
    @category_objects ||= api_data("#{attributes_base_url}/categories.json")
    @category_objects.each do |cat|
      # Add to each category the list of attributes in the category.
      # API returns an dict where category_attributes is a list of lists,
      # with the inner lists having attribute name followed by its documentation link.
      cat[:attributes] ||= api_data("#{attributes_base_url}/categories/#{cat[:id]}.json")[:category_attributes].pluck(0)
    end
    Enumerator.new { |y| @attr_objects.each { |o| y << api_attr_to_fr_attr(o) } }
  end
  # rubocop:enable Metrics/AbcSize

  def api_attr_to_fr_attr(a)
    # Translate Validator attribute object to FR export API
    {
      name: a[:primary_alias_name],
      description: trim_description(a[:description]),
      category: {
        name: atribute_category_name(a[:primary_alias_name])
      }
    }
  end

  def atribute_category_name(a)
    # Find the category that lists this attribute
    cat_obj = @category_objects.find { |c| c[:attributes].include?(a) }
    cat_obj ? cat_obj[:name] : 'Unknown'
  end

  def trim_description(d)
    # Return early for blank values.
    return d unless d

    # Replace newlines with spaces, squeeze spaces
    d = d.gsub('\n', ' ').gsub('\r', ' ').squeeze(' ')

    return d unless d.length>255

    sentence_end = d.index('. ')
    if sentence_end && sentence_end < 255
      d[0, sentence_end + 1] # include the dot
    else
      d[0, 255] # trim anyway
    end
  end

  def api_data(endpoint)
    response = Net::HTTP.get_response(URI(endpoint))
    response.value
    ImplicitSchema.new(JSON.parse(response.body.to_s, symbolize_names: true))
  end

  def organizations_url
    api_config[:organizations_url]
  end

  def attributes_base_url
    api_config[:attributes_base_url]
  end

  def api_config
    Rails.application.config.reporting_service.api
  end
end
