module Spree
  class CyberpacController < StoreController
    skip_before_filter :verify_authenticity_token, only: :notify

    before_action :load_order, only: [:confirm, :notify]

    def confirm
      @order.next
      flash.notice = Spree.t(:order_processed_successfully)
      flash[:order_completed] = @order.complete?
      session[:order_id] = nil
      redirect_to order_path(@order)
    end

    def notify
      # Create the Cyberpac response from request params
      cyberpac_response = ActiveMerchant::Billing::CyberpacResponse.new(nil, 'notify', params)
      secret = Spree::Gateway::Cyberpac.last.preferences[:secret_key]

      payment = order.payments.create!({
        source: payment_method,
        amount: @order.total,
        payment_method: payment_method,
        response_code: cyberpac_response.response_code
      })
      if cyberpac_response.valid_signature?(secret) && cyberpac_response.success?
        @order.next
      else
        payment.invalidate
      end
      render nothing: true
    end

    def cancel
      flash[:notice] = Spree.t('flash.cancel', scope: 'cyberpac')
      order = current_order || raise(ActiveRecord::RecordNotFound)
      redirect_to checkout_state_path(order.state)
    end

    private

    def payment_method
      @payment_method ||= Spree::PaymentMethod.where(id: params[:payment_method_id]).first
      @payment_method ||= Spree::PaymentMethod.where(type: "Spree::Gateway::Cyberpac").last
    end

    def provider
      payment_method.provider
    end

    def load_order
      @order = Spree::Order.where(number: params[:id]).last || raise(ActiveRecord::RecordNotFound)
    end
  end
end
