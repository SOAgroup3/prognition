require 'sinatra/base'
require 'json'

require 'haml'
require 'sinatra/flash'

require 'httparty'


class NewsLensUI < Sinatra::Base
  enable :sessions
  register Sinatra::Flash
  use Rack::MethodOverride

  configure :production, :development do
    enable :logging
  end

  configure :development do
    set :session_secret, "something"    # ignore if not using shotgun in development
  end

  API_BASE_URI = 'https://thenewslensapp2.herokuapp.com'
  API_VER = '/api/v1/'

  helpers do
    def current_page?(path = ' ')
      path_info = request.path_info
      path_info += ' ' if path_info == '/'
      request_path = path_info.split '/'
      request_path[1] == path
    end

    def api_url(resource)
      URI.join(API_BASE_URI, API_VER, resource).to_s
    end
  end

  get '/' do
    haml :home
  end

    get '/news' do
    @number = params[:number]
    if @number
      redirect "/news/#{@number}"
      return nil
    end
    haml :news
  end

  get '/news/:number' do
    @news = get_news(params[:number])
    if @news.nil?
      flash[:notice] = 'no news found'
      redirect '/news'
    end
    haml :news
  end

  get '/tutorials' do
    @action = :create
    haml :tutorials
  end

  post '/tutorials' do
    request_url = "#{API_BASE_URI}/api/v1/tutorials"
    number = params[:number].split("\r\n")
    column = params[:column].split("\r\n")
    params_h = {
      number: number
    }

    options =  {  body: params_h.to_json,
                  headers: { 'Content-Type' => 'application/json' }
               }

    result = HTTParty.post(request_url, options)

    if (result.code != 200)
      flash[:notice] = 'number not found'
      redirect '/tutorials'
      return nil
    end

    id = result.request.last_uri.path.split('/').last
    session[:result] = result.to_json
    session[:number] = number
    session[:column] = column
    session[:action] = :create
    redirect "/tutorials/#{id}"
  end

  get '/tutorials/:id' do
    if session[:action] == :create
      @results = JSON.parse(session[:result])
      @number = session[:number]
      @column = session[:column]
    else
      request_url = "#{API_BASE_URI}/api/v1/tutorials/#{params[:id]}"
      options =  { headers: { 'Content-Type' => 'application/json' } }
      result = HTTParty.get(request_url, options)
      @results = result
    end

    @id = params[:id]
    @action = :update
    haml :tutorials
  end

  delete '/tutorials/:id' do
    request_url = "#{API_BASE_URI}/api/v1/tutorials/#{params[:id]}"
    result = HTTParty.delete(request_url)
    flash[:notice] = 'record of tutorial deleted'
    redirect '/tutorials'
  end
end