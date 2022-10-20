class UnixUserManager::File::Passwd < UnixUserManager::File::Base
  def add(name:, uid:, gid:, shell: '/bin/bash')
    return false unless can_add?(name, uid)
    @new_records[name] = { uid: uid, gid: gid }

    true
  end

  def build_new_records
    @new_records.map { |name, data| "#{name}:x:#{data[:uid]}:#{data[:gid]}::/dev/null:#{shell}" }.join("\n")
  end
end
