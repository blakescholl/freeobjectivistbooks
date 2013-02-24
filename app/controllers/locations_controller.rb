# Displays the "locations" page with a map of users around the world.
class LocationsController < ApplicationController
  def index
    @requests = Request.active.includes(user: :location).all
    @users = @requests.map {|request| request.user}.uniq
    @locations = @users.map {|user| user.location}.uniq
    @countries = @locations.map {|location| location.country}.uniq.compact.sort
    @markers = @locations.select {|location| location.locality?}
  end
end
