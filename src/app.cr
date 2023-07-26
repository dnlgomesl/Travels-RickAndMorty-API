require "json"
require "kemal"
require "./controller/*"

module App
  VERSION = "0.1.0"
  Kemal.run
end
