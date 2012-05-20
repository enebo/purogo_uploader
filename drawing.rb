require 'sinatra'
require 'gollum'
require 'fileutils'

# Check out Purugin.wiki.git and place as sibling
WIKI_LOCATION = ENV['PURUGIN_WIKI_DIR'] || "../Purugin.wiki"
WIKI = Gollum::Wiki.new(WIKI_LOCATION)

def default_drawing
  Drawing.new(request.ip, params['name'], %Q{turtle("my drawing") do\nend\n})
end

get "/" do
  redirect "/edit/drawing"
end

get "/images/:name" do
  send_file "#{WIKI_LOCATION}/images/#{params['name']}", :type => :png
end

get "/:page" do
  puts "P: #{params['page']}"
  page = WIKI.page(params['page'])
  @data = page.formatted_data
  erb :docs
end

get "/edit/" do
  redirect "/edit/drawing"
end

get "/edit/:name" do
  @drawings = Drawing.all(request.ip)
  @drawing = Drawing.find(request.ip, params['name'])
  @drawing = default_drawing unless @drawing
  erb :edit
end

post "/edit/:name" do
  @drawing = Drawing.new(request.ip, params['drawing']['name'], params['drawing']['program'])
  @drawing.save
  @drawings = Drawing.all(request.ip)
  @message = "#{params['drawing']['name']} saved."
  if params['name'] != params['drawing']['name']
    redirect "/edit/#{params['drawing']['name']}"
  else
    erb :edit
  end
end

delete "/edit/:name" do
  @drawing = Drawing.find(request.ip, params['name'])
  if @drawing
    @message = "#{params['name']} removed."
    @drawing.remove
  else
    @drawing = default_drawing
  end
  @drawings = Drawing.all(request.ip)
  erb :edit
end

get "/" do
  redirect "/edit/drawing"
end

get "/images/:name" do
  send_file "#{WIKI_LOCATION}/images/#{params['name']}", :type => :png
end

get "/:page" do
  
  puts "P: #{params['page']}"
  page = WIKI.page(params['page'])
  @data = page.formatted_data
  erb :docs
end

get "/edit/" do
  redirect "/edit/drawing"
end


class Drawing
  DRAWING_DIR = ENV['PUROGO_DRAWING_DIR'] || "../minecraft/plugins/purogo"
  attr_accessor :name, :program

  def initialize(host, name, program)
    @host, @name, @program = host, name, program
  end

  def self.all(host)
    make_user_dir(host)
    glob_expr = File.join(DRAWING_DIR, host, "*.rb")
    Dir[glob_expr].inject([]) do |list, file|
      list << File.basename(file, ".rb")
    end
  end

  def self.find(host, name)
    make_user_dir(host)
    file = File.join(DRAWING_DIR, host, name + ".rb")
    return nil unless File.exist?(file)
    name = File.basename(file, ".rb")
    program = File.readlines(file).join('')
    new(host, name, program)
  end

  def remove
    Drawing.make_user_dir(@host)
    file = File.join(DRAWING_DIR, @host, @name + ".rb")
    File.unlink(file) if File.exists?(file)
  end

  def save
    Drawing.make_user_dir(@host)
    File.open(File.join(DRAWING_DIR, @host, @name + ".rb"), "w") do |f|
      f.write program
    end
  end

  def self.make_user_dir(host)
    dir = File.join(DRAWING_DIR, host)

    FileUtils.mkdir_p dir unless File.directory? dir
  end
end
