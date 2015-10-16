module Spree
  class Gateway::CyberpacRedirect < Gateway::CyberpacDirect
    def auto_capture?
      true
    end

    # We Fake a source with the payment method that don't responds to brand
    # becouse que creadit card is managed in cyberpac, so we always support
    # the source in the gateway
    def supports?(source)
      true
    end

    def purchase(amount, checkout, gateway_options={})
      # The payment is confirmed in the notify call, so we fake a success
      # for the auto capture calls
      ActiveMerchant::Billing::CyberpacResponse.new(true, 'purchase', {})
    end
  end
end
