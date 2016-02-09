RSpec.shared_examples "a etc file" do
  describe ".initialize" do
    it "initializes correctly" do
      obj = described_class.new(etc_group_content)
      expect(obj.source).to eql etc_group_content
    end
  end

  describe "methods" do
    let!(:file) { described_class.new(target_file_content) }


    describe "#ids" do
      subject { file.ids }

      it { should eql available_ids }
    end

    describe "#find(name)" do
      context "existed" do
        subject { file.find(existed_name) }

        it { should eql existed_id }
      end

      context "new" do
        subject { file.find('Wally') }

        it { should eql nil }
      end
    end

    describe "#find_by_id(id)" do
      context "existed" do
        subject { file.find_by_id(existed_id) }

        it { should eql existed_name }
      end

      context "new" do
        subject { file.find_by_id(42) }

        it { should eql nil }
      end
    end

    describe "#id_exist?(id)" do
      context "existed" do
        subject { file.id_exist?(existed_id) }

        it { should be_truthy }
      end

      context "unexisted" do
        subject { file.id_exist?(42) }

        it { should be_falsey }
      end
    end

    describe "#exist?(name)" do
      context "existed" do
        subject { file.exist?(existed_name) }

        it { should be_truthy }
      end

      context "unexisted" do
        subject { file.exist?('Wally') }

        it { should be_falsey }
      end
    end
  end
end
