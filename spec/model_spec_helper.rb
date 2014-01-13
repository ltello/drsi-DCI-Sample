require 'spec_helper'
require 'unit_spec_helper'
require 'active_record'
require 'virtus'
require 'devise'
require 'database_cleaner_config'
require 'support/object_mother'
require 'devise/orm/active_record'
require 'drsi'

db_yml_file = File.expand_path('config/database.yml')
db_config = YAML.load_file(db_yml_file)
ActiveRecord::Base.establish_connection(db_config['test'])
