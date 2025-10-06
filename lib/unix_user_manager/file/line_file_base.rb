class UnixUserManager::File::LineFileBase
  attr_reader :source, :data, :new_records, :edited_records, :deleted_records

  def initialize(source)
    @source = source
    @new_records = {}
    @edited_records = {}
    @deleted_records = {}
    parse_index
  end

  def ids
    data.values.compact.sort
  end

  def find(name)
    data[name]
  end

  def find_by_id(id)
    data.key id
  end

  def exist?(name)
    !!data[name]
  end

  def id_exist?(id)
    return false if id.nil?
    !!data.key(id)
  end

  def can_add?(name, id = nil)
    !(exist?(name) || id_exist?(id) || @new_records.key?(name))
  end

  def all
    data
  end

  def delete(name:)
    if @new_records.key?(name)
      @new_records.delete(name)
      return true
    end
    return false unless exist?(name)
    @deleted_records[name] = true
    true
  end

  def build
    if @edited_records.empty? && @deleted_records.empty?
      return @new_records.any? ? (source + "\n" + build_new_records) : source
    end

    updated_source = source.split("\n").map do |line|
      stripped = line.strip
      if stripped[0] == '#'
        line
      else
        parts = UnixUserManager::Utils::Line.split_colon(line)
        name, _id = parse_key_and_id(parts)
        next nil if @deleted_records.key?(name)
        if (edits = @edited_records[name])
          UnixUserManager::Utils::Line.join_colon(apply_edits(parts, edits))
        else
          line
        end
      end
    end.compact.join("\n")

    @new_records.any? ? (updated_source + "\n" + build_new_records) : updated_source
  end

  def build_new_records
    @new_records.map { |name, attrs| build_new_record_line(name, attrs) }.join("\n")
  end

  private

  def parse_index
    @data = source.split("\n")
                 .reject { |line| line.strip[0] == '#' }
                 .map do |line|
                   fields = UnixUserManager::Utils::Line.split_colon(line)
                   parse_key_and_id(fields)
                 end.to_h
  end
end
