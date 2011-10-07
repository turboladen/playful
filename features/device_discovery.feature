Feature: Device discovery
  As a device control point, I want to be able to discover devices
  so that I can use the services those devices provide

  Scenario: A single root device
    Given there's at least 1 root device in my network
    When I come online
    Then I should discover at least 1 root device
    And the location of that device should match my fake device's location
