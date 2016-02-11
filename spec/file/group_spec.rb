require 'spec_helper'

describe UnixUserManager::File::Group do
  it_behaves_like "a etc file" do
    let(:target_file_content) { etc_group_content }
    let(:existed_name) { 'games' }
    let(:existed_id) { 60 }
    let(:available_ids) { [0, 1, 2, 3, 8, 60, 104, 65534] }
  end

  describe "methods" do
    let(:file) { described_class.new(etc_group_content) }
    let(:existed_name) { 'games' }
    let(:existed_id) { 60 }

    describe "#build_new_records" do
      let(:name)  { 'risky_man' }
      let(:uname) { 'risky_man' }
      let(:gid)   { 42 }

      context "without new records" do
        it "returns empty string" do
          expect(file.build_new_records).to be_empty
        end
      end

      context "with new records" do
        before do
          file.add(name: name, gid: gid, uname: uname)
        end

        it "correctly builds new records" do
          expect(file.build_new_records).to eql "#{name}:x:#{gid}:#{uname}"
        end
      end
    end

    describe "#build" do
      let(:name)  { 'risky_man' }
      let(:uname) { 'risky_man' }
      let(:gid)   { 42 }

      context "without new records" do
        it "correctly builds new records" do
          expect(file.build).to eql etc_group_content
        end
      end

      context "with new records" do
        before do
          file.add(name: name, gid: gid, uname: uname)
        end

        it "correctly builds new records" do
          expect(file.build).to eql (etc_group_content + "\n#{name}:x:#{gid}:#{uname}")
        end
      end
    end

    describe "#add(name:, uname:, gid:)" do
      context "existed name" do
        subject { file.add(name: existed_name, gid: 42, uname: 'Wally') }

        it { should be_falsey }
      end

      context "existed id" do
        subject { file.add(name: 'Wally', gid: existed_id, uname: 'Wally') }

        it { should be_falsey }
      end

      context "new" do
        subject { file.add(name: 'Wally', gid: 42, uname: 'Wally') }

        it { should be_truthy }
      end
    end
  end
end
