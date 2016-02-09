class UnixUserManager::Groups < UnixUserManager::Base
  def initialize(group:)
    @file = group
  end
end
