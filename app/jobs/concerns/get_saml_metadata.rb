# frozen_string_literal: true

module GetSAMLMetadata
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

  def document(source, cert)
    doc = Nokogiri::XML.parse(retrieve(source))

    verify_signature(doc, cert) if cert

    doc
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
    request['Accept'] = 'application/samlmetadata+xml'

    http.request(request)
  end

  def verify_signature(doc, cert)
    return if Xmldsig::SignedDocument.new(doc).validate(cert)

    raise("Invalid signature for metadata from #{source}")
  end

  def xpath(node, path)
    node.xpath(path, SAML_NAMESPACES)
  end

  def xpath_at(node, path)
    xpath(node, path)[0]
  end

  def attr_val(node, attr)
    node.attributes[attr]&.value
  end
end
