class IdentityProviderAttributesReport < TabularReport
  report_type 'identity-provider-attributes'
  header ['Name', 'Core Attributes', 'Optional Attributes']
  footer

  def initialize
    super('Identity Provider Attributes')
  end

  def rows
    sorted_idps = activated_identitiy_providers.sort_by do |idp|
      idp.name.downcase
    end

    sorted_idps.map do |idp|
      optional_attributes = idp.saml_attributes.count
      [idp.name, '2', "#{optional_attributes}"]
    end
  end

  private

  def activated_identitiy_providers
    IdentityProvider.find_active.joins(:saml_attributes)
      .preload(:saml_attributes)
  end
end
