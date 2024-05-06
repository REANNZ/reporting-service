# frozen_string_literal: true

require 'net/http'

class UpdateFromSAMLService
  SAML_NAMESPACES = {
    'xmlns' => 'urn:oasis:names:tc:SAML:2.0:metadata',
    'xmlns:md' => 'urn:oasis:names:tc:SAML:2.0:metadata',
    'xmlns:saml' => 'urn:oasis:names:tc:SAML:2.0:assertion',
    'xmlns:idpdisc' => 'urn:oasis:names:tc:SAML:profiles:SSO:idp-discovery-protocol',
    'xmlns:mdrpi' => 'urn:oasis:names:tc:SAML:metadata:rpi',
    'xmlns:mdui' => 'urn:oasis:names:tc:SAML:metadata:ui',
    'xmlns:mdattr' => 'urn:oasis:names:tc:SAML:metadata:attribute',
    'xmlns:shibmd' => 'urn:mace:shibboleth:metadata:1.0',
    'xmlns:ds' => 'http://www.w3.org/2000/09/xmldsig#',
    'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
    'xmlns:fed' => 'http://docs.oasis-open.org/wsfed/federation/200706',
    'xmlns:privacy' => 'http://docs.oasis-open.org/wsfed/privacy/200706',
    'xmlns:remd' => 'http://refeds.org/metadata'
  }.freeze

  def self.perform
    new.perform
  end

  def perform
    @service_providers = []
    @identity_providers = []

    ActiveRecord::Base.transaction do
      document.xpath("//md:EntityDescriptor", SAML_NAMESPACES).each do |node|
        process_entity(node)
      end

      clean
    end

    nil
  end

  def process_entity(node)
    entity_id = node.attributes["entityID"].value

    org_node = xpath_at(node, "./md:Organization")
    return if org_node.nil?

    org = process_org(org_node)
    return if org.nil?

    reg_info_node = xpath_at(node, "./md:Extensions/mdrpi:RegistrationInfo")
    reg_date = nil
    if reg_info_node then
      reg_instant_attr = reg_info_node.attributes["registrationInstant"]
      reg_date = reg_instant_attr.value if reg_instant_attr
    end

    idp_node = xpath_at(node, "./md:IDPSSODescriptor")
    idp = process_idp(idp_node, entity_id, org) unless idp_node.nil?
    @identity_providers.append(idp) if idp

    sp_node = xpath_at(node, "./md:SPSSODescriptor")
    sp = process_sp(sp_node, entity_id, org) unless sp_node.nil?
    @service_providers.append(sp) if sp

    if reg_date then
      activate_object(idp, reg_date) if idp
      activate_object(sp, reg_date) if sp
    end
  end

  def process_org(node)
    org_id_node = xpath_at(node, "./md:OrganizationName")
    return nil if org_id_node.nil?
    org_name_node = xpath_at(node, "./md:OrganizationDisplayName")
    return nil if org_name_node.nil?

    org_id = org_id_node.content.strip
    org_name = org_name_node.content.strip

    org = Organization.find_or_initialize_by(domain: org_id)
    org_attrs = { name: org_name }
    if org.id.nil? then
      org_attrs[:identifier] = org_identifier(org_id)
    end
    org.update!(org_attrs)

    org
  end

  def process_idp(node, entity_id, org)
    idp = IdentityProvider.find_or_initialize_by(entity_id: entity_id)

    name_node = xpath_at(node, './md:Extensions/mdui:UIInfo/mdui:DisplayName')
    name = name_node.content.strip if name_node

    idp.update!(name: name, organization: org)

    idp_attributes = idp.identity_provider_saml_attributes

    attrs = xpath(node, './saml:Attribute').map do |attr|
      attr_name = attr.attributes["FriendlyName"].value
      attribute = SAMLAttribute.find_by(name: attr_name)
      next if attribute.nil?

      assoc = idp_attributes.find_or_initialize_by(saml_attribute_id: attribute.id)
      assoc.save
      assoc
    end

    # Delete attributes that aren't associated with this IdP any more
    attrs.compact!
    idp_attributes.where.not(id: attrs.map(&:id)).destroy_all

    idp
  end

  def process_sp(node, entity_id, org)
    sp = ServiceProvider.find_or_initialize_by(entity_id: entity_id)

    name_node = xpath_at(node, './md:Extensions/mdui:UIInfo/mdui:DisplayName')
    name = name_node.content.strip if name_node

    sp.update!(name: name, organization: org)

    sp_attributes = sp.service_provider_saml_attributes
    attrs = xpath(node, './md:AttributeConsumingService/md:RequestedAttribute').map do |attr|
      attr_name = attr.attributes["FriendlyName"].value
      attribute = SAMLAttribute.find_by(name: attr_name)
      next if attribute.nil?

      assoc = sp_attributes.find_or_initialize_by(saml_attribute_id: attribute.id)

      is_req_attr = attr.attributes["isRequired"]
      is_req = is_req_attr.nil? ? false : is_req_attr.value == "true"

      assoc.update!(optional: !is_req)
      assoc
    end

    # Delete attributes that aren't associated with this SP any more
    attrs.compact!
    sp_attributes.where.not(id: attrs.map(&:id)).destroy_all

    sp
  end

  def activate_object(obj, date)
    obj.activations.find_or_initialize_by({}).update!(activated_at: date)
  end

  def document
    doc = Nokogiri::XML.parse(retrieve(source))

    verify_signature(doc)

    saml_md_urn = 'urn:oasis:names:tc:SAML:2.0:metadata'
    root = doc.root

    return doc if root.namespaces.key(saml_md_urn) == 'xmlns'

    prev_prefix = doc.root.namespace.prefix
    doc.root.default_namespace = saml_md_urn
    new_doc_markup = doc.canonicalize.gsub(%r{([<|/])(#{prev_prefix}:)}, '\1')

    Nokogiri::XML.parse(new_doc_markup)
  end

  def retrieve(source_url)
    url = URI.parse(source_url)
    response = perform_http_client_request(url)

    return response.body if response.is_a?(Net::HTTPSuccess)

    raise("Unable to retrieve metadata from #{source_url} (#{response.code} #{response.message})")
  end

  def perform_http_client_request(url)
    request = Net::HTTP::Get.new(url)
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = (url.scheme == 'https')
    http.read_timeout = 600
    request['Accept'] = "application/samlmetadata+xml"

    http.request(request)
  end

  def verify_signature(doc)
    cert = metadata_cert
    return if cert.nil?

    return if Xmldsig::SignedDocument.new(doc).validate(cert)

    raise("Invalid signature for metadata from #{source}")
  end

  def source
    configuration[:metadata_url]
  end

  def metadata_cert
    cert = configuration[:metadata_cert]
    OpenSSL::X509::Certificate.new(cert) if cert
  end

  def configuration
    Rails.application.config.reporting_service.saml_service
  end

  def xpath(node, path)
    node.xpath(path, SAML_NAMESPACES)
  end

  def xpath_at(node, path)
    xpath(node, path)[0]
  end

  def org_identifier(name)
    # Generate a valid identifier for an organisation given the OrganisationName (domain)
    digest = OpenSSL::Digest.new('SHA256').digest("tuakiri:subscriber:#{name}")
    Base64.urlsafe_encode64(digest, padding: false)
  end

  def clean
    # Deactivate IdPs and SPs that we didn't see while processing, but are currently
    # considered active.
    idps = IdentityProvider.where.not(id: @identity_providers.map(&:id)).active
    idps.each do |idp|
      idp.activations.update_all(deactivated_at: Time::now)
    end

    sps = ServiceProvider.where.not(id: @service_providers.map(&:id)).active
    sps.each do |sp|
      sp.activations.update_all(deactivated_at: Time::now)
    end
  end
end
