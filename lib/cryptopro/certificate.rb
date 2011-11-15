module Cryptopro
  class Certificate < Cryptopro::Base

    def self.info(certificate_body)
      certificate_file_path = create_temp_certificate_file(certificate_body)
      cryptopro_answer = get_info(certificate_file_path)
      convert_from_raw_to_hashes(cryptopro_answer)
    end

    private

      def self.get_info(certificate_file_path)
        Cocaine::CommandLine.path = ["/opt/cprocsp/bin/amd64", "/opt/cprocsp/bin/ia32"]
        line = Cocaine::CommandLine.new("certmgr", "-list -f :certificate",
          :certificate => certificate_file_path
        )
        begin
          line.run
        rescue Cocaine::ExitStatusError
          false
        rescue Cocaine::CommandNotFoundError => e
          raise "Command certmgr was not found"
        end
      end

      def self.raw_certificates(cryptopro_answer)
        cleaned_answer = clean_answer(cryptopro_answer)
        cleaned_answer.split("=============================================================================")
      end

      def self.clean_answer(cryptopro_answer)
        cleaned = []
        cleaned = cryptopro_answer.split("\n")[4..-4]
        cleaned.join("\n")
      end

      def self.certificate_extract_info(raw_certificate)
        info = {}
        raw_certificate.split("\n").each do |certificate_line|
          if certificate_line.include?(":")
            name, value = certificate_line.split(":").map(&:strip)
            name.gsub!(/\s/, "_")
            name.downcase!
            info[name.to_sym] = value
          end
        end
        info
      end

      def self.convert_from_raw_to_hashes(cryptopro_answer)
        container_certificates = []

        raw_certificates(cryptopro_answer).each do |raw_certificate|
          container_certificates << certificate_extract_info(raw_certificate)
        end

        container_certificates        
      end

  end
end
