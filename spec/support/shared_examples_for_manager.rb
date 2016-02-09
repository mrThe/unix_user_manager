RSpec.shared_examples "a manager" do
  describe "methods" do
    let!(:name) { double :name }
    let!(:id) { double :id }

    describe "#ids" do
      it "calls file" do
        expect(manager_object.file).to receive(:ids)
        manager_object.ids
      end
    end

    describe "#find(name)" do
      it "calls file" do
        expect(manager_object.file).to receive(:find).with name
        manager_object.find(name)
      end
    end

    describe "#find_by_id(id)" do
      it "calls file" do
        expect(manager_object.file).to receive(:find_by_id).with id
        manager_object.find_by_id(id)
      end
    end

    describe "#exist?(name)" do
      it "calls file" do
        expect(manager_object.file).to receive(:exist?).with name
        manager_object.exist?(name)
      end
    end

    describe "#all" do
      it "calls file" do
        expect(manager_object.file).to receive(:all)
        manager_object.all
      end
    end
  end
end
