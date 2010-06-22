#!/usr/bin/env ruby

__DIR__ = File.expand_path(File.dirname(__FILE__))

require 'sinatra'
require 'errand'
require 'yajl'
require 'haml'
require 'lib/collectd-json'
require 'lib/visage-config'
require 'lib/collectd'

set :public, __DIR__ + '/public'
set :views,  __DIR__ + '/views'

configure do 
  require 'config/init'

  CollectdJSON.rrddir = Visage::Config.rrddir
  Visage::Config::Profiles.profiles = Visage::Config.profiles
end

template :layout do 
  File.read('views/layout.haml')
end

# infrastructure for embedding
get '/javascripts/visage.js' do
  javascript = ""
  %w{raphael-min g.raphael g.line mootools-1.2.3-core mootools-1.2.3.1-more graph}.each do |js|
    javascript += File.read(File.join(__DIR__, 'public', 'javascripts', "#{js}.js"))
  end
  javascript
end

# user facing
get '/' do 
  @hosts = Collectd.hosts
   
  haml :index
end

# sets of scattered graphs
get '/sets' do
    @sets = Visage::Config::Sets.all

    haml :sets
end

get '/sets/:set' do
    @sets = Visage::Config::Sets.all

    haml :sets
end

get '/groups' do 
  @hosts = Collectd.hosts
  @groups = Visage::Config::Groups.all
  
  haml :groups
end

get '/builder' do
    @hosts = Collectd.hosts
    @sets = Visage::Config::Sets.all

    haml :builder
end

get '/builder/:set' do
    @hosts = Collectd.hosts
    @metrics = Collectd.metrics
    @sets = Visage::Config::Sets.all

    @isbuilder=true

    haml :builder
end

post '/builder/clone' do
    @sets = Visage::Config::Sets.all
    clonesource=params[:clonesource]
    clonedest=params[:clonedest]
    
    puts @sets[clonesource].inspect
           
    @sets[clonedest]=@sets[clonesource]
    
    Visage::Config::Sets.write(@sets)
    
    redirect '/builder'
end

post '/builder/delete' do
    @sets = Visage::Config::Sets.all
    @sets.delete(params[:setdelete])
    Visage::Config::Sets.write(@sets)
    
    redirect '/builder'
end

post '/builder/save' do
    newset = {"graphs" => []}
    temp_set={}

    puts params.inspect        

    # ugly ugly ugly, but I suck at JavaScript
    params.each_pair { |key,value|
        k=key.strip
        
        if !temp_set.has_key?(k) then
            temp_set[k]=[]
        end
        
        value.each_value { |v|
            temp_set[k].push v.strip
        }
    }
        
    newset["graphs"].push temp_set
    puts newset.inspect
    
end


get '/:host' do 
  @hosts = Collectd.hosts
  @groups = Visage::Config::Groups.all
  Visage::Config::Profiles.profiles = Visage::Config.get(params[:host])
  @profiles = Visage::Config::Profiles.all
  
  
  haml :corporate
end

get '/:host/:profile' do 
  @hosts = Collectd.hosts
  @groups = Visage::Config::Groups.all
  @profiles = Visage::Config::Profiles.all
  @profile = Visage::Config::Profiles.get(params[:profile])
  
  haml :corporate
end



# JSON data backend

# /data/:host/:plugin/:optional_plugin_instance
get %r{/data/([^/]+)/([^/]+)((/[^/]+)*)} do 
  host = params[:captures][0]
  plugin = params[:captures][1]
  plugin_instances = params[:captures][2]

  collectd = CollectdJSON.new(:rrddir => Visage::Config.rrddir,
                              :fallback_colors => Visage::Config.fallback_colors)
  json = collectd.json(:host => host, 
                       :plugin => plugin,
                       :plugin_instances => plugin_instances,
                       :start => params[:start],
                       :finish => params[:finish],
                       :plugin_colors => Visage::Config.plugin_colors)
  # if the request is cross-domain, we need to serve JSONP
  maybe_wrap_with_callback(json)
end

# wraps json with a callback method that JSONP clients can call
def maybe_wrap_with_callback(json)
  if params[:callback]
    params[:callback] + '(' + json + ')'
  else
    json
  end
end
