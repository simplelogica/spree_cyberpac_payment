Spree::Order.class_eval do
  def cyberpac_number
    payment_number = "#{number}"
    payment_number += "-#{payments.count}" if payments.any?
    payment_number
  end

  def cyberpac_purchase_data
    {
      :number => cyberpac_number,
      :total => (total * 100).to_i,
      :user_name => bill_address.try(:full_name),
      :currency => currency,
      :locale => I18n.locale
    }
  end
end
