# features/api_endpoints.feature
Feature: Backend API Endpoints
  As a frontend application
  I want to interact with the backend API
  So that I can retrieve and manage card data

  Background:
    Given the application is deployed via Skaffold
    And all services are healthy

  Scenario: Health check endpoint returns OK status
    When I call the "/api/health" endpoint
    Then the response status code should be 200
    And the response should contain field "status" with value "ok"
    And the response should contain field "database" with value "ok"
    And the response should contain field "minio" with value "ok"
    And the response should contain field "service" with value "card-separator-backend"

  Scenario: List all cached sets
    When I call the "/api/sets" endpoint
    Then the response status code should be 200
    And the response should be a JSON array
    And each set should have fields "id", "name", "release_date"

  Scenario: Sync sets from external API
    When I POST to the "/api/sets/sync" endpoint
    Then the response status code should be 200
    And the response should contain field "synced_sets"
    And the "synced_sets" field should be greater than 0

  Scenario: Get cards for a specific set
    Given I have synced sets
    When I call the "/api/sets/OP-01/cards" endpoint
    Then the response status code should be 200
    And the response should be a JSON array
    And each card should have fields "id", "name", "color", "type", "rarity"

  Scenario: Search cards by color
    Given I have synced sets
    When I call the "/api/cards?color=Red" endpoint
    Then the response status code should be 200
    And the response should be a JSON array
    And all cards should have color "Red"

  Scenario: Search cards by type
    Given I have synced sets
    When I call the "/api/cards?type=Leader" endpoint
    Then the response status code should be 200
    And the response should be a JSON array
    And all cards should have type "Leader"

  Scenario: Search cards by rarity
    Given I have synced sets
    When I call the "/api/cards?rarity=SR" endpoint
    Then the response status code should be 200
    And the response should be a JSON array
    And all cards should have rarity "SR"

  Scenario: Get image proxy with thumbnail size
    Given I have synced sets
    When I request an image with size "thumbnail" and URL "https://optcgapi.com/images/OP01-001.jpg"
    Then the response status code should be 200
    And the response content type should be "image"
    And the image size should be less than 50KB

  Scenario: Get image proxy with medium size
    Given I have synced sets
    When I request an image with size "medium" and URL "https://optcgapi.com/images/OP01-001.jpg"
    Then the response status code should be 200
    And the response content type should be "image"
    And the image size should be less than 100KB

  Scenario: Get image proxy with full size
    Given I have synced sets
    When I request an image with size "full" and URL "https://optcgapi.com/images/OP01-001.jpg"
    Then the response status code should be 200
    And the response content type should be "image"
    And the image size should be less than 200KB

  Scenario: Get all image sizes for a URL
    Given I have synced sets
    When I call the "/api/images?url=https://optcgapi.com/images/OP01-001.jpg" endpoint
    Then the response status code should be 200
    And the response should contain URLs for "thumbnail", "medium", "full", and "original" sizes

  Scenario: Cache statistics endpoint
    Given I have synced sets and images
    When I call the "/api/cache/stats" endpoint
    Then the response status code should be 200
    And the response should contain field "total_sets"
    And the response should contain field "total_cards"
    And the response should contain field "total_images"
    And the response should contain field "image_counts"

  Scenario: Sync specific set cards
    When I POST to the "/api/sets/OP-01/sync" endpoint
    Then the response status code should be 200
    And cards should be available for set "OP-01"

  Scenario: Invalid endpoint returns 404
    When I call the "/api/invalid-endpoint" endpoint
    Then the response status code should be 404

  Scenario: CORS headers are present
    When I call the "/api/health" endpoint with OPTIONS method
    Then the response should contain CORS headers
    And the "Access-Control-Allow-Origin" header should be "*"
