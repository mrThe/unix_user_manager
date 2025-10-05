require 'spec_helper'

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
        subject { file.edit(name: 'unknown', password: 'secret') }

        it { should be_falsey }
      end

      context "when setting encrypted password" do
        let(:hash) { '$6$saltsalt$abcdef' }

        it "replaces password field with given hash" do
          expect(file.edit(name: 'games', encrypted_password: hash)).to be_truthy
          line = file.build.split("\n").find { |l| l.start_with?('games:') }
          expect(line.split(':')[1]).to eql hash
        end
      end

      context "when setting raw password" do
        it "hashes with sha512 by default" do
          expect(file.edit(name: 'games', password: 'secret', salt: 'saltsalt')).to be_truthy
          line = file.build.split("\n").find { |l| l.start_with?('games:') }
          expect(line.split(':')[1]).to match(/^\$6\$/)
        end

        it "supports sha256" do
          expect(file.edit(name: 'games', password: 'secret', salt: 'saltsalt', algorithm: :sha256)).to be_truthy
          line = file.build.split("\n").find { |l| l.start_with?('games:') }
          expect(line.split(':')[1]).to match(/^\$5\$/)
        end

        it "supports md5" do
          expect(file.edit(name: 'games', password: 'secret', salt: 'saltsalt', algorithm: :md5)).to be_truthy
          line = file.build.split("\n").find { |l| l.start_with?('games:') }
          expect(line.split(':')[1]).to match(/^\$1\$/)
        end
      end

      context "when editing without any password" do
        it "sets placeholder '!!'" do
          expect(file.edit(name: 'games')).to be_truthy
          line = file.build.split("\n").find { |l| l.start_with?('games:') }
          expect(line.split(':')[1]).to eql '!!'
        end
      end
    end

    describe "#add(name:, password:, encrypted_password:)" do
      it "accepts encrypted password" do
        file.add(name: 'new_user', encrypted_password: '$6$saltsalt$abcdef')
        expect(file.build_new_records).to include 'new_user:$6$saltsalt$abcdef:'
      end

      it "hashes raw password" do
        file.add(name: 'new_user2', password: 'secret', salt: 'saltsalt', algorithm: :sha256)
        expect(file.build_new_records).to match(/new_user2:\$5\$saltsalt\$/)
      end

      it "uses '!!' when no password provided" do
        file.add(name: 'new_user3')
        expect(file.build_new_records).to include 'new_user3:!!:'
      end
    end
  end
end
