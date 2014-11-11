#
# Copyright Chef Inc. 2014
# All rights reserved.
#
# Author: Mark Anderson <mark@getchef.com>
#
# Much of this code was orginally derived from the orgmapper tool, which had many varied authors.

require 'singleton'
require 'yajl'


module Fixie
  def self.configure
    yield Config.instance
  end

  ##
  # = Fixie::Config
  # configuration for the orgmapper command.
  #
  # ==Example Config File:
  #
  #   Fixie.configure do |mapper|
  #     mapper.couchdb_uri = 'http://db.example.com:5984'
  #     mapper.database = 'opscode_account'
  #     mapper.authz_uri = 'http://authz.example.com:5959'
  #   end
  #
  class Config
    include Singleton
    KEYS = [:couchdb_uri, :couchdb_auth_database, :authz_uri, :sql_database, :superuser_id, :pivotal_key]
    KEYS.each { |k| attr_accessor k }

    def merge_opts(opts={})
      opts.each do |key, value|
        send("#{key}=".to_sym, value)
      end
    end

    # this is waaay tightly coupled to ::Backend's initialize method
    def to_ary
      [couchdb_uri, database, auth_uri, authz_couch, sql_database, superuser_id].compact
    end

    def to_text
      txt = ["### Fixie::Config"]
      max_key_len = KEYS.inject(0) do |max, k|
        key_len = k.to_s.length
        key_len > max ? key_len : max
      end
      KEYS.each do |key|
        value = send(key) || 'default'
        txt << "# %#{max_key_len}s: %s" % [key.to_s, value]
      end
      txt.join("\n")
    end

    def example_config
      txt = ["Fixie.configure do |mapper|"]
      KEYS.each do |key|
        txt << "  mapper.%s = %s" % [key.to_s, '"something"']
      end
      txt << "end"
      txt.join("\n")
    end

    def load_from_pc(dir = "/etc/opscode")
      configdir = Pathname.new(dir)

      secrets_files = %w(private-chef-secrets.json)
      secrets = load_json_from_path([configdir], secrets_files)

      config_files = %w(chef-server-running.json)
      config = load_json_from_path([configdir], config_files)
     
    end

    def load_json_from_path(pathlist, filelist)
      parser = Yajl::Parser.new
      pathlist.each do |path|
        filelist.each do |file|
          configfile = path + file
          if configfile.file?
            return parser.parse(json)
          end
        end
      end
    end
  end
end
