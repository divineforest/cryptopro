require 'tmpdir'
require 'digest/md5'
require 'cocaine'

module Cryptopro
  class Signature
    MESSAGE_FILE_NAME = "message.txt"
    # Должен называться как файл с сообщением, только расширение .sgn
    SIGNATURE_FILE_NAME = "message.txt.sgn"
    CERTIFICATE_FILE_NAME = "certificate.cer"

    CERTIFICATE_LINE_LENGTH = 64

    # Options: message, signature, certificate
    def self.verify(options)
      raise "Message required" if options[:message].blank?
      raise "Signature required" if options[:signature].blank?
      raise "Certificate required" if options[:certificate].blank?

      tmp_dir = create_temp_dir
      create_temp_files(tmp_dir, options)
      valid = execute(tmp_dir)
    end

    private

      # Для работы с cryptcp требуется, чтобы сообщение, полпись и сертификат были в виде файлов
      # Создаётся временная уникальная папка для каждой проверки
      def self.create_temp_dir
        uniq_name = Digest::MD5.hexdigest("#{rand(1_000_000)}#{Time.now}")
        full_name = "#{Dir.tmpdir}/cryptcp/#{uniq_name}"
        FileUtils.mkdir_p(full_name)
      end

      def self.create_temp_files(tmp_dir, options)
        # Создать файл сообщения
        create_temp_file(tmp_dir, MESSAGE_FILE_NAME, options[:message])
        # Создать файл подписи
        create_temp_file(tmp_dir, SIGNATURE_FILE_NAME, options[:signature])
        # Создать файл сертификата
        certificate_with_container = add_container_to_certificate(options[:certificate])
        create_temp_file(tmp_dir, CERTIFICATE_FILE_NAME, certificate_with_container)
      end

      def self.create_temp_file(dir_name, file_name, content)
        File.open("#{dir_name}/#{file_name}", "w") { |file| file.write(content) }
      end

      # Обсуждение формата использования: http://www.cryptopro.ru/forum2/Default.aspx?g=posts&t=1516
      # Пример вызова утилиты cryptcp:
      # cryptcp -vsignf -dir /home/user/signs -f certificate.cer message.txt
      # /home/user/signs -- папка с подписью, имя которой соответствуют имени сообщения, но с расширением .sgn
      def self.execute(dir)
        cmd = "cryptcp -vsignf -dir #{dir} -f #{dir}/#{CERTIFICATE_FILE_NAME} -nochain #{dir}/#{MESSAGE_FILE_NAME}"
        line = Cocaine::CommandLine.new("cryptcp", "-vsignf -dir :signatures_dir -f :certificate -nochain :message",
          :signatures_dir => dir,
          :certificate => "#{dir}/#{CERTIFICATE_FILE_NAME}",
          :message => "#{dir}/#{MESSAGE_FILE_NAME}"
        )
        begin
          line.run
          true
        rescue Cocaine::ExitStatusError
          false
        rescue Cocaine::CommandNotFoundError => e
          raise "Command cryptcp was not found"
        end
      end

      # Добавляет -----BEGIN CERTIFICATE----- / -----END CERTIFICATE-----, если их нет.
      # Так же делит длинную строку Base64 на строки по 64 символа.
      # Это требование cryptcp к файл с сертификатом.
      def self.add_container_to_certificate(certificate)
        return certificate if certificate.downcase.include?("begin")

        parts = certificate.scan(/.{1,#{CERTIFICATE_LINE_LENGTH}}/)
        certificate_with_container = "-----BEGIN CERTIFICATE-----\n#{parts.join("\n")}\n-----END CERTIFICATE-----"
      end

  end

end
