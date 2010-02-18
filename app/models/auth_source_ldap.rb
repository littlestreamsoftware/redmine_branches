# redMine - project management software
# Copyright (C) 2006  Jean-Philippe Lang
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

require 'net/ldap'
require 'iconv'

class AuthSourceLdap < AuthSource 
  validates_presence_of :host, :port, :attr_login
  validates_length_of :name, :host, :account_password, :maximum => 60, :allow_nil => true
  validates_length_of :account, :base_dn, :maximum => 255, :allow_nil => true
  validates_length_of :attr_login, :attr_firstname, :attr_lastname, :attr_mail, :maximum => 30, :allow_nil => true
  validates_numericality_of :port, :only_integer => true
  
  before_validation :strip_ldap_attributes

  serialize :custom_attributes
  
  def after_initialize
    self.port = 389 if self.port == 0
    self.custom_attributes = {} if self.custom_attributes.nil?
  end
  
  def authenticate(login, password)
    return nil if login.blank? || password.blank?
    attrs = get_user_dn(login)
    
    if attrs && attrs[:dn] && authenticate_dn(attrs[:dn], password)
      logger.debug "Authentication successful for '#{login}'" if logger && logger.debug?
      return attrs.except(:dn)
    end
  rescue  Net::LDAP::LdapError => text
    raise "LdapError: " + text
  end

  # test the connection to the LDAP
  def test_connection
    ldap_con = initialize_ldap_con(self.account, self.account_password)
    ldap_con.open { }
  rescue  Net::LDAP::LdapError => text
    raise "LdapError: " + text
  end
 
  def auth_method_name
    "LDAP"
  end
  
  private
  
  def strip_ldap_attributes
    [:attr_login, :attr_firstname, :attr_lastname, :attr_mail].each do |attr|
      write_attribute(attr, read_attribute(attr).strip) unless read_attribute(attr).nil?
    end
  end
  
  def initialize_ldap_con(ldap_user, ldap_password)
    options = { :host => self.host,
                :port => self.port,
                :encryption => (self.tls ? :simple_tls : nil)
              }
    options.merge!(:auth => { :method => :simple, :username => ldap_user, :password => ldap_password }) unless ldap_user.blank? && ldap_password.blank?
    Net::LDAP.new options
  end

  def get_user_attributes_from_ldap_entry(entry)
    custom_field_values = {}
    custom_attributes.each do |custom_field_id, ldap_attr_name|
      custom_field_values[custom_field_id] = AuthSourceLdap.get_attr(entry, ldap_attr_name)
    end

    {
     :dn => entry.dn,
     :firstname => AuthSourceLdap.get_attr(entry, self.attr_firstname),
     :lastname => AuthSourceLdap.get_attr(entry, self.attr_lastname),
     :mail => AuthSourceLdap.get_attr(entry, self.attr_mail),
     :auth_source_id => self.id,
     :custom_field_values => custom_field_values
    }
  end

  # Return the attributes needed for the LDAP search.  It will only
  # include the user attributes if on-the-fly registration is enabled
  def search_attributes
    if onthefly_register?
      ['dn', self.attr_firstname, self.attr_lastname, self.attr_mail]
    else
      ['dn']
    end
  end

  # Check if a DN (user record) authenticates with the password
  def authenticate_dn(dn, password)
    if dn.present? && password.present?
      initialize_ldap_con(dn, password).bind
    end
  end

  # Get the user's dn and any attributes for them, given their login
  def get_user_dn(login)
    ldap_con = initialize_ldap_con(self.account, self.account_password)
    login_filter = Net::LDAP::Filter.eq( self.attr_login, login ) 
    object_filter = Net::LDAP::Filter.eq( "objectClass", "*" )
    custom_ldap_filter = custom_filter_to_ldap

    if custom_ldap_filter.present?
      search_filters = object_filter & login_filter & custom_ldap_filter
    else
      search_filters = object_filter & login_filter
    end
    attrs = {}
    
    ldap_con.search( :base => self.base_dn, 
                     :filter => search_filters, 
                     :attributes=> search_attributes) do |entry|

      if onthefly_register?
        attrs = get_user_attributes_from_ldap_entry(entry)
      else
        attrs = {:dn => entry.dn}
      end

      logger.debug "DN found for #{login}: #{attrs[:dn]}" if logger && logger.debug?
    end

    attrs
  end

  def custom_filter_to_ldap
    return nil unless custom_filter.present?
    
    begin
      return Net::LDAP::Filter.construct(custom_filter)
    rescue Net::LDAP::LdapError # Filter syntax error
      logger.debug "LDAP custom filter syntax error for: #{custom_filter}" if logger && logger.debug?
      return nil
    end
  end
  
  def self.get_attr(entry, attr_name)
    if !attr_name.blank?
      entry[attr_name].is_a?(Array) ? entry[attr_name].first : entry[attr_name]
    end
  end
end
