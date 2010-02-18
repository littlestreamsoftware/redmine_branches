# Redmine - project management software
# Copyright (C) 2006-2008  Jean-Philippe Lang
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

require File.dirname(__FILE__) + '/../test_helper'

class AuthSourceLdapTest < ActiveSupport::TestCase
  fixtures :auth_sources
  
  def setup
  end
  
  def test_create
    a = AuthSourceLdap.new(:name => 'My LDAP', :host => 'ldap.example.net', :port => 389, :base_dn => 'dc=example,dc=net', :attr_login => 'sAMAccountName')
    assert a.save
  end
  
  def test_should_strip_ldap_attributes
    a = AuthSourceLdap.new(:name => 'My LDAP', :host => 'ldap.example.net', :port => 389, :base_dn => 'dc=example,dc=net', :attr_login => 'sAMAccountName',
                           :attr_firstname => 'givenName ')
    assert a.save
    assert_equal 'givenName', a.reload.attr_firstname
  end

  should_have_and_belong_to_many :groups

  if ldap_configured?
    context '#authenticate' do
      setup do
        @custom_field = UserCustomField.generate!(:name => 'Home directory')

        @auth = AuthSourceLdap.generate!(:name => 'on the fly',
                                         :host => '127.0.0.1',
                                         :port => 389,
                                         :base_dn => 'OU=Person,DC=redmine,DC=org',
                                         :attr_login => 'uid',
                                         :attr_firstname => 'givenName',
                                         :attr_lastname => 'sn',
                                         :attr_mail => 'mail',
                                         :onthefly_register => true,
                                         :custom_attributes => {@custom_field.id.to_s => 'homeDirectory'})


      end

      context 'with a valid LDAP user' do
        should 'return the firstname user attributes' do
          response =  @auth.authenticate('example1','123456')
          assert response
          assert_equal 'Example', response.first[:firstname]
        end

        should 'return the lastname user attributes' do
          response =  @auth.authenticate('example1','123456')
          assert response
          assert_equal 'One', response.first[:lastname]
        end

        should 'return mail user attributes' do
          response =  @auth.authenticate('example1','123456')
          assert response
          assert_equal 'example1@redmine.org', response.first[:mail]
        end

        should 'return custom field attributes from LDAP' do
          response = @auth.authenticate('example1','123456')

          assert response.is_a?(Array), "An array was not returned"
          assert response.first.present?, "No user data returned"

          custom_field_attributes = response.first[:custom_field_values]
          assert custom_field_attributes.is_a?(Hash)
          assert custom_field_attributes.include?(@custom_field.id.to_s), "Custom field wasn't returned"
          assert_equal "/home/example1", custom_field_attributes[@custom_field.id.to_s]
        end
      end

      context 'with an invalid LDAP user' do
        should 'return nil' do
          assert_equal nil, @auth.authenticate('nouser','123456')
        end
      end

      context 'without a login' do
        should 'return nil' do
          assert_equal nil, @auth.authenticate('','123456')
        end
      end

      context 'without a password' do
        should 'return nil' do
          assert_equal nil, @auth.authenticate('edavis','')
        end
      end

      context "using a valid custom filter" do
        setup do
          @auth.update_attributes(:custom_filter => "(& (homeDirectory=*) (sn=O*))")
        end

        should "find a user who authenticates and matches the custom filter" do
          assert_not_nil @auth.authenticate('example1', '123456')
        end

        should "be nil for users who don't match the custom filter" do
          assert_nil @auth.authenticate('edavis', '123456')
        end
      end

      context "using an invalid custom filter" do
        setup do
          # missing )) at the end
          @auth.update_attributes(:custom_filter => "(& (homeDirectory=*) (sn=O*")
        end

        should "skip the custom filter" do
          assert_not_nil @auth.authenticate('example1', '123456')
          assert_not_nil @auth.authenticate('edavis', '123456')
        end
      end

    end
  else
    puts '(Test LDAP server not configured)'
  end
end
