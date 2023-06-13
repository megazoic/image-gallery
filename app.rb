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
  
  get "/images/delete/:id" do
    #clean out images_tags first
    image = Image[params[:id].to_i]
    DB.transaction do
      image.remove_all_tags
      #need to remove image file from file system (public/uploads/<image file>)
      cwFilename = image.file
      #filename has /uploads/ prefix eg. /uploads/Screen_Shot_2023-06-05_at_7.43.46_AM.png
      m = /\/uploads\/(.*)/.match(cwFilename.url)
      filename = m[1]
      ["./public/uploads/#{filename}", "./public/uploads/small_#{filename}"].each do |fp|
        if File.exist?(fp)
          File.delete(fp)
        else
          raise StandardError.new "No such file"
        end
      end
      #finally, delete record
      image.delete
    end
    "done"
  end
  
  get "/images/edit/:id" do
    protected!
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
    protected!
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
  
  helpers do
    def protected!
      return if authorized?
      headers['WWW-Authenticate'] = 'Basic realm="Restricted Area"'
      halt 401, "Not authorized\n"
    end

    def authorized?
      @auth ||= Rack::Auth::Basic::Request.new(request.env)
      @auth.provided? and @auth.basic? and @auth.credentials and @auth.credentials == [ENV["MY_SECRET_USER"], ENV["MY_SECRET_PWD"]]
    end
  end
end