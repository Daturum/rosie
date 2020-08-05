Rails.application.routes.draw do
  mount Rosie::Engine => (ENV['ROSIE_MOUNT_PATH']||"/")
end
