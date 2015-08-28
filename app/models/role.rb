class Role < ActiveRecord::Base
  has_many :api_subject_roles
  has_many :api_subjects, through: :api_subject_roles

  has_many :subject_roles
  has_many :subjects, through: :subject_roles

  has_many :permissions

  valhammer

  def self.for_entitlement(entitlement)
    create_with(name: 'auto').find_or_create_by!(entitlement: entitlement)
      .tap(&:update_permissions)
  end

  def update_permissions
    return update_admin_permissions if entitlement == config[:admin_entitlement]
    return update_object_permissions if entitlement_suffix

    permissions.destroy_all
  end

  private

  def update_admin_permissions
    ensure_permission_values('*')
  end

  def update_object_permissions
    parts = entitlement_suffix.split(':', 3)

    return update_object_admin_permissions(parts) if parts[2] == 'admin'
    return if parts.length > 2

    values = ["objects:#{parts[0]}:#{parts[1]}:read",
              "objects:#{parts[0]}:#{parts[1]}:report"]
    ensure_permission_values(values)
  end

  def update_object_admin_permissions(parts)
    ensure_permission_values("objects:#{parts[0]}:#{parts[1]}:*")
  end

  def ensure_permission_values(values)
    Array(values).each { |v| permissions.find_or_create_by!(value: v) }
    permissions.where.not(value: values).destroy_all
  end

  def entitlement_suffix
    prefix = config[:federation_object_entitlement_prefix]
    return nil unless entitlement.start_with?("#{prefix}:")

    i = prefix.length + 1
    entitlement[i..-1]
  end

  def config
    Rails.application.config.reporting_service.ide
  end
end
