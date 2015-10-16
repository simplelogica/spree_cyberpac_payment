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
        super
        @success ||= response_success?
        @response_message = response_message_from params
      end

      def valid_signature?(secret)
        signature = [params["Ds_Amount"], params["Ds_Order"],
          params["Ds_MerchantCode"], params["Ds_Currency"],
          params["Ds_Response"], secret].join('')
        Digest::SHA1.hexdigest(signature).upcase == params["Ds_Signature"]
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
