class Project < ApplicationRecord
  
  include ActiveModel::Serializers::JSON

  attr_accessor :name, :owner, :url, :stars

  def attributes=(hash)
    hash.each do |key, value|
      send("#{key}=", value)
    end
  end

  def attributes
    {'name' => nil, 'owner' => nil, 
      'url' => nil, 'stars' => nil}
  end 
end