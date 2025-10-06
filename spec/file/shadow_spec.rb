require 'spec_helper'
require 'unix_crypt'

describe UnixUserManager::File::Shadow do
  describe ".initialize" do
    it "initializes correctly" do
      obj = described_class.new(etc_shadow_content)
      expect(obj.source).to eql etc_shadow_content
    end
  end

  describe "methods" do
    let(:file) { described_class.new(etc_shadow_content) }

    describe "#build" do
      let(:name) { 'risky_man' }

      context "without new records" do
        it "returns empty string" do
          expect(file.build_new_records).to be_empty
        end
      end

      context "with new records" do
        before do
          file.add(name: name)
        end

        it "correctly builds new records" do
          expect(file.build_new_records).to eql "#{name}:!!:::::::"
        end
      end
    end

    describe "#build" do
      let(:name) { 'risky_man' }

      context "without new records" do
        it "correctly builds new records" do
          expect(file.build).to eql etc_shadow_content
        end
      end

      context "with new records" do
        before do
          file.add(name: name)
        end

        it "correctly builds new records" do
          expect(file.build).to eql (etc_shadow_content + "\n#{name}:!!:::::::")
        end
      end
    end

    context "unsupported" do
      [:ids, :find, :find_by_id].each do |method_name|
        describe "##{method_name}" do
          it "not supported" do
            expect { file.send method_name }.to raise_error(NotImplementedError)
          end
        end
      end

      describe "#:id_exist?" do
        it "always returns false" do
          100.times do |i|
            expect(file.id_exist?(i)).to be_falsey
          end
        end
      end
    end

    describe "#exist?(name)" do
      context "existed" do
        subject { file.exist?('games') }

        it { should be_truthy }
      end

      context "new" do
        subject { file.exist?('Wally') }

        it { should be_falsey }
      end
    end

    describe "#add(name, id)" do
      context "existed user" do
        subject { file.add(name: 'root') }

        it { should be_falsey }
      end

      context "new" do
        subject { file.add(name: 'Wally') }

        it { should be_truthy }
      end
    end

    describe "#edit(name:, password:, encrypted_password:)" do
      context "when user does not exist" do
        subject { file.edit(name: 'unknown') }

        it { should be_falsey }
      end

      context "when editing with default (no password provided)" do
        it "sets placeholder '!!' for the user in build output" do
          expect(file.edit(name: 'games')).to be_truthy

          line = file.build.split("\n").find { |l| l.start_with?('games:') }
          expect(line.split(':')[1]).to eql '!!'
        end
      end

      context "when setting encrypted password" do
        it "uses the provided hash as is" do
          expect(file.edit(name: 'games', encrypted_password: '$6$saltsalt$abcdef')).to be_truthy
          line = file.build.split("\n").find { |l| l.start_with?('games:') }
          expect(line.split(':')[1]).to eql '$6$saltsalt$abcdef'
        end
      end

      context "when setting raw password" do
        it "hashes with sha512 by default" do
          expect(file.edit(name: 'games', password: 'secret', salt: 'saltsalt')).to be_truthy
          line = file.build.split("\n").find { |l| l.start_with?('games:') }
          expect(line.split(':')[1]).to match(/^\$6\$saltsalt\$/)
        end

        it "supports sha256" do
          expect(file.edit(name: 'games', password: 'secret', salt: 'saltsalt', algorithm: :sha256)).to be_truthy
          line = file.build.split("\n").find { |l| l.start_with?('games:') }
          expect(line.split(':')[1]).to match(/^\$5\$saltsalt\$/)
        end

        it "supports md5" do
          expect(file.edit(name: 'games', password: 'secret', salt: 'saltsalt', algorithm: :md5)).to be_truthy
          line = file.build.split("\n").find { |l| l.start_with?('games:') }
          expect(line.split(':')[1]).to match(/^\$1\$saltsalt\$/)
        end
      end

      context "exact hashes" do
        it "produces exact sha512 hash" do
          expect(file.edit(name: 'games', password: 'secret', salt: 'saltsalt', algorithm: :sha512)).to be_truthy
          line = file.build.split("\n").find { |l| l.start_with?('games:') }
          password_field = line.split(':')[1]
          expected = UnixCrypt::SHA512.build('secret', 'saltsalt')
          expect(password_field).to eql expected
        end

        it "produces exact sha256 hash" do
          expect(file.edit(name: 'games', password: 'secret', salt: 'saltsalt', algorithm: :sha256)).to be_truthy
          line = file.build.split("\n").find { |l| l.start_with?('games:') }
          password_field = line.split(':')[1]
          expected = UnixCrypt::SHA256.build('secret', 'saltsalt')
          expect(password_field).to eql expected
        end

        it "produces exact md5 hash" do
          expect(file.edit(name: 'games', password: 'secret', salt: 'saltsalt', algorithm: :md5)).to be_truthy
          line = file.build.split("\n").find { |l| l.start_with?('games:') }
          password_field = line.split(':')[1]
          expected = UnixCrypt::MD5.build('secret', 'saltsalt')
          expect(password_field).to eql expected
        end
      end

      it "keeps other lines unchanged" do
        file.edit(name: 'games', password: 'LOCKED')
        original = etc_shadow_content.split("\n")
        updated  = file.build.split("\n")

        original.each do |l|
          next if l.start_with?('games:')
          expect(updated).to include(l)
        end
      end
    end

    describe "#delete(name:)" do
      context "when user does not exist" do
        subject { file.delete(name: 'unknown') }

        it { should be_falsey }
      end

      context "when user exists" do
        it "returns true and removes the line from build output" do
          expect(file.delete(name: 'games')).to be_truthy

          built_lines = file.build.split("\n")
          expect(built_lines.any? { |l| l.start_with?("games:") }).to be_falsey

          original = etc_shadow_content.split("\n")
          original.each do |line|
            next if line.start_with?("games:")
            expect(built_lines).to include(line)
          end
        end
      end

      context "when deleting a staged new record" do
        let(:name) { 'risky_man' }

        it "removes the staged addition and keeps original content unchanged" do
          expect(file.add(name: name)).to be_truthy
          expect(file.delete(name: name)).to be_truthy
          expect(file.build).to eql etc_shadow_content
        end
      end
    end
  end
end
