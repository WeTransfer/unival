require 'spec_helper'
require 'rack'
require 'rack/test'
require 'active_record'
require 'sqlite3'

describe 'Unival app' do
  include Rack::Test::Methods
  let(:app) { Unival::App.new }
  
  describe 'with a model module that supports the proper methods' do
    module SomeModel
      class UserData < Struct.new(:name)
        def valid?
          name == 'John'
        end
        
        def errors
          ['name is wrong']
        end
      end
      
      def self.find(id)
        return SomeModel
      end
    end
  end
  
  describe 'with a model module that returns nil from find()' do
    module NilReturningModel
      def self.find(id); end
    end
    
    it 'returns a 400 and explains what happened' do
      put '/?id=123&model=NilReturningModel', JSON.dump({name: 'Julik', email: 'julik@example.com'})
    
      expect(last_response).not_to be_ok
      parsed = JSON.parse(last_response.body, symbolize_names: true)
      expect(parsed).to eq({:error=>"The model (NilClass) does not support `#valid?'"})
    end
  end
  
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
  
  describe 'with enabled I18n that provides introspection' do
    it 'replaces errors with their keys' do
      fake_errors = [
        double('missing field error string', translation_metadata: {key: 'missing.field'})
      ]
      
      module TranslatedModel
      end
      
      fake_model = double('Translated model with errors')
      
      expect(TranslatedModel).to receive(:new).and_return(fake_model) 

      expect(fake_model).to receive(:attributes=)
      expect(fake_model).to receive(:valid?).and_return(false)
      expect(fake_model).to receive(:errors).and_return(fake_errors)
      
      post '/?model=TranslatedModel', JSON.dump({name: 'Julik', email: 'julik@example.com'})
      
      parsed = JSON.parse(last_response.body, symbolize_names: true)
      expect(last_response).not_to be_ok
      expect(parsed[:errors]).to eq(["missing.field"])
    end
  end
end
