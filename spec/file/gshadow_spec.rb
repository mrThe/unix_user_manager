require 'spec_helper'

describe UnixUserManager::File::GShadow do
  describe ".initialize" do
    it "initializes correctly" do
      obj = described_class.new(etc_gshadow_content)
      expect(obj.source).to eql etc_gshadow_content
    end
  end

  describe "methods" do
    let(:file) { described_class.new(etc_gshadow_content) }

    describe "#build_new_records" do
      context "without new records" do
        it "returns empty string" do
          expect(file.build_new_records).to be_empty
        end
      end

      context "with new records" do
        before do
          file.add(name: 'adm', password: '!', admins: 'root', members: 'syslog')
        end

        it "correctly builds new records" do
          expect(file.build_new_records).to eql "adm:!:root:syslog"
        end
      end
    end

    describe "#build" do
      context "without new records" do
        it "returns the same content" do
          expect(file.build).to eql etc_gshadow_content
        end
      end

      context "with new records" do
        before do
          file.add(name: 'adm', password: '!', admins: 'root', members: 'syslog')
        end

        it "appends new record" do
          expect(file.build).to eql (etc_gshadow_content + "\nadm:!:root:syslog")
        end
      end
    end

    describe "#exist?(name)" do
      it "detects existing group" do
        expect(file.exist?('syslog')).to be_truthy
      end

      it "detects non-existing group" do
        expect(file.exist?('unknown')).to be_falsey
      end
    end

    describe "#add(name:, ...)" do
      it "prevents duplicate" do
        expect(file.add(name: 'syslog')).to be_falsey
      end

      it "allows new" do
        expect(file.add(name: 'adm', password: '!', admins: 'root', members: 'syslog')).to be_truthy
      end
    end

    describe "#edit(name:, ...)" do
      it "fails for unknown" do
        expect(file.edit(name: 'unknown')).to be_falsey
      end

      it "updates fields" do
        expect(file.edit(name: 'syslog', admins: 'root', members: 'syslog,daemon')).to be_truthy
        line = file.build.split("\n").find { |l| l.start_with?('syslog:') }
        expect(line).to eql 'syslog:*:root:syslog,daemon'
      end
    end

    describe "#delete(name:)" do
      it "fails for unknown" do
        expect(file.delete(name: 'unknown')).to be_falsey
      end

      it "removes existing" do
        expect(file.delete(name: 'syslog')).to be_truthy
        built_lines = file.build.split("\n")
        expect(built_lines.any? { |l| l.start_with?('syslog:') }).to be_falsey
      end

      it "removes staged new record" do
        file.add(name: 'adm', password: '!', admins: 'root', members: 'syslog')
        expect(file.delete(name: 'adm')).to be_truthy
        expect(file.build).to eql etc_gshadow_content
      end
    end
  end
end


