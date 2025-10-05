class UnixUserManager::Users < UnixUserManager::Base
  attr_reader :shadow_file

  def initialize(passwd:, shadow:)
    @file = passwd
    @shadow_file = shadow
  end

  def build_passwd
    file.build
  end

  def build_passwd_new_records
    file.build_new_records
  end

  def build_shadow
    shadow_file.build
  end

  def build_shadow_new_records
    shadow_file.build_new_records
  end

  def build
    { passwd: build_passwd, shadow: build_shadow }
  end

  def build_new_records
    { passwd: build_passwd_new_records, shadow: build_shadow_new_records }
  end

  def add(name:, uid:, gid:, password: nil, encrypted_password: nil, salt: nil, algorithm: :sha512)
    return false unless file.can_add?(name, uid) && shadow_file.can_add?(name)

    file.add(name: name, uid: uid, gid: gid) && shadow_file.add(name: name, password: password, encrypted_password: encrypted_password, salt: salt, algorithm: algorithm)
  end

  def edit(name:, uid: nil, gid: nil, home_directory: nil, shell: nil)
    file.edit(name: name, uid: uid, gid: gid, home_directory: home_directory, shell: shell)
  end

  def edit_shadow(name:, password: nil, encrypted_password: nil, salt: nil, algorithm: :sha512)
    shadow_file.edit(name: name, password: password, encrypted_password: encrypted_password, salt: salt, algorithm: algorithm)
  end
end
