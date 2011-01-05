require File.dirname(__FILE__) + '/../../test_helper'

class RemoteHsbcSecureEpaymentTest < Test::Unit::TestCase
  
  def setup
    ActiveMerchant::Billing::Base.mode = :test

    @gateway = HsbcSecureEpaymentsGateway.new(fixtures(:hsbc_secure_epayment))
    
    @amount = 100
    @credit_card = credit_card('4000100011112224')
    @declined_card = credit_card('4000300011112220')
    
    @options = { 
      :order_id => '1',
      :billing_address => address,
      :description => 'Store Purchase',
      :currency => "GBP"
    }
  end
  
  def test_successful_purchase
    ActiveMerchant::Billing::HsbcSecureEpaymentsGateway::test_mode = "Y"

    assert response = @gateway.purchase(@amount, @credit_card, @options)
    assert_success response
    assert_equal 'Approved.', response.message
    assert_equal 1, response.params["return_code"]
    assert_match /[a-z0-9]{8}-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{12}/, response.authorization
    assert_match /[0-9]{4,6}/, response.params["auth_code"]
  end

  def test_unsuccessful_purchase
    ActiveMerchant::Billing::HsbcSecureEpaymentsGateway::test_mode = "N"
    
    assert response = @gateway.purchase(@amount, @declined_card, @options)
    assert_failure response
    assert_equal 'Declined (General).', response.message

    assert_not_equal 1, response.params["return_code"]
    assert_match /[a-z0-9]{8}-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{12}/, response.authorization
    assert_nil response.params["auth_code"]
  end
  
  def test_authorize_and_capture
    assert auth = @gateway.authorize(@amount, @credit_card, @options)
    assert_success auth
    assert_equal 'Approved.', auth.message
    assert auth.authorization
    assert capture = @gateway.capture(@amount, auth.authorization, @options)
    assert_success capture
  end
  
  def test_failed_capture
    assert response = @gateway.capture(@amount, '')
    assert_failure response
    assert_equal 'REPLACE WITH GATEWAY FAILURE MESSAGE', response.message
  end
  
  def test_invalid_login
    gateway = HsbcSecureEpaymentsGateway.new(
                :login => 'login',
                :password => 'password',
                :client_id => 'client_id'
              )
    assert response = gateway.purchase(@amount, @credit_card, @options)
    assert_failure response
    assert_equal 'System error', response.message
  end
end
