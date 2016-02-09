require 'spec_helper'

describe UnixUserManager do
  describe ".initialize" do
    let(:passwd) { double(:passwd) }
    let(:shadow) { double(:shadow) }
    let(:group)  { double(:group) }

    it "initializes correctly" do
      expect(UnixUserManager::File::Passwd).to receive(:new).with(etc_passwd_content).and_return(passwd)
      expect(UnixUserManager::File::Shadow).to receive(:new).with(etc_shadow_content).and_return(shadow)
      expect(UnixUserManager::File::Group).to  receive(:new).with(etc_group_content ).and_return(group)

      expect(UnixUserManager::Users).to  receive(:new).with(passwd: passwd, shadow: shadow)
      expect(UnixUserManager::Groups).to receive(:new).with(group:  group)

      UnixUserManager.new(passwd: etc_passwd_content, shadow: etc_shadow_content, group: etc_group_content)
    end
  end

  describe "#available_id" do
    let(:uum) { UnixUserManager.new(passwd: etc_passwd_content, shadow: etc_shadow_content, group: etc_group_content) }

    it "returns correct ids" do
      expect(uum.available_id).to eq 200
      expect(uum.available_id(preffered_ids: [])).to eq 100
      expect(uum.available_id(min_id: 1, preffered_ids: [])).to eq 6
    end

    context "recursive" do
      it "returns correct ids" do
        expect(uum.available_id(max_id: 1, recursive: true)).to eq 100
        expect(uum.available_id(preffered_ids: [], max_id: 1, recursive: true)).to eq 100
        expect(uum.available_id(min_id: 1, max_id: 1, preffered_ids: [], recursive: true)).to eq 6
      end
    end
  end
end
