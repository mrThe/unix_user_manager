class UnixUserManager::File::Group < UnixUserManager::File::Base
  def add(name:, uname:, gid:)
    return false unless can_add?(name, gid)
    @new_records[name] = { gid: gid, uname: uname }

    true
  end

  private

  def build_new_records
    @new_records.map { |name, data| "#{name}:x:#{data[:gid]}:#{data[:uname]}" }.join("\n")
  end
end
