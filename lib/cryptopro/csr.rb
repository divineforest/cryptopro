module Cryptopro
  class Csr
    TEST_CA_UPLOAD_PAGE_URL = "http://www.cryptopro.ru/certsrv/certfnsh.asp"
    TEST_CA_DOWNLOAD_PAGE_URL = "http://www.cryptopro.ru/certsrv/certnew.cer?ReqID=%{ca_request_id}&Enc=b64"

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
  end
end
