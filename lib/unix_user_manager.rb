require "unix_user_manager/version"

require "unix_user_manager/file/base"
require "unix_user_manager/file/group"
require "unix_user_manager/file/passwd"
require "unix_user_manager/file/shadow"
require "unix_user_manager/utils/password"

require "unix_user_manager/base"
require "unix_user_manager/groups"
require "unix_user_manager/users"

class UnixUserManager
  attr_reader :passwd, :shadow, :group,
              :users, :groups

  def initialize(passwd:, shadow:, group:)
    @passwd = UnixUserManager::File::Passwd.new passwd
    @shadow = UnixUserManager::File::Shadow.new shadow
    @group  = UnixUserManager::File::Group.new  group

    @users  = UnixUserManager::Users.new(passwd: @passwd, shadow: @shadow)
    @groups = UnixUserManager::Groups.new(group: @group)
  end

  def available_id(min_id: 100, max_id: 500, preffered_ids: [200, 300, 333, 400, 500], recursive: false)
    ids = available_ids(min_id: min_id, max_id: max_id)

    new_id = (ids & preffered_ids).any? ? (ids & preffered_ids)[0] : ids[0]

    if recursive && new_id.nil?
      available_id(min_id: min_id, preffered_ids: preffered_ids, recursive: recursive, max_id: max_id + 100)
    else
      new_id
    end
  end

  def available_ids(min_id: 100, max_id: 500)
    # Service ids must be from 100 to 500
    available_uid = (min_id..max_id).to_a - users.ids
    available_gid = (min_id..max_id).to_a - groups.ids

    available_uid & available_gid
  end
end
