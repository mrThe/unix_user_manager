class UnixUserManager::File::Passwd < UnixUserManager::File::Base
  def add(name:, uid:, gid:, home_directory: '/dev/null', shell: '/bin/bash')
    return false unless can_add?(name, uid)
    @new_records[name] = { uid: uid, gid: gid, home_directory: home_directory, shell: shell }

    true
  end

  def build_new_records
    @new_records.map do |name, data|
      "#{name}:x:#{data[:uid]}:#{data[:gid]}::#{data[:home_directory]}:#{data[:shell]}"
    end.join("\n")
  end
end
