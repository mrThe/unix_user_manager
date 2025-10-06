require 'spec_helper'

describe UnixUserManager::ShadowGroups do
  let(:gfile) { double(:gshadow) }

  it_behaves_like "a manager" do
    let(:manager_object) { described_class.new(gshadow: gfile) }
  end

  describe ".initialize" do
    it "initializes correctly" do
      obj = described_class.new(gshadow: gfile)
      expect(obj.file).to eql gfile
    end
  end

  describe "methods" do
    let(:manager_object) { described_class.new(gshadow: gfile) }

    describe "#build" do
      it "calls file" do
        expect(manager_object.file).to receive(:build)
        manager_object.build
      end
    end

    describe "#build_new_records" do
      it "calls file" do
        expect(manager_object.file).to receive(:build_new_records)
        manager_object.build_new_records
      end
    end
  end
end


