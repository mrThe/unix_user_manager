class UnixUserManager::File::Passwd < UnixUserManager::File::Base
  def add(name:, uid:, gid:, home_directory: '/dev/null', shell: '/bin/bash')
    return false unless can_add?(name, uid)
    @new_records[name] = { uid: uid, gid: gid }

    true
  end

  def build_new_records
    @new_records.map do |name, data|
      "#{name}:x:#{data[:uid]}:#{data[:gid]}::#{home_directory}:#{shell}"
    end.join("\n")
  end
end
