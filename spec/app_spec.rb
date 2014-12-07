require_relative 'spec_helper'
require_relative 'support/story_helpers'
require 'json'
require 'date'

describe 'Prognition Stories' do
  include StoryHelpers

  describe 'Getting the root of the service' do
    it 'Should return ok' do
      get '/'
      last_response.must_be :ok?
      last_response.body.must_match(/thenewslensapp/i)
    end
  end

end
