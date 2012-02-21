require 'cryptopro/base'
require 'cryptopro/csr'
require 'cryptopro/signature'
require 'cryptopro/certificate'

module Cryptopro

  module Config

    # API_KEY for cabinet.ekey.ru.
    # Used for generating certificates, based in CSR, given by user.
    mattr_accessor :api_key
  end
end
