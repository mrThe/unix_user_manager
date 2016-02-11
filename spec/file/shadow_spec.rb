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
  end
end
