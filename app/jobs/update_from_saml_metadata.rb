# frozen_string_literal: true
# rubocop:disable Metrics/ClassLength

require 'net/http'

class UpdateFromSAMLMetadata
  include GetSAMLMetadata

  def self.perform
    new.perform
  end

  def perform
    @service_providers = []
    @identity_providers = []

    doc = document(source, metadata_cert)
    ActiveRecord::Base.transaction do
      doc.xpath('//md:EntityDescriptor', SAML_NAMESPACES).each do |node|
        process_entity(node)
      end

      clean
    end

    nil
  end

  def process_entity(node)
    entity_id = node.attributes['entityID'].value

    org_node = xpath_at(node, './md:Organization')
    org = process_org(org_node) if org_node
    return unless org

    reg_info_node = xpath_at(node, './md:Extensions/mdrpi:RegistrationInfo')
    reg_date = attr_val(reg_info_node, 'registrationInstant') if reg_info_node

    idp_node = xpath_at(node, './md:IDPSSODescriptor')
    process_idp(idp_node, entity_id, org, reg_date) if idp_node

    sp_node = xpath_at(node, './md:SPSSODescriptor')
    process_sp(sp_node, entity_id, org, reg_date) if sp_node
  end

  # rubocop:disable Metrics/MethodLength
  def process_org(node)
    org_domain_node = xpath_at(node, './md:OrganizationName')
    org_name_node = xpath_at(node, "./md:OrganizationDisplayName[@xml:lang='en']") ||
                    xpath_at(node, "./md:OrganizationDisplayName[starts-with(@xml:lang, 'en')]")

    return nil unless org_domain_node && org_name_node

    org_domain = org_domain_node.content.strip
    org_name = org_name_node.content.strip

    org = Organization.find_or_initialize_by(domain: org_domain)
    org_attrs = { name: org_name }

    org_attrs[:identifier] = org_identifier_from_name(org_domain) if org.id.nil?

    org.update!(org_attrs)

    org
  end
  # rubocop:enable Metrics/MethodLength

  def process_idp(node, entity_id, org, reg_date)
    idp = IdentityProvider.find_or_initialize_by(entity_id: )

    name_node = xpath_at(node, "./md:Extensions/mdui:UIInfo/mdui:DisplayName[@xml:lang='en']") ||
                xpath_at(node, "./md:Extensions/mdui:UIInfo/mdui:DisplayName[starts-with(@xml:lang, 'en')]")
    name = name_node.content.strip if name_node

    idp.update!(name: , organization: org)

    idp_attributes = idp.identity_provider_saml_attributes
    process_idp_attributes(idp_attributes, node)

    @identity_providers.append(idp)
    activate_object(idp, reg_date)
  end

  def process_sp(node, entity_id, org, reg_date)
    sp = ServiceProvider.find_or_initialize_by(entity_id: )

    name_node = xpath_at(node, "./md:Extensions/mdui:UIInfo/mdui:DisplayName[@xml:lang='en']") ||
                xpath_at(node, "./md:Extensions/mdui:UIInfo/mdui:DisplayName[starts-with(@xml:lang, 'en')]")
    name = name_node.content.strip if name_node

    sp.update!(name: , organization: org)

    sp_attributes = sp.service_provider_saml_attributes
    process_sp_attributes(sp_attributes, node)

    @service_providers.append(sp)
    activate_object(sp, reg_date)
  end

  def process_idp_attributes(scope, node)
    nodes = xpath(node, './saml:Attribute')
    process_attributes(scope, nodes) do |_, assoc|
      assoc.save
    end
  end

  def process_sp_attributes(scope, node)
    nodes = xpath(node, './md:AttributeConsumingService/md:RequestedAttribute')
    process_attributes(scope, nodes) do |attr, assoc|
      is_req = attr_val(attr, 'isRequired') == 'true'
      assoc.update(optional: !is_req)
    end
  end

  def process_attributes(scope, nodes)
    attrs = nodes.map do |attr|
      attr_name = attr_val(attr, 'FriendlyName')
      attribute = SAMLAttribute.find_by(name: attr_name)
      next unless attribute

      assoc = scope.find_or_initialize_by(saml_attribute_id: attribute.id)

      assoc if yield attr, assoc
    end

    # Delete attributes that aren't associated with this IdP/SP any more
    scope.where.not(id: attrs.compact.map(&:id)).destroy_all
  end

  def activate_object(obj, date)
    obj.activations.find_or_initialize_by({}).update!(activated_at: date, deactivated_at: nil)
  end

  def source
    configuration[:metadata_url]
  end

  def metadata_cert
    cert_path = configuration[:metadata_cert_path]
    OpenSSL::X509::Certificate.new(File.read(cert_path)) if cert_path
  end

  def configuration
    Rails.application.config.reporting_service.saml_metadata
  end

  def org_identifier_from_name(name)
    # Generate a valid identifier for an organisation given the OrganisationName (domain)
    digest = OpenSSL::Digest.new('SHA256').digest("tuakiri:subscriber:#{name}")
    Base64.urlsafe_encode64(digest, padding: false)
  end

  def clean
    # Deactivate IdPs and SPs that we didn't see while processing, but are currently
    # considered active.
    clean_entities(IdentityProvider.where.not(id: @identity_providers.map(&:id)).active)
    clean_entities(ServiceProvider.where.not(id: @service_providers.map(&:id)).active)
  end

  def clean_entities(entities)
    entities.each do |e|
      e.activations.each do |a|
        a.update(deactivated_at: Time.current)
      end
    end
  end
end
# rubocop:enable Metrics/ClassLength
