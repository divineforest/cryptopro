require 'tmpdir'
require 'digest/md5'
require 'cocaine'

module Cryptopro
  class Base
    CERTIFICATE_FILE_NAME = "certificate.cer"
    CERTIFICATE_LINE_LENGTH = 64

    def self.create_temp_dir
      uniq_name = Digest::MD5.hexdigest("#{rand(1_000_000)}#{Time.now}")
      full_name = "#{Dir.tmpdir}/cryptcp/#{uniq_name}"
      FileUtils.mkdir_p(full_name)
    end

    def self.create_temp_file(dir_name, file_name, content)
      full_path = "#{dir_name}/#{file_name}"
      File.open(full_path, "w") { |file| file.write(content) }
      full_path
    end

    # Добавляет -----BEGIN CERTIFICATE----- / -----END CERTIFICATE-----, если их нет.
    # Так же делит длинную строку Base64 на строки по 64 символа.
    # Это требование cryptcp к файл с сертификатом.
    def self.add_container_to_certificate(certificate)
      return certificate if certificate.downcase.include?("begin")

      parts = certificate.scan(/.{1,#{CERTIFICATE_LINE_LENGTH}}/)
      certificate_with_container = "-----BEGIN CERTIFICATE-----\n#{parts.join("\n")}\n-----END CERTIFICATE-----"
    end

    def self.create_temp_certificate_file(content)
      tmp_dir = create_temp_dir
      certificate_with_container = add_container_to_certificate(content)
      create_temp_file(tmp_dir, CERTIFICATE_FILE_NAME, certificate_with_container)
    end

  end
end
