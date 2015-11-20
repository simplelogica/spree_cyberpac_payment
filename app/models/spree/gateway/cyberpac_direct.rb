module Spree
  class Gateway::CyberpacDirect < Gateway
    preference :merchant_name, :string
    preference :merchant_code, :string
    preference :secret_key, :string, default: 'qwertyasdf0123456789'
    preference :terminal, :string, default: '1'

    def provider_class
      ::ActiveMerchant::Billing::CyberpacGateway
    end

    def method_type
      'cyberpac_direct'
    end
  end
end
