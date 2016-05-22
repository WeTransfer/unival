require 'spec_helper'
require 'rack'
require 'rack/test'
require 'active_record'
require 'sqlite3'

describe 'Unival full-stack' do
  include Rack::Test::Methods
  let(:app) { Unival::App.new }
  
  # This is a full-stack speck, so we are going to do real ActiveRecord and stuff.
  before :all do
    ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')
    
    ActiveRecord::Schema.define do
      create_table :people do |t|
        t.string :name, null: false
        t.string :email, null: true
        t.integer :items, default: 0
      end
      
      create_table :credit_cards do |t|
        t.string :number, null: false, maxlength: 12
      end
    end
    
    class Person < ActiveRecord::Base
      validates_presence_of :name
      validates_uniqueness_of :name
      validates_format_of :email, with: /\w+@\w+/
    end
    
    class CreditCard < ActiveRecord::Base
      validates_presence_of :number
    end
  end
  
  after :each do
    Person.delete_all
  end
  
  it 'performs validation in raw JSON format for a new record and says it may proceed' do
    post '/?model=Person', JSON.dump({name: 'Julik', email: 'julik@example.com'})
    parsed = JSON.parse(last_response.body, symbolize_names: true)
    
    expect(last_response).to be_ok
    expect(parsed).to eq({:model => "Person", :is_create => true, :valid => true, :errors => nil})
  end
  
  it 'performs validation in raw JSON format for a new record and returns an error if the saving would cause a duplicate' do
    john = Person.create name: 'John', email: 'john@example.com'
    
    post '/?model=Person', JSON.dump({name: 'John', email: 'another-john@example.com'})
    
    parsed = JSON.parse(last_response.body, symbolize_names: true)
    expect(last_response).not_to be_ok
    expect(last_response.status).to eq(409)
    expect(parsed).to eq({
      :model => "Person", 
      :is_create => true,
      :valid => false,
      :errors => {:name=>["has already been taken"]}
    })
  end
  
  it 'performs validation in raw JSON format for a record update via PUT and says it may proceed' do
    john = Person.create name: 'John', email: 'john@example.com'
    
    put '/?model=Person&id=%d' % john.id, JSON.dump({name: 'John Doe'})
    
    parsed = JSON.parse(last_response.body, symbolize_names: true)
    expect(last_response).to be_ok
    expect(parsed).to eq({:model => "Person", :is_create => false, :valid => true, :errors => nil})
  end
  
  it 'performs validation in raw JSON format for a record update via PATCH and says it may proceed' do
    john = Person.create name: 'John', email: 'john@example.com'
    
    patch '/?model=Person&id=%d' % john.id, JSON.dump({name: 'John Doe'})
    
    parsed = JSON.parse(last_response.body, symbolize_names: true)
    expect(last_response).to be_ok
    expect(parsed).to eq({:model => "Person", :is_create => false, :valid => true, :errors => nil})
  end
  
  describe 'when the model is not permitted for validation' do
    class MoreRestrictive < Unival::App
      def model_accessible?(model_class)
        model_class == Person
      end
    end
    
    let(:app) { MoreRestrictive.new }
    
    it 'performs validation for a model that is permitted, but forbids it for a model that is not' do
      post '/?model=Person', JSON.dump({name: 'John', email: 'john@example.com'})
      expect(last_response).to be_ok
      
      post '/?model=CreditCard', JSON.dump({number: '123-123-123-123'})
      parsed = JSON.parse(last_response.body, symbolize_names: true)
      
      expect(last_response).not_to be_ok
      expect(parsed).to eq({error: "Invalid model or model not permitted"})
    end
  end
end
