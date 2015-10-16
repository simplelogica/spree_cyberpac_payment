module Spree
  class Gateway::CyberpacRedirect < Gateway::CyberpacDirect
    def method_type
      'cyberpac_redirect'
    end

    def actions
      %w{capture}
    end

    # Indicates whether its possible to capture the payment
    def can_capture?(payment)
      payment.checkout?
    end

    def capture(*)
      simulated_successful_billing_response
    end

    def cancel(*)
      simulated_successful_billing_response
    end

    def credit(*)
      simulated_successful_billing_response
    end

    def auto_capture?
      false
    end

    def source_required?
      false
    end

    private

    def simulated_successful_billing_response
      ActiveMerchant::Billing::CyberpacResponse.new(true, 'capture')
    end
  end
end
