class UnixUserManager::File::Passwd < UnixUserManager::File::LineFileBase
  def initialize(source)
    super
  end

  def add(name:, uid:, gid:, home_directory: '/dev/null', shell: '/bin/bash', password: nil, encrypted_password: nil, salt: nil, algorithm: :sha512)
    return false unless can_add?(name, uid)

    pass_field = 'x'
    if encrypted_password && !encrypted_password.to_s.empty?
      pass_field = encrypted_password
    elsif password && !password.to_s.empty?
      pass_field = UnixUserManager::Utils::Password.hash(password: password, algorithm: algorithm, salt: salt)
    end

    @new_records[name] = { uid: uid, gid: gid, home_directory: home_directory, shell: shell, password: pass_field }

    true
  end

  def edit(name:, uid: nil, gid: nil, home_directory: nil, shell: nil, password: nil, encrypted_password: nil, salt: nil, algorithm: :sha512)
    return false unless exist?(name)

    # Ensure we have a resolvable current uid for the target user; otherwise, fail fast
    return false if find(name).nil?

    if uid
      current_name_for_uid = find_by_id(uid)
      return false if current_name_for_uid && current_name_for_uid != name

      return false if @edited_records.any? { |other_name, data| other_name != name && data[:uid] && data[:uid] == uid }
      return false if @new_records.any? { |other_name, data| other_name != name && data[:uid] == uid }
    end

    @edited_records[name] ||= { uid: nil, gid: nil, home_directory: nil, shell: nil, password: nil }
    @edited_records[name][:uid] = uid unless uid.nil?
    @edited_records[name][:gid] = gid unless gid.nil?
    @edited_records[name][:home_directory] = home_directory unless home_directory.nil?
    @edited_records[name][:shell] = shell unless shell.nil?

    if encrypted_password && !encrypted_password.to_s.empty?
      @edited_records[name][:password] = encrypted_password
    elsif password && !password.to_s.empty?
      @edited_records[name][:password] = UnixUserManager::Utils::Password.hash(password: password, algorithm: algorithm, salt: salt)
    end

    true
  end

  def delete(name:)
    # If it's a newly added record, remove it from the staged new records
    if @new_records.key?(name)
      @new_records.delete(name)
      return true
    end

    # If it exists in the original data, mark for deletion
    return false unless exist?(name)

    @deleted_records[name] = true
    true
  end

  def build
    super
  end

  def build_new_records
    @new_records.map do |name, data|
      "#{name}:#{data[:password] || 'x'}:#{data[:uid]}:#{data[:gid]}::#{data[:home_directory]}:#{data[:shell]}"
    end.join("\n")
  end

  private

  def parse_key_and_id(fields)
    [fields[0], fields[2].to_i]
  end

  def apply_edits(parts, edits)
    uname = parts[0]
    passwd_marker = edits[:password].nil? ? parts[1] : edits[:password]
    uid = edits[:uid].nil? ? parts[2] : edits[:uid].to_s
    gid = edits[:gid].nil? ? parts[3] : edits[:gid].to_s
    gecos = parts[4]
    home = edits[:home_directory].nil? ? parts[5] : edits[:home_directory]
    shell = edits[:shell].nil? ? parts[6] : edits[:shell]
    [uname, passwd_marker, uid, gid, gecos, home, shell]
  end
end
