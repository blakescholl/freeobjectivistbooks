# Used to test certain conditions, such as exceptions.
class TestController < ApplicationController
  # Does nothing and renders an empty response.
  def noop
    render nothing: true
  end

  # Raises an exception.
  def exception
    raise "Barf!"
  end

  # Simulates the experience of a blocked user.
  def blocked
    raise BlockedUserException
  end
end
