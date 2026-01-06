# features/data_persistence.feature
Feature: Data Persistence and Caching
  As a system administrator
  I want to ensure data persists across restarts
  So that users don't lose their data

  Background:
    Given the application is deployed via Skaffold
    And all services are healthy

  Scenario: Database persists after backend restart
    Given I sync card sets via API
    And I verify sets exist in database
    When I restart the backend pod
    And I wait for the backend to be ready
    Then the sets should still exist in database
    And I should be able to query the sets

  Scenario: MinIO storage persists after restart
    Given I have cached images in MinIO
    When I restart the MinIO pod
    And I wait for MinIO to be ready
    Then the images should still exist in MinIO
    And I should be able to retrieve the images

  Scenario: Cache statistics reflect actual data
    Given I sync 3 card sets
    And I cache 10 images
    When I call the cache stats endpoint
    Then the total sets should be at least 3
    And the total images should be at least 10
    And the image counts should show distribution across sizes

  Scenario: Image caching reduces download time
    Given I request an image for the first time
    And I record the response time as "initial"
    When I request the same image a second time
    And I record the response time as "cached"
    Then the cached response time should be faster than initial
    And the cached response time should be under 200ms

  Scenario: Database handles concurrent writes
    When I sync multiple sets concurrently
    Then all sets should be stored without conflicts
    And I should be able to query all sets

  Scenario: SQLite WAL mode is enabled
    Given the backend is running
    When I check the database configuration
    Then WAL mode should be enabled
    And the database should support concurrent reads

  Scenario: Image versioning and updates
    Given I have cached an image with URL "https://optcgapi.com/images/OP01-001.jpg"
    When the source image is updated
    And I request the image after cache expiry
    Then the new version should be downloaded
    And stored in MinIO with updated timestamp

  Scenario: Database cleanup for old data
    Given I have images cached for 8 days
    When the cleanup process runs
    Then images older than 7 days should be removed
    And recent images should remain

  Scenario: MinIO bucket is created automatically
    Given I delete the card-images bucket
    When I restart the backend
    Then the backend should recreate the bucket
    And images should be stored successfully

  Scenario: Data integrity after full stack restart
    Given I have a complete dataset with sets and images
    When I delete all pods in the namespace
    And I wait for all pods to restart
    Then all data should be intact
    And the application should function normally
