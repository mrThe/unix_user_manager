module UnixUserManager::File
  class Base
    attr_reader :source, :data, :new_records

    def initialize(source)
      @source = source
      @new_records = Hash.new { |h, k| h[k] = { id: nil } }

      parse_file
    end

    def ids
      data.values.sort
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

    def build
      @new_records.any? ? (source + "\n" + build_new_records) : source
    end

    private

    def build_new_records
      raise NotImplementedError
    end

    def parse_file
      @data = source.split("\n")
                .reject { |line| line.strip[0] == '#' } # remove comments
                .map { |line| data = line.split(':'); [data[0], data[2].to_i] }.to_h # name => id
    end
  end
end
