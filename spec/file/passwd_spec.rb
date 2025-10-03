require 'spec_helper'

describe UnixUserManager::File::Passwd do
  it_behaves_like "a etc file" do
    let(:target_file_content) { etc_passwd_content }
    let(:existed_name) { 'games' }
    let(:existed_id) { 5 }
    let(:available_ids) { [0, 1, 2, 3, 4, 5, 8, 101, 65534] }
  end

  describe "methods" do
    let(:file) { described_class.new(etc_passwd_content) }
    let(:existed_name) { 'games' }
    let(:existed_id) { 5 }

    describe "#build" do
      let(:name) { 'risky_man' }
      let(:uid)  { 42 }
      let(:gid)  { 42 }

      context "without new records" do
        it "returns empty string" do
          expect(file.build_new_records).to be_empty
        end
      end

      context "with new records" do
        before do
          file.add(name: name, gid: gid, uid: uid)
        end

        it "correctly builds new records" do
          expect(file.build_new_records).to eql "#{name}:x:#{uid}:#{gid}::/dev/null:/bin/bash"
        end
      end
    end

    describe "#build" do
      let(:name) { 'risky_man' }
      let(:uid)  { 42 }
      let(:gid)  { 42 }

      context "without new records" do
        it "correctly builds new records" do
          expect(file.build).to eql etc_passwd_content
        end
      end

      context "with new records" do
        before do
          file.add(name: name, gid: gid, uid: uid)
        end

        it "correctly builds new records" do
          expect(file.build).to eql (etc_passwd_content + "\n#{name}:x:#{uid}:#{gid}::/dev/null:/bin/bash")
        end
      end
    end

    describe "#add(name:, uid:, gid:)" do
      context "existed name" do
        subject { file.add(name: existed_name, uid: 42, gid: 42) }

        it { should be_falsey }
      end

      context "existed id" do
        subject { file.add(name: 'Wally', uid: existed_id, gid: 42) }

        it { should be_falsey }
      end

      context "new" do
        subject { file.add(name: 'Wally', uid: 42, gid: 42) }

        it { should be_truthy }
      end
    end

    describe "#edit(name:, ...)" do
      context "when user does not exist" do
        subject { file.edit(name: 'hacker', uid: 42) }

        it { should be_falsey }
      end

      context "when changing uid to an existing one" do
        subject { file.edit(name: existed_name, uid: 0) }

        it { should be_falsey }
      end

      context "when valid changes" do
        it "updates uid, gid, home and shell in build output" do
          expect(
            file.edit(name: existed_name, uid: 420, gid: 420, home_directory: '/home/games', shell: '/bin/zsh')
          ).to be_truthy

          built_lines = file.build.split("\n")
          edited_line = built_lines.find { |l| l.start_with?("#{existed_name}:") }
          expect(edited_line).to eql "#{existed_name}:x:420:420:games:/home/games:/bin/zsh"
        end

        it "keeps other lines unchanged" do
          file.edit(name: existed_name, shell: '/bin/sh')
          original = etc_passwd_content.split("\n")
          updated  = file.build.split("\n")
          original.each do |line|
            next if line.start_with?("#{existed_name}:")
            expect(updated).to include(line)
          end
        end
      end
    end
  end
end
