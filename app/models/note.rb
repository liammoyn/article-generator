# == Schema Information
#
# Table name: notes
#
#  id         :bigint           not null, primary key
#  content    :text
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  topic_id   :integer
#
class Note < ApplicationRecord
  belongs_to :topic, required: true, class_name: "Topic", foreign_key: "topic_id"
  has_one_attached :file
end
