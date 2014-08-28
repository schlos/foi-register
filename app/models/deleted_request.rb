class DeletedRequest < ActiveRecord::Base
  # == Schema Information
  #
  # Table name: deleted_requests
  #
  #  id                        :integer          not null, primary key
  #  title                     :string(255)      not null
  #  requestor_id              :integer          not null
  #  created_at                :datetime         not null
  #  updated_at                :datetime         not null
  #  body                      :text             not null
  #  date_received             :date
  #  due_date                  :date             not null
  #  lgcs_term_id              :integer
  #  is_published              :boolean          default(TRUE), not null
  #  is_requestor_name_visible :boolean          default(FALSE), not null
  #  medium                    :string(255)      default("web"), not null
  #  remote_id                 :integer
  #  remote_url                :string(255)
  #  state                     :string(255)      default("new"), not null
  #  nondisclosure_reason      :string(255)
  #  remote_email              :string(255)
  #  top_level_lgcs_term_id    :integer
  #  request_id                :integer          not null
  #  deleted_by                :string(255)
  #  deleted_date              :date             not null
  #
end
