class UnixUserManager
  module Utils
    module Line
      def self.split_colon(line)
        line.split(':', -1)
      end

      def self.join_colon(parts)
        parts.join(':')
      end
    end
  end
end
