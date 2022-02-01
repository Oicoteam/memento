require 'active_record'

module Memento

  class ErrorOnRewind < StandardError;end

  class << self

    # For backwards compatibility (was a Singleton)
    def instance
      self
    end

    def watch(user_or_id)
      start(user_or_id)
      yield
      if session && session.tmp_states.any?
        session.save
        session
      else
        false
      end
    ensure
      stop
    end

    def start(user_or_id)
      user_id = user_or_id.is_a?(Integer) ? user_or_id : user.id
      self.session = user_id ? Memento::Session.new(:user_id => user_id) : nil
    end

    def stop
      session.save if session && session.tmp_states.any?
      self.session = nil
    end

    def add_state(action_type, record)
      return unless active?
      session.add_state(action_type, record)
    end

    def active?
      !!session && !ignore?
    end

    def ignore
      Thread.current[:memento_ignore] = true
      yield
    ensure
      Thread.current[:memento_ignore] = false
    end

    def serializer=(serializer)
      @serializer = serializer
    end

    def serializer
      @serializer ||= YAML
    end

    def ignore?
      !!Thread.current[:memento_ignore]
    end

    def session
      Thread.current[:memento_session]
    end

    private

    def session=(session)
      Thread.current[:memento_session] = session
    end
  end
end

def Memento(user_or_id, &block)
  Memento.watch(user_or_id, &block)
end

require 'memento/railtie'
require 'memento/result'
require 'memento/action'
require 'memento/active_record_methods'
require 'memento/action_controller_methods'
require 'memento/state'
require 'memento/session'
