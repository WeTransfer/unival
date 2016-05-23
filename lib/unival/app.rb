require 'json'

class Unival::App
  include Unival::Utils
  
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
    
    model_module_name = query_params.delete('model')
    raise Inv, "No model class given (by default passed as the `model' query-string param)" if model_module_name.to_s.empty?
    
    model_module = Kernel.const_get(model_module_name)
    raise Inv, "Invalid model or model not permitted" unless model_accessible?(model_module)
    
    model = if req.post?
      raise Inv, "The model module does not support .new" unless model_module.respond_to?(:new)
      model_module.new
    else
      model_id = query_params.delete('id')
      raise Inv, "No model ID to find given (by default passed as the `id' query-string param)" unless model_id
      raise Inv, "The model module does not support .find" unless model_module.respond_to?(:find)
      model_module.find(model_id)
    end
    
    # Instead of scanning for instance_methods, check the object itself.
    raise Inv, "The model (#{model.class}) does not support `#valid?'" unless model.respond_to?(:valid?)
    
    model_data = filter_model_params(model_module, params)
    
    # Instead of scanning for instance_methods, check the object itself.
    raise Inv, "The model does not support `#valid?'" unless model.respond_to?(:valid?)
    
    # Despite what you might think, attributes= ONLY updates the attributes given in the argument.
    model.attributes = model_data
    
    is_create = req.post?
    if model.valid?
      d = {model: model_module.to_s, is_create: is_create, valid: true, errors: nil}
      [200, {'Content-Type' => 'application/json'}, [JSON.dump(d)]]
    else
      model_errors = replace_with_translation_keys(model.errors)
      d = {model: model_module.to_s, is_create: is_create, valid: false, errors: model_errors}
      [409, {'Content-Type' => 'application/json'}, [JSON.dump(d)]]
    end
  rescue Exception => e
    if e.to_s =~ /NotFound/
      d = {error: "Model not found: #{e}"}
      [404, {'Content-Type' => 'application/json'}, [JSON.dump(d)]]
    elsif e.is_a?(Inv)
      d = {error: e.message}
      [400, {'Content-Type' => 'application/json'}, [JSON.dump(d)]]
    else
      raise e # Something we can't handle internally, raise it up the stack for eventual exception capture in middleware
    end
  end

  # Tells whether it is permitted to validate a given Module object as an ActiveModel.
  # You might want to restrict this further. The default permits everything.
  def model_accessible?(model_module)
    true
  end
  
  # Replaces the literal strings in the model errors (furnished as
  # a json-able Hash with arbitrary nesting) with the I18n keys.
  # Only gets performed if the translation introspection module is present
  # on the I18n backend currently in use.
  def replace_with_translation_keys(model_errors)
    return model_errors if internationalized?
    deep_translation_replace(model_errors)
  end
  
  # Can be used to do optional parameter filtering.
  # If you want to use strong parameters, this is the place to apply them.
  def filter_model_params(model_module, params)
    params
  end
  
  # Extract params like :format, :id and :model
  def extract_query_or_route_params_from(rack_request)
    Rack::Utils.parse_nested_query(rack_request.query_string)
  end
end
