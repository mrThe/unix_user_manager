class UnixUserManager::Groups < UnixUserManager::Base
  def initialize(group:)
    @file = group
  end

  def edit(name:, gid: nil, uname: nil)
    file.edit(name: name, gid: gid, uname: uname)
  end

  def delete(name:)
    file.delete(name: name)
  end
end
