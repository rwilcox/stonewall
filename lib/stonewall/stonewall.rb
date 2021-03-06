module StoneWall
  def self.included(base)
    base.instance_eval do
      def stonewall()
        require File.expand_path(File.dirname(__FILE__)) +
                  "/access_controller.rb"
        require File.expand_path(File.dirname(__FILE__)) +
                  "/parser.rb"
        require File.expand_path(File.dirname(__FILE__)) +
                  "/helpers.rb"
        require File.expand_path(File.dirname(__FILE__)) +
                  "/user_extensions.rb"
        cattr_accessor :stonewall
        self.stonewall = StoneWall::AccessController.new(self)
        yield StoneWall::Parser.new(self)
      end

      # --------------
      # This is 1/3rd of the magic in this gem.  After ActiceRecord defines
      # the classes attribute methods, we come along and alias all of the
      # guarded methods defined in the dsl in the class.
      def self.define_attribute_methods_with_stonewall
        define_attribute_methods_without_stonewall
        StoneWall::Helpers.fix_aliases_for(self) # if a stonewall enhanced class?
      end

      class << self
        unless respond_to?(:define_attribute_methods_without_stonewall)
          alias_method_chain :define_attribute_methods, :stonewall
        end
      end
    end

    # mimicking the send method, we want to ask permission first with send?
    def send?(method, user = User.current)
      self.class.stonewall.allowed?(self, user, method)
    end
    alias_method :allowed?, :send?
    
    def send_method_group?(group_name, user = User.current)
      self.class.stonewall.method_groups[group_name].each do |method|
        return false unless self.send?(method, user)
      end
      return true
    end
    alias_method :allowed_method_group?, :send_method_group?
    
  end
end