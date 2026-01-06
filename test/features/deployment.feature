# features/deployment.feature
Feature: Card Separator Deployment
  As a DevOps engineer
  I want to deploy the Card Separator application to Kubernetes
  So that users can access the service reliably

  Background:
    Given Kubernetes cluster is available
    And Skaffold is installed

  Scenario: Deploy application to development environment
    When I deploy the application using Skaffold dev profile
    Then the deployment should succeed
    And all pods should be running
    And the backend service should be healthy
    And the frontend service should be accessible

  Scenario: Backend API is functional
    Given the application is deployed
    When I call the health endpoint
    Then the response status should be 200
    And the response should contain "ok"

  Scenario: MinIO storage is accessible
    Given the application is deployed
    When I check MinIO service
    Then MinIO should be running
    And the card-images bucket should exist

  Scenario: Auto-scaling is configured
    Given the application is deployed in production profile
    When I check the HorizontalPodAutoscaler
    Then HPA should be configured for backend
    And min replicas should be 5
    And max replicas should be 20

  Scenario: Frontend can communicate with backend
    Given the application is deployed
    When I access the frontend URL
    Then the page should load successfully
    And I should be able to fetch sets from the API

  Scenario: Database persistence
    Given the application is deployed
    When I sync a card set
    And I restart the backend pod
    Then the synced set data should still be available

  Scenario: Image caching workflow
    Given the application is deployed
    When I request an image through the backend
    Then the image should be downloaded
    And stored in MinIO
    And tracked in the database
    And subsequent requests should serve from cache
