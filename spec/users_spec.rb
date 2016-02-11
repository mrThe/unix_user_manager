require 'spec_helper'

describe UnixUserManager::Users do
  let(:passwd) { double(:passwd) }
  let(:shadow) { double(:shadow) }

  it_behaves_like "a manager" do
    let(:manager_object) { described_class.new(passwd: passwd, shadow: shadow) }
  end

  describe ".initialize" do
    it "initializes correctly" do
      obj = described_class.new(passwd: passwd, shadow: shadow)
      expect(obj.file).to eql passwd
      expect(obj.shadow_file).to eql shadow
    end
  end

  describe "methods" do
    let(:manager_object) { described_class.new(passwd: passwd, shadow: shadow) }

    describe "#build" do
      let(:build_passwd) { "build passwd" }
      let(:build_shadow) { "build shadow" }

      it "calls file" do
        expect(manager_object.file).to receive(:build).and_return(build_passwd)
        expect(manager_object.shadow_file).to receive(:build).and_return(build_shadow)

        expect(manager_object.build).to eql ({ passwd: build_passwd, shadow: build_shadow })
      end
    end

    describe "#build_new_records" do
      let(:build_passwd) { "build passwd" }
      let(:build_shadow) { "build shadow" }

      it "calls file" do
        expect(manager_object.file).to receive(:build_new_records).and_return(build_passwd)
        expect(manager_object.shadow_file).to receive(:build_new_records).and_return(build_shadow)

        expect(manager_object.build_new_records).to eql ({ passwd: build_passwd, shadow: build_shadow })
      end
    end

    describe "#build_passwd" do
      it "calls file" do
        expect(manager_object.file).to receive(:build)
        manager_object.build_passwd
      end
    end

    describe "#build_shadow" do
      it "calls file" do
        expect(manager_object.shadow_file).to receive(:build)
        manager_object.build_shadow
      end
    end

    describe "#build_passwd_new_records" do
      it "calls file" do
        expect(manager_object.file).to receive(:build_new_records)
        manager_object.build_passwd_new_records
      end
    end

    describe "#build_shadow_new_records" do
      it "calls file" do
        expect(manager_object.shadow_file).to receive(:build_new_records)
        manager_object.build_shadow_new_records
      end
    end
  end
end
