# Displays the "locations" page with a map of users around the world.
class LocationsController < ApplicationController
  def index
    @users = Request.active.includes(:user).all.map {|request| request.user}.uniq
    @location_names = @users.map {|user| user.location}.uniq
    @locations = Location.where(name: @location_names)
    @countries = @locations.map {|location| location.country}.uniq.compact.sort
    @markers = @locations.select {|location| location.locality?}
  end
end
