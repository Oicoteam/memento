module Memento::RecordChanges
  
  IGNORE_ATTRIBUTES = [:updated_at, :created_at]
  
  def self.included(base)
    base.send :extend, ClassMethods
  end
  
  module ClassMethods
    
    def record_changes(action_type_types=Memento::Action::Base.action_types)
      include InstanceMethods
      
      action_type_types.each do |action_type|
        callback_exists = send(:"after_#{action_type}_callback_chain").any? do |callback|
          callback.method.to_sym == :"record_#{action_type}"
        end
        send :"after_#{action_type}", :"record_#{action_type}" unless callback_exists
      end
      
      has_many :memento_states, :class_name => "Memento::State", :as => :recorded_object
    end
  end
  
  module InstanceMethods
    
    def attributes_for_recording
      attributes.delete_if{|key, value| Memento::RecordChanges::IGNORE_ATTRIBUTES.include?(key.to_sym) }
    end
    
    def changes_for_recording
      changes.delete_if{|key, value| Memento::RecordChanges::IGNORE_ATTRIBUTES.include?(key.to_sym) }
    end
    
    private
    
    Memento::Action::Base.action_types.each do |action_type|
      define_method :"record_#{action_type}" do
        Memento.instance.add_state(action_type, self)
      end
    end
  end
  
end

ActiveRecord::Base.send(:include, Memento::RecordChanges) if defined?(ActiveRecord::Base)