class UnixUserManager::File::Passwd < UnixUserManager::File::Base
  def initialize(source)
    @edited_records = {}
    super
  end

  def add(name:, uid:, gid:, home_directory: '/dev/null', shell: '/bin/bash')
    return false unless can_add?(name, uid)
    @new_records[name] = { uid: uid, gid: gid, home_directory: home_directory, shell: shell }

    true
  end

  def edit(name:, uid: nil, gid: nil, home_directory: nil, shell: nil)
    return false unless exist?(name)

    # Ensure we have a resolvable current uid for the target user; otherwise, fail fast
    return false if find(name).nil?

    if uid
      current_name_for_uid = find_by_id(uid)
      return false if current_name_for_uid && current_name_for_uid != name

      return false if @edited_records.any? { |other_name, data| other_name != name && data[:uid] && data[:uid] == uid }
      return false if @new_records.any? { |other_name, data| other_name != name && data[:uid] == uid }
    end

    @edited_records[name] ||= { uid: nil, gid: nil, home_directory: nil, shell: nil }
    @edited_records[name][:uid] = uid unless uid.nil?
    @edited_records[name][:gid] = gid unless gid.nil?
    @edited_records[name][:home_directory] = home_directory unless home_directory.nil?
    @edited_records[name][:shell] = shell unless shell.nil?

    true
  end

  def build
    updated_source = source.split("\n").map do |line|
      stripped = line.strip
      if stripped[0] == '#'
        line
      else
        parts = line.split(':')
        uname = parts[0]
        if @edited_records.key?(uname)
          edits = @edited_records[uname]
          passwd_marker = parts[1]
          new_uid = edits[:uid].nil? ? parts[2] : edits[:uid].to_s
          new_gid = edits[:gid].nil? ? parts[3] : edits[:gid].to_s
          gecos = parts[4]
          new_home = edits[:home_directory].nil? ? parts[5] : edits[:home_directory]
          new_shell = edits[:shell].nil? ? parts[6] : edits[:shell]
          [uname, passwd_marker, new_uid, new_gid, gecos, new_home, new_shell].join(':')
        else
          line
        end
      end
    end.join("\n")

    if @new_records.any?
      updated_source + "\n" + build_new_records
    else
      updated_source
    end
  end

  def build_new_records
    @new_records.map do |name, data|
      "#{name}:x:#{data[:uid]}:#{data[:gid]}::#{data[:home_directory]}:#{data[:shell]}"
    end.join("\n")
  end
end
