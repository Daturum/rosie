module Rosie
  class Programmer < Rosie::ApplicationRecord
    has_paper_trail(ignore: [:updated_at], on: [:create, :update, :destroy])
    has_secure_password
    validates :email, format: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i, uniqueness: true
    validates :password, length: { minimum: 6 }

    def self.current
      RequestStore["programmer"]
    end
    def self.current= programmer_email
      raise "invalid parameter" if (programmer_email != nil) && !programmer_email.is_a?(String)
      PaperTrail.request.whodunnit = programmer_email
      RequestStore["programmer"] = programmer_email
    end

    def self.update_last_action_timestamp
      raise "Error touching #{current}" unless find_by(email: current).touch
    end
    def self.last_action_timestamp
      RequestStore['programmer.last_action_timestamp'] ||=
        ((table_exists? ? maximum(:updated_at) : nil) || Time.at(1))
    end

    def self.invitation_duration; 10.minutes end

    def self.login email, password
      programmer = find_by(email: email)
      if programmer.blank?
        if !self.exists?
          # creating first programmer
          programmer = create(email: email, password: password)
          programmer = nil unless programmer.persisted?
        else
          return false
        end
      elsif (programmer.password_digest == nil) # invited programmer
        if (programmer.updated_at > invitation_duration.ago)
          programmer.password = password
          programmer.save
        else
          programmer = nil # invitation expired
        end
      elsif !programmer.authenticate(password)
        Rails.logger.fatal "Invalid password attempt for #{email}"
        return false
      end

      if programmer
        self.current = programmer.email
        return true
      else
        self.current = nil
        return false
      end
    end

    def self.short_name email
      return nil unless email
      email.split('@')[0]
    end

    def self.create_test_programmer email, password
      programmer = new(email: email, password: password, updated_at: Programmer.last_action_timestamp)
      programmer.save!
      programmer
    end
  end
end
