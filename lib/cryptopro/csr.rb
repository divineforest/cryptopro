# Модуль Csr отвечает за отправление запроса на сертификат (CSR) и получение готового сертификата.
#
# Существует 2 варианта работы с модулем:
# 1. Тестовый выпуск - issue_test_certificate. Совмещает в себе отправку запроса
# и получение тестового сертификата.
# 2. Полноценный комплекс взаимодействия с ekey.ru:
#    - issue -- отправляет запрос на выпуск сертификата
#       на вход: csr в формате pem
#       ответ: ruby hash в формате {"created_request_id" => <number>} или {"error" => <message>}
#    - get_certificates -- забирает с Удостоверяющего центра (УЦ, CA) готовые сертификаты
#       на вход: id сертификатов в очереди на выпуск (request_ids)
#       ответ: json в формате [{"id" => <request_id>, "certificate" => <certificate_body>},
#              если серт. еще не выпущен - {"id" => <request_id>, "error" => "certificate is not ready yet"}]

require 'rest_client'
require 'json'

module Cryptopro
  class Csr
    TEST_CA_UPLOAD_PAGE_URL   = "http://www.cryptopro.ru/certsrv/certfnsh.asp"
    TEST_CA_DOWNLOAD_PAGE_URL = "http://www.cryptopro.ru/certsrv/certnew.cer?ReqID=%{ca_request_id}&Enc=b64"

    CA_UPLOAD_PAGE_URL   = "http://cabinet.ekey.ru/api/1.0/request/put"
    CA_DOWNLOAD_PAGE_URL = "http://cabinet.ekey.ru/api/1.0/certificates/get"

    def self.issue_test_certificate(csr)
      upload_uri = URI(TEST_CA_UPLOAD_PAGE_URL)
      upload_response = Net::HTTP.post_form(upload_uri,
        'Mode' => 'newreq',
        'CertRequest' => csr
      )

      ca_request_id = upload_response.body.match(/ReqID\=(\d+)/)[1]

      if ca_request_id
        download_url_string = TEST_CA_DOWNLOAD_PAGE_URL % {:ca_request_id => ca_request_id}
        download_uri = URI(download_url_string)
        Net::HTTP.get(download_uri)
      else
        raise "CSR not accepted"
      end
    end

    def self.issue(csr)
      upload_responce = RestClient.post(CA_UPLOAD_PAGE_URL,
                                        { :api_key => Cryptopro::Config.api_key,
                                          :pkcs10 => Cryptopro::Base.add_container_to_csr(csr) },
                                        :multipart => true)
      JSON(upload_responce)
    end

    def self.get_certificates(ca_request_ids)
      id_list = Array(ca_request_ids).join(', ')
      ca_responce = RestClient.post(CA_DOWNLOAD_PAGE_URL, { :api_key => Cryptopro::Config.api_key,
                                                            :id_list => id_list })
      JSON(ca_responce)
    end

  end
end
