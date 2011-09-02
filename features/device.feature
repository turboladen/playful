Feature: Controlled Device
  As a UPnP device user
  I want to use the device that offers some service
  So that I can consume that service

  @negative
  Scenario: Device startup without an IP
    Given I don't have an IP address
    When I start the device
    Then I get an error message saying I don't have an IP address

  Scenario: Device startup with a local-link IP
    Given I have a local-link IP address
    When I start the device
    Then the device starts running normally

