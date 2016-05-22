module Unival::Utils
  def deep_translation_replace(v)
    if v.is_a?(Array)
      v.map{|e| deep_translation_replace(e) }
    elsif v.is_a?(Hash)
      v.each_with_object({}){|(k, v), o| o[deep_translation_replace(k)] = deep_translation_replace(v) }
    else
      if v.respond_to?(:translation_metadata)
        v.translation_metadata.fetch(:key)
      else
        v
      end
    end
  end

  def internationalized?
    !defined?(I18n) || !I18n.backend
  end

  # Hackishly use Rack to reconstruct a hash of keys-values, with nesting
  def repack_jquery_serialization(model_module_name, jquery_array_of_fields)
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