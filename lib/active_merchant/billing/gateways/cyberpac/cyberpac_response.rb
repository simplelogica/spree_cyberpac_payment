module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    class CyberpacResponse < Response
      attr_reader :response_message

      RESPONSE_CODES = {
        # success codes
        (0..99) => "Transacción autorizada para pagos y preautorizaciones",
        900 => "Transacción autorizada para devoluciones y confirmaciones",
        # refused codes
        101 => "Tarjeta caducada",
        102 => "Tarjeta en excepción transitoria o bajo sospecha de fraude",
        104 => "Operación no permitida para esa tarjeta o terminal",
        116 => "Disponible insuficiente",
        118 => "Tarjeta no registrada",
        129 => "Código de seguridad (CVV2/CVC2) incorrecto",
        180 => "Tarjeta ajena al servicio",
        184 => "Error en la autenticación del titular",
        190 => "Denegación sin especificar Motivo",
        191 => "Fecha de caducidad errónea",
        202 => "Tarjeta en excepción transitoria o bajo sospecha de fraude con retirada de tarjeta",
        [912,9912] => "Emisor no disponible"
        # other "Transacción denegada"
      }

      def self.response_code_succeed?(value)
        value.between?(0,99) || value.eql?(900)
      end

      def initialize(success, message, params = {}, options = {})
        params.merge! JSON.parse(Base64.strict_decode64(params["Ds_MerchantParameters"])) unless params["Ds_MerchantParameters"].blank?
        super
        @success ||= response_success?
        @response_message = response_message_from params
      end

      def valid_signature?(secret_key)
        return false if params['Ds_Signature'].blank?
        secret_key_base64 = Base64.strict_decode64(secret_key)

        des3 = OpenSSL::Cipher::Cipher.new('des-ede3-cbc')
        block_length = 8
        des3.padding = 0
        des3.encrypt
        des3.key = secret_key_base64
        order_number = params['Ds_Order']
        order_number += "\0" until order_number.bytesize % block_length == 0
        key_des3 = des3.update(order_number) + des3.final
        result = OpenSSL::HMAC.digest('sha256', key_des3, params['Ds_MerchantParameters'])
        sig = Base64.strict_encode64(result).gsub("+", "-").gsub("/", "_")
        sig == params['Ds_Signature']
      end

      def response_code
        params["Ds_Response"]
      end

      private

        def response_success?
          response_code.blank? ? false : self.class.response_code_succeed?(response_code.to_i)
        end

        def response_message_from(response)
          code = response[:ds_response].to_i
          key = RESPONSE_CODES.keys.find { |k| (k.respond_to?(:include?) && k.include?(code)) || k.eql?(code) }
          RESPONSE_CODES[key] || "Transacción denegada"
        end

    end
  end
end
