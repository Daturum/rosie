Rosie::Engine.routes.draw do
  # test
  root to: 'application#home'

  # Programmer area
  get 'p/guide', to: 'programmer#guide'
  get 'p/cns', to: 'programmer#console', as: :programmer_console
  post 'p/go', to: 'programmer#go'
  post '/p/invite_programmer', to: 'programmer#invite', as: :invite_programmer

  get 'p/files', to: 'programmer#files'
  post 'p/files', to: 'programmer#manage_file'
end
