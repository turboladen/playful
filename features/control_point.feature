Feature: Control Point
  As a consumer of UPnP devices and services
  I want to act as a UPnP control point
  So that I can control the devices and services that fulfill my needs

  Scenario: Search for devices on startup
    Given I have a non-local IP address
    And a UDP port on that IP is free
    When I create my control point
    And tell it to find all root devices
    And tell it to find all services
    Then it gets a list of root devices
    And it gets a list of services
