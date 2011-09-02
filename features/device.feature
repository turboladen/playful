Feature: Controlled Device
  As a UPnP device user
  I want to use the device that offers some service
  So that I can consume that service

  Scenario: Device added to the network
    Given I have a non-local IP address
    And a UDP port on that IP is free
    When I start my device on that IP address and port
    Then the device multicasts a discovery message

  @negative
  Scenario: Device startup without an IP
    Given I don't have an IP address
    When I start the device
    Then I get an error message saying I don't have an IP address

  Scenario: Device startup with a local-link IP
    Given I have a local-link IP address
    When I start the device
    Then the device starts running normally

