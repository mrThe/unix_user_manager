class UnixUserManager::Users < UnixUserManager::Base
  attr_reader :shadow_file

  def initialize(passwd:, shadow:)
    @file = passwd
    @shadow_file = shadow
  end

  def build_passwd
    file.build
  end

  def build_shadow
    shadow_file.build
  end

  def build
    { passwd: build_passwd, shadow: build_shadow }
  end

  def add(name:, uid:, gid:)
    return false unless file.can_add?(name, uid) && shadow_file.can_add?(name)

    file.add(name: name, uid: uid, gid: gid) && shadow_file.add(name: name)
  end
end
