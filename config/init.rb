#!/usr/bin/env ruby

__DIR__ = File.expand_path(File.dirname(__FILE__))
require File.join(__DIR__, '..', 'lib', 'visage-config')

require 'yaml'

Visage::Config.use do |c|
  c['fallback_colors'] = YAML::load(File.read(File.join(__DIR__, 'fallback-colors.yaml')))
 
  # Load profiles (config/profiles.yaml + config/*-profiles.yaml)
  profiles_config_files = Dir.glob(__DIR__+"/*-profiles.yaml")
  profile_filename = File.join(__DIR__, 'profiles.yaml')
  unless File.exists?(profile_filename)
    puts "You need to specify a list of profiles in config/profile.yaml!"
    puts "Check out config/profiles.yaml.sample for an example."
    exit 1
  end
  profiles_config_files.insert(0, profile_filename)
  
  profiles_string = ""
  profiles_config_files.each do |f|
    profiles_string += File.read(f)
  end
  puts profiles_string
  
  YAML::load(profiles_string).each_pair do |key, value|
    c[key] = value
  end

  # Load colors
  plugin_colors_filename = File.join(__DIR__, 'plugin-colors.yaml')
  unless File.exists?(plugin_colors_filename)
    puts "It's highly recommended you specify graph line colors in config/plugin-colors.yaml!"
  end
  YAML::load(File.read(plugin_colors_filename)).each_pair do |key, value|
    c[key] = value
  end

  # Location of collectd's RRD - you may want to edit this!
  c['rrddir'] = "/var/lib/collectd/rrd"

  # whether to shade in graphs
  c['shade'] = false
  
  # groups, to have fewer hosts displayed at the same time
  c['groups']={}
  groups_config_filename = File.join(__DIR__, 'groups.yaml')
  unless File.exists?(groups_config_filename)
    puts "You need to have a groups config file ! Exiting"
    exit 1
  end
  YAML::load(File.read(groups_config_filename)).each_pair { |key,value|
    hosts=value.split
    hosts.each { |h|
      c['groups'][h]=key
    }
  }
  
  # sets, to aggregate graphs with particular metrics from different machines
  c['sets']={}
  sets_filename = File.join(__DIR__, 'sets.yaml')
  unless File.exists?(sets_filename)
    puts "You need to have a sets config file ! Exiting"
    exit 1
  end
  YAML::load(File.read(sets_filename)).each_pair { |key, value|
    c['sets'][key]=value
  }
  
end
