# Stores geocoder results for a User location. Used by the LocationsController to display a map of users.
class Location < ActiveRecord::Base
  serialize :geocoder_results

  after_create :geocode!

  #--
  # Parsing the geocoder results
  #++

  def first_geocoder_result
    return {} if geocoder_results.nil? || geocoder_results.empty?
    geocoder_results[0]
  end

  def address_components
    first_geocoder_result['address_components'] || []
  end

  def country
    component = address_components.find {|component| component['types'].include? "country"}
    component['long_name'] if component
  end

  def formatted_address
    first_geocoder_result['formatted_address']
  end

  def geometry
    first_geocoder_result['geometry'] || {}
  end

  def location
    geometry['location'] || {}
  end

  def lat
    location['lat']
  end

  def lon
    location['lng']
  end

  def types
    first_geocoder_result['types'] || []
  end

  #--
  # Derived attributes
  #++

  def locality?
    types.include?("locality")
  end

  #--
  # Actions
  #++

  def geocode!
    self.geocoder_results = Geocoder.geocode name
    save!
  end
  handle_asynchronously :geocode!

  #--
  # Conversions
  #++

  def to_s
    name
  end

  def as_json(options = {})
    {id: id, name: name}
  end
end
