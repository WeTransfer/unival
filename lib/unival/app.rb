require 'json'

class Unival::App
  SUPPORTED_METHODS = %w( PUT POST PATCH )
  Inv = Class.new(StandardError)
  
  def call(env)
    req = Rack::Request.new(env)
    
    # Only support POST, PUT and PATCH
    if !SUPPORTED_METHODS.include?(env['REQUEST_METHOD'])
      e = {error: 'Unsupported HTTP method %s' % env['REQUEST_METHOD']}
      return [406, {'Content-Type' => 'application/json', 'Allow' => 'POST,PUT,PATCH'}, [JSON.dump(e)]]
    end
    
    params = JSON.load(env['rack.input'].read)
    
    query_params = extract_query_or_route_params_from(req)
    
    model_class_name = query_params.delete('model')
    raise Inv, "No model class given (by default passed as the `model' query-string param)" unless model_class_name.present?
  
    model_class = Kernel.const_get(model_class_name)
    raise Inv, "Invalid model or model not permitted" unless model_accessible?(model_class)
    
    model = if req.post?
      raise Inv, "The model module does not support .new" unless model_class.respond_to?(:new)
      model_class.new
    else
      model_id = query_params.delete('id')
      raise Inv, "No model ID to find given (by default passed as the `id' query-string param)" unless model_id
      raise Inv, "The model module does not support .find" unless model_class.respond_to?(:find)
      model_class.find(model_id)
    end
    
    model_data = if query_params['format'].to_s.downcase == 'jquery'
      repack_jquery_serialization(model_class_name, params)
    else
      params
    end
    
    # Instead of scanning for instance_methods, check the object itself.
    raise Inv, "The model does not support `#valid?'" unless model.respond_to?(:valid?)
    
    # Despite what you might think, attributes= ONLY updates the attributes given in the argument.
    model.attributes = model_data
    
    is_create = req.post?
    if model.valid?
      d = {model: model_class, is_create: is_create, valid: true, errors: nil}
      [200, {'Content-Type' => 'application/json'}, [JSON.dump(d)]]
    else
      d = {model: model_class, is_create: is_create, valid: false, errors: model.errors.as_json}
      [409, {'Content-Type' => 'application/json'}, [JSON.dump(d)]]
    end
  rescue Exception => e
    if e.to_s =~ /NotFound/
      d = {error: "Model not found: #{e}"}
      [404, {'Content-Type' => 'application/json'}, [JSON.dump(d)]]
    elsif e === Inv
      d = {error: e.message}
      [400, {'Content-Type' => 'application/json'}, [JSON.dump(d)]]
      []
    else
      d = {error: e.message}
      [502, {'Content-Type' => 'application/json'}, [JSON.dump(d)]]
    end
  end

  # Tells whether it is permitted to validate a given Module object as an ActiveModel.
  # You might want to restrict this further. The default permits everything.
  def model_accessible?(model_module)
    true
  end
  
  # Logs the exception for later use
  def log_exception(e)
    $stderr.puts e.message
  end
  
  # Extract params like :format, :id and :model
  def extract_query_or_route_params_from(rack_request)
    Rack::Utils.parse_nested_query(rack_request.query_string)
  end

  # Hackishly use Rack to reconstruct a hash of keys-values, with nesting
  def repack_jquery_serialization(model_class_name, jquery_array_of_fields)
    reassembled_query = jquery_array_of_fields.map do |elem|
      Rack::Utils.escape(elem.fetch('name')) + '=' + Rack::Utils.escape(elem.fetch('value'))
    end.join('&')
  
    param_hash = Rack::Utils.parse_nested_query(reassembled_query)
  
    raise "The resulting parametric object must be a Hash" unless param_hash.is_a?(Hash)
    raise "The resulting parametric object must have 1 key" unless param_hash.keys.one?
    object_params = param_hash.fetch(param_hash.keys[0])

    raise "The resulting unwrapped object params must be a Hash" unless object_params.is_a?(Hash)
  
    return object_params.with_indifferent_access
  end
end
