#
# RFC822 Email Address Regex
# --------------------------
# 
# Originally written by Cal Henderson
# c.f. http://iamcal.com/publish/articles/php/parsing_email/
#
# Translated to Ruby by Tim Fletcher, with changes suggested by Dan Kubb.
#
# Licensed under a Creative Commons Attribution-ShareAlike 2.5 License
# http://creativecommons.org/licenses/by-sa/2.5/
# 
module RFC822
  EmailAddress = begin
    qtext = '[^\\x0d\\x22\\x5c\\x80-\\xff]'
    dtext = '[^\\x0d\\x5b-\\x5d\\x80-\\xff]'
    atom = '[^\\x00-\\x20\\x22\\x28\\x29\\x2c\\x2e\\x3a-' +
      '\\x3c\\x3e\\x40\\x5b-\\x5d\\x7f-\\xff]+'
    quoted_pair = '\\x5c[\\x00-\\x7f]'
    domain_literal = "\\x5b(?:#{dtext}|#{quoted_pair})*\\x5d"
    quoted_string = "\\x22(?:#{qtext}|#{quoted_pair})*\\x22"
    domain_ref = atom
    sub_domain = "(?:#{domain_ref}|#{domain_literal})"
    word = "(?:#{atom}|#{quoted_string})"
    domain = "#{sub_domain}(?:\\x2e#{sub_domain})*"
    local_part = "#{word}(?:\\x2e#{word})*"
    addr_spec = "(#{local_part})\\x40(#{domain})"
    pattern = /\A#{addr_spec}\z/
  end
end

# Validation helper for ActiveRecord derived objects that cleanly and simply
# allows the model to check if the given string is a syntactically valid email
# address (by using the RFC822 module above).
#
# Original code by Ximon Eighteen <ximon.eightee@int.greenpeace.org> which was
# heavily based on code I can no longer find on the net, my apologies to the
# author!
#
# Huge credit goes to Dan Kubb <dan.kubb@autopilotmarketing.com> for
# submitting a patch to massively simplify this code and thereby instruct me
# in the ways of Rails too! I reflowed the patch a little to keep the line
# length to a maximum of 78 characters, an old habit.
#
module ActiveRecord #:nodoc:
  class Errors #:nodoc:
    default_error_messages.update(
      :invalid_email => 'is an invalid email'
    )
  end
  
  module Validations #:nodoc:
    module ClassMethods
      #
      EMAIL_LENGTH_OPTIONS = [
        :minimum,
        :maximum,
        :is,
        :within,
        :in,
        :too_long,
        :too_short,
        :wrong_length
      ]
      
      #
      EMAIL_BOTH_OPTIONS = [
        :message,
        :allow_nil,
        :on,
        :if
      ]
      
      # Configuration options:
      # * <tt>minimum</tt> - The minimum size of the attribute
      # * <tt>maximum</tt> - The maximum size of the attribute
      # * <tt>is</tt> - The exact size of the attribute
      # * <tt>within</tt> - A range specifying the minimum and maximum size of the attribute
      # * <tt>in</tt> - A synonym(or alias) for :within
      # * <tt>too_long</tt> - The error message if the attribute goes over the maximum (default is: "is too long (maximum is %d characters)")
      # * <tt>too_short</tt> - The error message if the attribute goes under the minimum (default is: "is too short (min is %d characters)")
      # * <tt>wrong_length</tt> - The error message if using the :is method and the attribute is the wrong size (default is: "is the wrong length (should be %d characters)")
      # 
      # Configuration options for both length and format:
      # * <tt>message</tt> - A custom error message
      # * <tt>allow_nil</tt> - Attribute may be nil; skip validation.
      # * <tt>on</tt> - Specifies when this validation is active (default is :save, other options :create, :update)
      # * <tt>if</tt> - Specifies a method, proc or string to call to determine if the validation should
      # occur (e.g. :if => :allow_validation, or :if => Proc.new { |user| user.signup_step > 2 }).  The
      # method, proc or string should return or evaluate to a true or false value.
      # 
      def validates_as_email(*attr_names)
        configuration = attr_names.last.is_a?(Hash) ? attr_names.pop : {}
        configuration.reverse_merge!(
          :message => ActiveRecord::Errors.default_error_messages[:invalid_email]
        )
        
        # Add format validation
        format_configuration = configuration.reject {|key, value| !EMAIL_BOTH_OPTIONS.include?(key)}
        format_configuration[:with] = RFC822::EmailAddress
        validates_format_of attr_names, format_configuration
        
        # Add length validation
        length_configuration = configuration.reject {|key, value| !(EMAIL_LENGTH_OPTIONS + EMAIL_BOTH_OPTIONS).include?(key)}
        length_configuration.reverse_merge!(:within => 3..384)
        validates_length_of attr_names, length_configuration
      end
    end
  end
end
