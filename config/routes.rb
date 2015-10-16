Spree::Core::Engine.routes.draw do
  scope :cyberpac do
    post '/purchase', to: "cyberpac#purchase", as: :purchase_cyberpac
    get '/cancel', to: "cyberpac#cancel", as: :cancel_cyberpac
    get '/confirm/:id', to: "cyberpac#confirm", as: :confirm_cyberpac
    post '/notify/:id', to: "cyberpac#notify", as: :notify_cyberpac
  end
end
