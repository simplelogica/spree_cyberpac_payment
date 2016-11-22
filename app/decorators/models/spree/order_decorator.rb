Spree::Order.class_eval do
  def cyberpac_number
    # Send always a different order number to avoid problems with retrys
    # The provider doesn't accept request with duplicate order numbers
    # The number can't be more tha 12 characters and ordar numbers are 9
    # characters long
    "#{number}-#{random_chars(2)}"
  end

  def random_chars n=1
    chars = [*'A'..'Z',*0..9].sample(n)
    chars.join('')
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
