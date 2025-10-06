class UnixUserManager::ShadowGroups < UnixUserManager::Base
  def initialize(gshadow:)
    @file = gshadow
  end

  def edit(name:, password: nil, encrypted_password: nil, admins: nil, members: nil)
    file.edit(name: name, password: password, encrypted_password: encrypted_password, admins: admins, members: members)
  end

  def add(name:, password: nil, encrypted_password: nil, admins: nil, members: nil)
    file.add(name: name, password: password, encrypted_password: encrypted_password, admins: admins, members: members)
  end

  def delete(name:)
    file.delete(name: name)
  end
end

