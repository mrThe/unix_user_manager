class UnixUserManager::File::Group < UnixUserManager::File::Base
  def initialize(source)
    @edited_records = {}
    @deleted_records = {}
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

  def build
    updated_source = source.split("\n").map do |line|
      stripped = line.strip
      if stripped[0] == '#'
        line
      else
        parts = line.split(':')
        uname = parts[0]
        # drop deleted entries
        next nil if @deleted_records.key?(uname)
        if @edited_records.key?(uname)
          edits = @edited_records[uname]
          passwd_marker = parts[1]
          new_gid = edits[:gid].nil? ? parts[2] : edits[:gid].to_s
          members = parts[3] || ""
          new_members = edits[:uname].nil? ? members : edits[:uname]
          [uname, passwd_marker, new_gid, new_members].join(':')
        else
          line
        end
      end
    end.compact.join("\n")

    if @new_records.any?
      updated_source + "\n" + build_new_records
    else
      updated_source
    end
  end

  def build_new_records
    @new_records.map { |name, data| "#{name}:x:#{data[:gid]}:#{data[:uname]}" }.join("\n")
  end
end
