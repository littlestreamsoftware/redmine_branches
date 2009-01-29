class StaleObject
  include Redmine::I18n
  include ERB::Util
  attr_accessor :attributes
  attr_accessor :changes
  
  def initialize(stale_object)
    raise ArgumentError.new("Call with an ActiveRecord object") unless stale_object.respond_to?(:attributes)
    @attributes = stale_object.attributes.dup
  end
  
  def difference_messages(fresh_object, options = { })
    options = { 
      :wrap => "ul",
      :item => "li"
    }.merge(options)

    changes = self.changes(fresh_object)
    
    if changes.empty?
      error_messages = ''
    else
      error_messages = "<#{options[:wrap]}>"
      changes.each do |key,value|
        if key.match(/(.*)(_id)$/)
          association = fresh_object.class.reflect_on_association($1.to_sym)
          if association
            field = 'field_' + key.sub($2,'')
            if value.nil?
              data_value = l(:label_none)
            else
              data_value = association.klass.find(value)
            end
          end
        end
        field ||= 'field_' + key
        data_value ||= value || l(:label_none)

        error_messages << "<#{options[:item]}>#{l(:text_changed_to, :label => l(field.to_sym), :new => html_escape(data_value))}</#{options[:item]}>"
      end
      error_messages << "</#{options[:wrap]}>"
    end
    
    return error_messages
  end

  def changes(fresh_object)
    @changes ||= @attributes.diff(fresh_object.attributes).except('lock_version') || { }
  end
end
