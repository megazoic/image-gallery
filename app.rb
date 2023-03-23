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
    haml :show
  end

  get "/auth" do
    protected!
    redirect "/"
  end

  post "/images" do
    protected!
    tags = DB[:tags]
    puts params
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
    puts params
    "done"
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