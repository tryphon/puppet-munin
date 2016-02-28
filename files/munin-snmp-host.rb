#!/usr/bin/env ruby

require 'fileutils'

class Host

  attr_accessor :name, :plugin_names

  def initialize(name, plugin_names = [])
    @name = name
    @plugin_names = plugin_names
  end

  def check
    plugins.all?(&:present?)
  end

  def create
    plugins.each(&:link)
  end

  class Plugin

    @@munin_plugins_dir = '/etc/munin/plugins'
    @@munin_scripts_dir = '/usr/share/munin/plugins'

    attr_accessor :host, :name

    def initialize(host, name)
      @host = host
      @name = name
    end

    def link_path
      "#{@@munin_plugins_dir}/snmp_#{host}_#{name}"
    end

    def target_path
      "#{@@munin_scripts_dir}/snmp__#{name}"
    end

    def present?
      puts "check #{link_path}"
      File.exists? link_path
    end

    def link
      FileUtils.ln_sf target_path, link_path unless present?
    end

    def unlink
      FileUtils.safe_unlink link_path
    end
  end

  def plugins
    @plugins ||= plugin_names.map { |n| Plugin.new name, n }
  end

end

command = ARGV.shift
success = Host.new(ARGV.shift, ARGV).send(command)
exit (success ? 0 : 1)
