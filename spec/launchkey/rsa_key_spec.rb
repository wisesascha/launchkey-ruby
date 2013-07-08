# encoding: utf-8

require 'spec_helper'

describe LaunchKey::RSAKey do

  let(:key) do
    described_class.generate(2048)
  end

  let(:unwrapped_key) do
    key.key
  end

  let(:data) do
    SecureRandom.random_bytes
  end

  let(:crypted_data) do
    SecureRandom.random_bytes
  end

  describe '::SHA256' do

    it 'is a reference to OpenSSL::Digest::SHA256' do
      expect(LaunchKey::RSAKey::SHA256).to eq(OpenSSL::Digest::SHA256)
    end
  end

  describe '::MD5' do

    it 'is a reference to OpenSSL::Digest::MD5' do
      expect(LaunchKey::RSAKey::MD5).to eq(OpenSSL::Digest::MD5)
    end
  end

  describe '::RSA' do

    it 'is a reference to OpenSSL::PKey::RSA' do
      expect(LaunchKey::RSAKey::RSA).to eq(OpenSSL::PKey::RSA)
    end
  end

  describe '::PKCS1_OAEP_PADDING' do

    it 'is a reference to OpenSSL::PKey::RSA::PKCS1_OAEP_PADDING' do
      expect(LaunchKey::RSAKey::PKCS1_OAEP_PADDING).to eq(OpenSSL::PKey::RSA::PKCS1_OAEP_PADDING)
    end
  end

  describe '::PUBKEY_PATTERN' do

    subject(:pubkey_pattern) do
      LaunchKey::RSAKey::PUBKEY_PATTERN
    end

    it 'is a regular expression' do
      expect(pubkey_pattern).to be_a(Regexp)
    end

    it 'matches public key header' do
      expect('-----BEGIN PUBLIC KEY-----bar'.gsub(pubkey_pattern, 'foo')).to eq('foobar')
    end

    it 'matches public key footer' do
      expect('foo-----END PUBLIC KEY-----'.gsub(pubkey_pattern, 'bar')).to eq('foobar')
    end

    it 'matches newlines' do
      expect("\n\n\n\n".gsub(pubkey_pattern, '')).to be_empty
    end
  end

  describe '.generate' do

    let(:key_double) do
      double(OpenSSL::PKey::RSA)
    end

    it 'returns RSAKey' do
      expect(described_class.generate).to be_a(LaunchKey::RSAKey)
    end

    it 'generates OpenSSL::PKey::RSA with supplied bits' do
      OpenSSL::PKey::RSA.should_receive(:new).with(4096).and_return(key_double)
      key_double.should_receive(:is_a?).with(OpenSSL::PKey::RSA).and_return(true)
      described_class.generate(4096)
    end

    it 'initializes RSAKey with generated RSA key' do
      OpenSSL::PKey::RSA.should_receive(:new).with(1024).and_return(key_double)
      described_class.should_receive(:new).with(key_double)
      described_class.generate(1024)
    end
  end

  describe '.unwrap_public_key' do

    let(:key) do
      <<-KEY.strip_heredoc
        -----BEGIN PUBLIC KEY-----
        #{Base64.encode64('blah blah blah')}
        -----END PUBLIC KEY-----
      KEY
    end

    it 'returns unwrapped public key' do
      expect(described_class.send(:unwrap_public_key, key)).to eq('blah blah blah')
    end
  end

  describe '#initialize' do

    context 'when supplied key is invalid' do

      it 'raises Errors::InvalidKeypair' do
        expect {
          described_class.new('ಠ_ಠ')
        }.to raise_error(LaunchKey::Errors::InvalidKeypair)
      end
    end

    context 'when supplied passphrase is incorrect' do

      it 'raises Errors::PrivateKeyMissing' do
        key = described_class.generate.to_pem('top secret')
        expect {
          described_class.new(key, passphrase: 'secret top')
        }.to raise_error(LaunchKey::Errors::PrivateKeyMissing)
      end
    end

    context 'when supplied public key' do

      let(:key_double) do
        double(OpenSSL::PKey::RSA)
      end

      it 'initializes with unwrapped key' do
        described_class.should_receive(:unwrap_public_key).with('foo').and_return('bar')
        OpenSSL::PKey::RSA.should_receive(:new).with('bar').and_return(key_double)
        expect(described_class.new('foo', public_only: true).key).to eq(key_double)
      end
    end
  end

  describe '#public_key' do

    let(:key) do
      described_class.generate(1024)
    end

    subject(:pubkey) do
      key.public_key
    end

    it 'returns RSA instance' do
      expect(pubkey).to be_a(LaunchKey::RSAKey)
    end

    it 'is a new instance' do
      expect(pubkey.object_id).not_to eq(key.object_id)
    end

    it 'matches the original key' do
      expect(pubkey).to eq(key)
    end

    it 'does not include private key' do
      expect(pubkey).to_not be_private
    end
  end

  describe '#private_decrypt' do

    context 'when padding supplied' do

      let(:padding) do
        rand(100)
      end

      it 'delegates to key.private_decrypt with supplied data and padding' do
        unwrapped_key.should_receive(:private_decrypt).with(crypted_data, padding).and_return(data)
        expect(key.private_decrypt(crypted_data, padding)).to eq(data)
      end
    end

    context 'when padding not supplied' do

      it 'delegates to key.private_decrypt with supplied data and OAEP padding' do
        unwrapped_key.should_receive(:private_decrypt).with(
          crypted_data, LaunchKey::RSAKey::PKCS1_OAEP_PADDING
        ).and_return(data)
        expect(key.private_decrypt(crypted_data)).to eq(data)
      end
    end
  end

  describe '#public_encrypt' do

    context 'when padding supplied' do

      let(:padding) do
        rand(100)
      end

      it 'delegates to key.public_encrypt with supplied data and padding' do
        unwrapped_key.should_receive(:public_encrypt).with(data, padding).and_return(crypted_data)
        expect(key.public_encrypt(data, padding)).to eq(crypted_data)
      end
    end

    context 'when padding not supplied' do

      it 'delegates to key.public_encrypt with supplied data and OAEP padding' do
        unwrapped_key.should_receive(:public_encrypt).with(
          data, LaunchKey::RSAKey::PKCS1_OAEP_PADDING
        ).and_return(crypted_data)
        expect(key.public_encrypt(data)).to eq(crypted_data)
      end
    end
  end

  describe '#sign' do
    pending
  end

  describe '#verify' do
    pending
  end

  describe '#==' do
    pending
  end

  describe '#fingerprint' do

    subject(:key) do
      described_class.new('MFwwDQYJKoZIhvcNAQEBBQADSwAwSAJBANZXKE1xFZdUg5KqTfrdSZa1HzQIixkl
                           sVFO1sduTNWgng0MclaqjPEBtSrxelCm0DhlWhe9aFzibqXay4Yu1Q0CAwEAAQ==', public_only: true)
    end

    let(:fingerprint) do
      'ae:5a:87:71:36:92:2c:f8:32:4c:c9:ae:03:e4:ce:f1'
    end

    it 'returns SSH-style fingerprint' do
      expect(key.fingerprint).to eq(fingerprint)
    end
  end

  describe '#inspect' do

    it 'returns string containing fingerprint' do
      expect(key.inspect).to eq("#<LaunchKey::RSAKey #{key.fingerprint}>")
    end
  end

  [:to_pem, :to_s, :export].each do |method_name|

    describe "##{method_name}" do
      pending
    end
  end
end
