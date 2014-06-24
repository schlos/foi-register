# encoding: utf-8
# == Schema Information
#
# Table name: confirmation_links
#
#  id            :integer          not null, primary key
#  token         :string           not null
#  request_id    :integer          not_null
#  expired       :boolean
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

require 'securerandom'

class ConfirmationLink < ActiveRecord::Base
    belongs_to :request

    before_create :generate_token

    protected

    def generate_token
      self.token = loop do
        random_token = SecureRandom.base64.tr("+/.,?", rand(9).to_s)[0..-3]
        break random_token unless ConfirmationLink.exists?(:token => random_token)
      end
    end
end