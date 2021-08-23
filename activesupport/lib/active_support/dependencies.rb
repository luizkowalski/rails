# frozen_string_literal: true

require "set"
require "active_support/core_ext/module/attribute_accessors"
require "active_support/dependencies/interlock"

module ActiveSupport # :nodoc:
  module Dependencies # :nodoc:
    require_relative "dependencies/require_dependency"

    UNBOUND_METHOD_MODULE_NAME = Module.instance_method(:name)
    private_constant :UNBOUND_METHOD_MODULE_NAME

    mattr_accessor :interlock, default: Interlock.new

    # :doc:

    # Execute the supplied block without interference from any
    # concurrent loads.
    def self.run_interlock
      interlock.running { yield }
    end

    # Execute the supplied block while holding an exclusive lock,
    # preventing any other thread from being inside a #run_interlock
    # block at the same time.
    def self.load_interlock
      interlock.loading { yield }
    end

    # Execute the supplied block while holding an exclusive lock,
    # preventing any other thread from being inside a #run_interlock
    # block at the same time.
    def self.unload_interlock
      interlock.unloading { yield }
    end

    # :nodoc:

    # The set of directories from which we may automatically load files. Files
    # under these directories will be reloaded on each request in development mode,
    # unless the directory also appears in autoload_once_paths.
    mattr_accessor :autoload_paths, default: []

    # The set of directories from which automatically loaded constants are loaded
    # only once. All directories in this set must also be present in +autoload_paths+.
    mattr_accessor :autoload_once_paths, default: []

    # This is a private set that collects all eager load paths during bootstrap.
    # Useful for Zeitwerk integration. Its public interface is the config.* path
    # accessors of each engine.
    mattr_accessor :_eager_load_paths, default: Set.new

    # If reloading is enabled, this private set holds autoloaded classes tracked
    # by the descendants tracker. It is populated by an on_load callback in the
    # main autoloader. Used to clear state.
    mattr_accessor :_autoloaded_tracked_classes, default: Set.new

    def self.eager_load?(path)
      _eager_load_paths.member?(path)
    end

    # Search for a file in autoload_paths matching the provided suffix.
    def self.search_for_file(path_suffix)
      path_suffix += ".rb" unless path_suffix.end_with?(".rb")

      autoload_paths.each do |root|
        path = File.join(root, path_suffix)
        return path if File.file? path
      end
      nil # Gee, I sure wish we had first_match ;-)
    end
  end
end
