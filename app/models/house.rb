class House < ApplicationRecord
	has_many :rooms, dependent: :destroy

	validates_presence_of :name
end
