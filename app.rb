require 'sinatra/base'
require 'json'

require 'haml'
require 'sinatra/flash'

require 'httparty'
require 'uri'

class NewsLensUI < Sinatra::Base
  enable :sessions
  register Sinatra::Flash
  use Rack::MethodOverride

  configure :production, :development do
    enable :logging
  end

  configure :development do
 #   set :session_secret, "something"    # ignore if not using shotgun in development
  end

  API_BASE_URI = 'https://newsdynamo.herokuapp.com'
  # API_BASE_URI = 'http://localhost:4567'
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
    @number = params[:number]
    if @number
      redirect "/news/#{@number}"
      return nil
    end
    haml :home
  end

  get '/originals' do
    @originals = HTTParty.get api_url("originals")###########
    if @originals.nil?
      flash[:notice] = 'no news found'
      redirect '/'
    end
    haml :originals
  end

  get '/news/:number' do
    @news = HTTParty.get api_url("#{params[:number]}.json")###########
    if @news.nil?
      flash[:notice] = 'no news found'
      redirect '/'
    end
    haml :home
  end

  get '/keywords' do
    @word = params[:word]
    if @word
      url= "/keywords/#{@word}"
      url = URI::escape(url) 
      redirect url
      return nil
    end
    haml :keywords
  end

  get '/keywords/:word' do
    urls = URI::escape("keywords/#{params[:word]}.json")
    @keywords = HTTParty.get api_url(urls)# use URI::escape (http://blog.sina.com.cn/s/blog_628e2ab30101ah0f.html)
    if @keywords.nil?
      flash[:notice] = 'no keywords found'
      redirect '/keywords'
    end
    haml :keywords
  end

  get '/classification' do
    @action = :create
    haml :classification
  end

  post '/classification' do
    request_url = "#{API_BASE_URI}/api/v1/class"
    number = params[:number].split("\r\n")
    column = params[:column].split("\r\n")
    params_h = {
      number: number,
      column: column
    }

    options =  {  body: params_h.to_json,
                  headers: { 'Content-Type' => 'application/json' }
               }

    result = HTTParty.post(request_url, options)

    if (result.code != 200)
      flash[:notice] = 'number not found'
      redirect '/classification'
      return nil
    end

    id = result.request.last_uri.path.split('/').last
    session[:result] = result.to_json
    session[:number] = number
    session[:column] = column
    session[:action] = :create
    redirect "/classification/#{id}"
  end

  get '/classification/:id' do
    if session[:action] == :create
      @results = JSON.parse(session[:result])
      @number = session[:number]
      @column = session[:column]
    else
      request_url = "#{API_BASE_URI}/api/v1/class/#{params[:id]}"
      options =  { headers: { 'Content-Type' => 'application/json' } }
      result = HTTParty.get(request_url, options)
      logger.info result
      @results = result
    end

    @id = params[:id]
    @action = :update
    haml :classification
  end

  delete '/classification/:id' do
    request_url = "#{API_BASE_URI}/api/v1/class/#{params[:id]}"
    result = HTTParty.delete(request_url)
    flash[:notice] = 'record of classification deleted'
    redirect '/classification'
  end
end