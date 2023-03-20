require "bundler"
Bundler.require

ENV["ENV_RACK"] ||= "development"

DB = Sequel.connect "sqlite://db/#{ENV["ENV_RACK"]}.sqlite3"

require "./app"
require "./lib/image_uploader"
require "./lib/image"

run App