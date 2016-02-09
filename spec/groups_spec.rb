require 'spec_helper'

describe UnixUserManager::Groups do
  let(:group) { double(:group) }

  it_behaves_like "a manager" do
    let(:manager_object) { described_class.new(group: group) }
  end

  describe ".initialize" do
    it "initializes correctly" do
      obj = described_class.new(group: group)
      expect(obj.file).to eql group
    end
  end

  describe "methods" do
    let(:manager_object) { described_class.new(group: group) }

    describe "#build" do
      it "calls file" do
        expect(manager_object.file).to receive(:build)
        manager_object.build
      end
    end
  end
end
