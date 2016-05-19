require 'spec_helper'
require 'rack'
require 'rack/test'
require 'active_record'
require 'sqlite3'

describe 'Unival full-stack' do
  include Rack::Test::Methods
  let(:app) { Unival::App.new }
  
  describe 'with a class that gives a nonsensical to_json' do
    class Nonsense
      def self.to_json(encoder)
        "this should not be happening"
      end
      
      def initialize(*);
      end
      
      def attributes=(*);
      end
      
      def valid?; true; end
    end
    
    it 'uses the qualified module name as model return value' do
      post '/?model=Nonsense', JSON.dump({name: 'Julik', email: 'julik@example.com'})
      parsed = JSON.parse(last_response.body, symbolize_names: true)
    
      expect(last_response).to be_ok
      expect(parsed).to eq({:model => "Nonsense", :is_create => true, :valid => true, :errors => nil})
    end
  end
end
