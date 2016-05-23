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
end