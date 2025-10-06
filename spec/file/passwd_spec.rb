require 'spec_helper'
require 'unix_crypt'

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

      context "with passwords" do
        it "accepts encrypted password" do
          file.add(name: 'new_user', uid: 420, gid: 420, encrypted_password: '$6$saltsalt$abcdef')
          expect(file.build_new_records).to include 'new_user:$6$saltsalt$abcdef:420:420::/dev/null:/bin/bash'
        end

        it "hashes raw password" do
          file.add(name: 'new_user2', uid: 421, gid: 421, password: 'secret', salt: 'saltsalt', algorithm: :sha256)
          line = file.build_new_records.split("\n").find { |l| l.start_with?('new_user2:') }
          password_field = line.split(':')[1]
          expect(password_field).to match(/^\$5\$saltsalt\$/)
        end

        context "exact hashes" do
          it "produces exact sha512 hash on add" do
            file.add(name: 'user_sha512', uid: 5001, gid: 5001, password: 'secret', salt: 'saltsalt', algorithm: :sha512)
            line = file.build_new_records.split("\n").find { |l| l.start_with?('user_sha512:') }
            password_field = line.split(':')[1]
            expected = UnixCrypt::SHA512.build('secret', 'saltsalt')
            expect(password_field).to eql expected
          end

          it "produces exact sha256 hash on add" do
            file.add(name: 'user_sha256', uid: 5002, gid: 5002, password: 'secret', salt: 'saltsalt', algorithm: :sha256)
            line = file.build_new_records.split("\n").find { |l| l.start_with?('user_sha256:') }
            password_field = line.split(':')[1]
            expected = UnixCrypt::SHA256.build('secret', 'saltsalt')
            expect(password_field).to eql expected
          end

          it "produces exact md5 hash on add" do
            file.add(name: 'user_md5', uid: 5003, gid: 5003, password: 'secret', salt: 'saltsalt', algorithm: :md5)
            line = file.build_new_records.split("\n").find { |l| l.start_with?('user_md5:') }
            password_field = line.split(':')[1]
            expected = UnixCrypt::MD5.build('secret', 'saltsalt')
            expect(password_field).to eql expected
          end
        end
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

      context "when setting encrypted password" do
        it "uses the provided hash as is" do
          expect(file.edit(name: existed_name, encrypted_password: '$6$saltsalt$abcdef')).to be_truthy
          line = file.build.split("\n").find { |l| l.start_with?("#{existed_name}:") }
          expect(line.split(':')[1]).to eql '$6$saltsalt$abcdef'
        end
      end

      context "when setting raw password" do
        it "hashes with sha512 by default" do
          expect(file.edit(name: existed_name, password: 'secret', salt: 'saltsalt')).to be_truthy
          line = file.build.split("\n").find { |l| l.start_with?("#{existed_name}:") }
          expect(line.split(':')[1]).to match(/^\$6\$saltsalt\$/)
        end

        it "supports sha256" do
          expect(file.edit(name: existed_name, password: 'secret', salt: 'saltsalt', algorithm: :sha256)).to be_truthy
          line = file.build.split("\n").find { |l| l.start_with?("#{existed_name}:") }
          expect(line.split(':')[1]).to match(/^\$5\$saltsalt\$/)
        end

        it "supports md5" do
          expect(file.edit(name: existed_name, password: 'secret', salt: 'saltsalt', algorithm: :md5)).to be_truthy
          line = file.build.split("\n").find { |l| l.start_with?("#{existed_name}:") }
          expect(line.split(':')[1]).to match(/^\$1\$saltsalt\$/)
        end
      end

      context "exact hashes" do
        it "produces exact sha512 hash on edit" do
          expect(file.edit(name: existed_name, password: 'secret', salt: 'saltsalt', algorithm: :sha512)).to be_truthy
          line = file.build.split("\n").find { |l| l.start_with?("#{existed_name}:") }
          password_field = line.split(':')[1]
          expected = UnixCrypt::SHA512.build('secret', 'saltsalt')
          expect(password_field).to eql expected
        end

        it "produces exact sha256 hash on edit" do
          expect(file.edit(name: existed_name, password: 'secret', salt: 'saltsalt', algorithm: :sha256)).to be_truthy
          line = file.build.split("\n").find { |l| l.start_with?("#{existed_name}:") }
          password_field = line.split(':')[1]
          expected = UnixCrypt::SHA256.build('secret', 'saltsalt')
          expect(password_field).to eql expected
        end

        it "produces exact md5 hash on edit" do
          expect(file.edit(name: existed_name, password: 'secret', salt: 'saltsalt', algorithm: :md5)).to be_truthy
          line = file.build.split("\n").find { |l| l.start_with?("#{existed_name}:") }
          password_field = line.split(':')[1]
          expected = UnixCrypt::MD5.build('secret', 'saltsalt')
          expect(password_field).to eql expected
        end
      end
    end

    describe "#delete(name:)" do
      context "when user does not exist" do
        subject { file.delete(name: 'unknown') }

        it { should be_falsey }
      end

      context "when user exists" do
        it "returns true and removes the line from build output" do
          expect(file.delete(name: existed_name)).to be_truthy

          built_lines = file.build.split("\n")
          expect(built_lines.any? { |l| l.start_with?("#{existed_name}:") }).to be_falsey

          original = etc_passwd_content.split("\n")
          original.each do |line|
            next if line.start_with?("#{existed_name}:")
            expect(built_lines).to include(line)
          end
        end
      end

      context "when deleting a staged new record" do
        let(:name) { 'risky_man' }
        let(:uid)  { 42 }
        let(:gid)  { 42 }

        it "removes the staged addition and keeps original content unchanged" do
          expect(file.add(name: name, gid: gid, uid: uid)).to be_truthy
          expect(file.delete(name: name)).to be_truthy
          expect(file.build).to eql etc_passwd_content
        end
      end
    end
  end
end
