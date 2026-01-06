# features/performance.feature
Feature: Performance and Scalability
  As a DevOps engineer
  I want to ensure the application performs well under load
  So that users have a fast experience

  Background:
    Given the application is deployed via Skaffold
    And all services are healthy

  Scenario: Health check response time
    When I call the health endpoint 10 times
    Then the average response time should be under 100ms
    And all requests should return 200 status

  Scenario: API response times are acceptable
    Given I have synced sets
    When I call the "/api/sets" endpoint 10 times
    Then the average response time should be under 200ms
    And the 95th percentile should be under 300ms

  Scenario: Image proxy performance with caching
    Given I request an image that is not cached
    And the initial request takes X milliseconds
    When I request the same image 10 times
    Then the average cached response time should be under 100ms
    And should be significantly faster than the initial request

  Scenario: Concurrent API requests
    When I make 50 concurrent requests to "/api/health"
    Then all requests should complete successfully
    And no request should take longer than 1 second
    And no errors should occur

  Scenario: Large dataset query performance
    Given I have synced 10 card sets with 1000+ cards
    When I query all cards via "/api/cards"
    Then the response time should be under 500ms
    And the response should contain all cards

  Scenario: Database query performance
    Given the database has 10000 cards
    When I search for cards by color
    Then the query should complete in under 100ms
    And results should be accurate

  Scenario: MinIO download performance
    Given I have 100 cached images in MinIO
    When I request 10 random images concurrently
    Then all images should be served in under 2 seconds
    And no request should fail

  Scenario: Frontend page load time
    When I measure the frontend page load time
    Then the page should load in under 2 seconds
    And all static assets should be loaded
    And the page should be interactive

  Scenario: Memory usage is within limits
    Given the backend has been running for 5 minutes
    When I check pod memory usage
    Then memory usage should be under 512MB
    And there should be no memory leaks

  Scenario: CPU usage under normal load
    Given the backend is serving 100 requests per minute
    When I check pod CPU usage
    Then CPU usage should be under 50%
    And the pod should be healthy
