require 'rails_helper'

RSpec.describe House, type: :model do

  it { should have_many(:rooms) }

  it { should validate_presence_of(:name) }

end
