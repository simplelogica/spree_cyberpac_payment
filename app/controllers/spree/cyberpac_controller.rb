module Spree
  class CyberpacController < StoreController
    skip_before_filter :verify_authenticity_token, only: :notify

    before_action :load_order, only: [:confirm, :notify]

    def confirm
      @order.with_lock do
        @order.reload
        unless @order.complete?
          payment = @order.payments.create!({
            amount: @order.total,
            payment_method: payment_method
          })
          @order.next
        end
      end
      flash.notice = Spree.t(:order_processed_successfully)
      flash[:order_completed] = @order.complete?
      session[:order_id] = nil
      redirect_to order_path(@order)
    end

    def notify
      # Create the Cyberpac response from request params
      cyberpac_response = ActiveMerchant::Billing::CyberpacResponse.new(nil, 'notify', params)
      secret = Spree::Gateway::CyberpacRedirect.last.preferences[:secret_key]

      @order.with_lock do
        @order.reload
        payment = @order.payments.valid.last
        payment ||= @order.payments.build
        payment.update_attributes({
          amount: @order.total,
          payment_method: payment_method,
          response_code: cyberpac_response.response_code
        })
        if cyberpac_response.valid_signature?(secret) && cyberpac_response.success?
          payment.capture!
          @order.reload.next
        else
          payment.invalidate
        end
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
      @payment_method ||= Spree::PaymentMethod.where(type: "Spree::Gateway::CyberpacRedirect").last
    end

    def provider
      payment_method.provider
    end

    def load_order
      @order = Spree::Order.where(number: params[:id]).last || raise(ActiveRecord::RecordNotFound)
    end
  end
end
