=begin
require 'sinatra'
require 'sequel'
DB = Sequel.connect "sqlite://db/development.sqlite3"
require 'carrierwave'
require_relative 'lib/image_uploader'
require_relative 'lib/image'
require_relative 'lib/tag'
=end

class App < Sinatra::Base
  set :haml, { escape_html: false }
  get "/" do
    @auth = authorized?
    tag_list = Tag.select(:name).all
    @list = []
    tag_list.each do |t|
      @list << t[:name]
    end
    @images = Image.all
    haml :index
  end

  get "/images/:id" do
    @image = Image[params[:id]]
    @image_tags = ""
    @image.tags.each do |tag|
      @image_tags << "#{tag[:name]},"
    end
    @image_tags.chop!
    haml :show
  end
  
  get "/images/edit/:id" do
    #need a list of all tags, tags assoc with this image and image title
    @image = Image[params[:id].to_i]
    image_tags = @image.tags
    @image_tags = ""
    image_tags.each do |it|
      @image_tags << "#{it[:name]},"
    end
    @image_tags.chop!
    all_tags = Tag.select(:name).all
    @tag_list = []
    all_tags.each do |t|
      @tag_list << t[:name]
    end
    haml :edit
  end
  
  post "/images/edit" do
    #params = {"image_tags"=>"sitting,watercolor,newish", "image_id"=>"2", "image_title"=>"japanese landscape"}
    images = DB[:images]
    tags = DB[:tags]
    tag_ids = []
    params[:image_tags].split(",").each do |it|
      #there may be new tags
      tag = nil
      tag = Tag.where(name: it).first
      if tag.nil?
        t = Tag.new(name: it)
        t.save
        tag_ids << t.id
      else
        tag_ids << tag[:id]
      end
    end
    #associate tags with image
    Image[id: params[:image_id]].remove_all_tags
    tag_ids.each do |ti|
      t = Tag[ti]
      Image[id: params[:image_id]].add_tag(t)
    end
    #update title
    Image[id: params[:image_id]].update(title: params[:image_title])
    redirect "/images/#{params[:image_id]}"
  end

  get "/auth" do
    protected!
    redirect "/"
  end

  post "/images" do
    protected!
    tags = DB[:tags]
    if params[:image].has_key?("file")
      image = Image.new params[:image]
      saved_image = image.save
      if !params[:image_tags].empty?
        #expecting a string with either a single tag or multiple tags separated by commas
        params[:image_tags].split(',').each do |str|
          #see if this tag exists
          this_tag = Tag.where(name: str).first
          if this_tag.nil?
            #need to enter tag before assigning it 
            saved_tag = tags.insert(name: str)
            saved_image.add_tag(saved_tag)
          else
            saved_image.add_tag(this_tag)
          end
        end
      end
    end
    redirect "/"
  end
  
  get "/test_jsuite" do
    tag_list = Tag.select(:name).all
    @list = []
    tag_list.each do |t|
      @list << t[:name]
    end
    haml :test_jsuite
  end
  post "/test_jsuite" do
    #params = {"mytags"=>"sitting,watercolor"}
    images = []
    params["mytags"].split(",").each do |tag_string|
      tag_object = Tag.where(name: tag_string).first
      images << tag_object.images
    end
    @images = images.flatten
    @images = @images.uniq {|i| i.title}
    haml :subset
  end

  helpers do
    def protected!
      return if authorized?
      headers['WWW-Authenticate'] = 'Basic realm="Restricted Area"'
      halt 401, "Not authorized\n"
    end

    def authorized?
      @auth ||= Rack::Auth::Basic::Request.new(request.env)
      @auth.provided? and @auth.basic? and @auth.credentials and @auth.credentials == ['jose', 'my_special_password']
    end
  end
end