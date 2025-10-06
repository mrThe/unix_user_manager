class UnixUserManager::File::Group < UnixUserManager::File::LineFileBase
  def initialize(source)
    super
  end

  def add(name:, uname:, gid:)
    return false unless can_add?(name, gid)
    @new_records[name] = { gid: gid, uname: uname }

    true
  end

  def edit(name:, gid: nil, uname: nil)
    return false unless exist?(name)

    if gid
      current_name_for_gid = find_by_id(gid)
      return false if current_name_for_gid && current_name_for_gid != name
      return false if @edited_records.any? { |other_name, data| other_name != name && data[:gid] && data[:gid] == gid }
      return false if @new_records.any? { |other_name, data| other_name != name && data[:gid] == gid }
    end

    @edited_records[name] ||= { gid: nil, uname: nil }
    @edited_records[name][:gid] = gid unless gid.nil?
    @edited_records[name][:uname] = uname unless uname.nil?

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

  def build_new_records
    @new_records.map { |name, data| "#{name}:x:#{data[:gid]}:#{data[:uname]}" }.join("\n")
  end

  private

  def parse_key_and_id(fields)
    [fields[0], fields[2].to_i]
  end

  def apply_edits(parts, edits)
    uname = parts[0]
    passwd_marker = parts[1]
    gid = edits[:gid].nil? ? parts[2] : edits[:gid].to_s
    members = parts[3] || ""
    new_members = edits[:uname].nil? ? members : edits[:uname]
    [uname, passwd_marker, gid, new_members]
  end
end
