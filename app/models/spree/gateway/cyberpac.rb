module Spree
  class Gateway::Cyberpac < Gateway
    preference :merchant_name, :string
    preference :merchant_code, :string, default: '003239696'
    preference :secret_key, :string, default: 'qwertyasdf0123456789'
    preference :terminal, :string, default: '1'

    def provider_class
      ::ActiveMerchant::Billing::CyberpacGateway
    end

    def method_type
      'cyberpac'
    end
  end
end
