module Spree
  class CyberpacController < StoreController
    skip_before_filter :verify_authenticity_token, only: :notify

    before_action :load_order, only: [:confirm, :notify]

    # TODO: Add purchase method using Cyberpac direct gateway
    def purchase
      raise(ActiveRecord::RecordNotFound)
    end

    def confirm
      Rails.logger.tagged("Cyberpac confirm order #{@order.number}") do
        Rails.logger.info "State (Initial): #{@order.state}"
        @order.with_lock do
          unless @order.complete?
            # If the order is not complete, we arrive here before the notify
            # so we create checkout payment and complete the order meanwhile
            # the notify arrives
            @order.payments.create!({
              amount: @order.total,
              payment_method: payment_method
            }) if @order.payments.valid.empty?
            Rails.logger.info "State (Before next): #{@order.state}"
            @order.next
            Rails.logger.info "State (After next): #{@order.state}"
            if @order.errors.any?
              Rails.logger.info "State (After next errors): #{@order.errors.full_messages}"
            end
          end
        end
      end
      if @order.complete?
        flash.notice = Spree.t(:order_processed_successfully)
        flash[:order_completed] = true
        session[:order_id] = nil
        redirect_to completion_route
      else
        redirect_to checkout_state_path(@order.state)
      end
    end

    def notify
      Rails.logger.tagged("Cyberpac notify order #{@order.number}") do
        # Create the Cyberpac response from request params
        cyberpac_response = ActiveMerchant::Billing::CyberpacResponse.new(nil, 'notify', params)
        secret = Spree::Gateway::CyberpacRedirect.last.preferences[:secret_key]
        Rails.logger.info "State (Initial): #{@order.state}"
        @order.with_lock do
          Rails.logger.info "State (Before payment): #{@order.state}"
          # Get last valid payment (in case we get before the confirm request)
          # or build a new payment
          payment = @order.payments.valid.last || @order.payments.build
          payment.update_attributes({
            amount: cyberpac_response.response_amount,
            payment_method: payment_method,
            response_code: cyberpac_response.response_code
          })
          Rails.logger.info "State (After payment): #{@order.state}"
          if cyberpac_response.valid_signature?(secret) && cyberpac_response.success?
            # Capture the payment and reload the order to have the new payment state loaded
            payment.capture!
            Rails.logger.info "State (After capture): #{@order.state}"
            # Reload in case states changed
            @order.reload
            Rails.logger.info "State (After reload): #{@order.state}"

            # Fix in case the user change the state browsing the funnel in another process while paying
            begin
              state_change = @order.next
            end while state_change && !@order.complete?
            Rails.logger.info "State (After complete): #{@order.state}"
            if @order.errors.any?
              Rails.logger.info "State (After complete errors): #{@order.errors.full_messages}"
            end
            if @order.complete?
              @order.shipments.each do |shipment|
                shipment.update!(@order)
                shipment.finalize! if shipment.ready?
              end
            else
              # If this wasn't here, order would transition to address state on complete failure
              # because there would be no valid payments any more.
              @order.update_column :state, 'confirm'
            end
            Rails.logger.info "State (Before ends): #{@order.state}"
          else
            payment.invalidate
          end
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
