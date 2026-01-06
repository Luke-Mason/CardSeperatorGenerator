package test

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os/exec"
	"strings"
	"testing"
	"time"

	"github.com/cucumber/godog"
	"github.com/gruntwork-io/terratest/modules/k8s"
)

type APITestContext struct {
	t                *testing.T
	kubectlOptions   *k8s.KubectlOptions
	namespace        string
	httpResponse     *http.Response
	responseBody     []byte
	imageSize        int64
	skaffoldDeployed bool
}

func TestAPIEndpoints(t *testing.T) {
	suite := godog.TestSuite{
		ScenarioInitializer: InitializeAPIScenario,
		Options: &godog.Options{
			Format:   "pretty",
			Paths:    []string{"features/api_endpoints.feature"},
			TestingT: t,
		},
	}

	if suite.Run() != 0 {
		t.Fatal("non-zero status returned, failed to run API feature tests")
	}
}

func InitializeAPIScenario(ctx *godog.ScenarioContext) {
	apiCtx := &APITestContext{
		namespace: "default",
	}

	ctx.Before(func(ctx context.Context, sc *godog.Scenario) (context.Context, error) {
		apiCtx.kubectlOptions = k8s.NewKubectlOptions("", "", apiCtx.namespace)
		return ctx, nil
	})

	// Step definitions
	ctx.Step(`^the application is deployed via Skaffold$`, apiCtx.deployViaSkaffold)
	ctx.Step(`^all services are healthy$`, apiCtx.allServicesAreHealthy)
	ctx.Step(`^I call the "([^"]*)" endpoint$`, apiCtx.callEndpoint)
	ctx.Step(`^I POST to the "([^"]*)" endpoint$`, apiCtx.postToEndpoint)
	ctx.Step(`^the response status code should be (\d+)$`, apiCtx.responseStatusShouldBe)
	ctx.Step(`^the response should contain field "([^"]*)" with value "([^"]*)"$`, apiCtx.responseShouldContainField)
	ctx.Step(`^the response should be a JSON array$`, apiCtx.responseShouldBeJSONArray)
	ctx.Step(`^each set should have fields "([^"]*)", "([^"]*)", "([^"]*)"$`, apiCtx.eachSetShouldHaveFields)
	ctx.Step(`^I have synced sets$`, apiCtx.haveSyncedSets)
	ctx.Step(`^each card should have fields "([^"]*)", "([^"]*)", "([^"]*)", "([^"]*)", "([^"]*)"$`, apiCtx.eachCardShouldHaveFields)
	ctx.Step(`^all cards should have color "([^"]*)"$`, apiCtx.allCardsShouldHaveColor)
	ctx.Step(`^all cards should have type "([^"]*)"$`, apiCtx.allCardsShouldHaveType)
	ctx.Step(`^all cards should have rarity "([^"]*)"$`, apiCtx.allCardsShouldHaveRarity)
	ctx.Step(`^I request an image with size "([^"]*)" and URL "([^"]*)"$`, apiCtx.requestImageWithSizeAndURL)
	ctx.Step(`^the response content type should be "([^"]*)"$`, apiCtx.responseContentTypeShouldBe)
	ctx.Step(`^the image size should be less than (\d+)KB$`, apiCtx.imageSizeShouldBeLessThan)
	ctx.Step(`^the response should contain URLs for "([^"]*)", "([^"]*)", "([^"]*)", and "([^"]*)" sizes$`, apiCtx.responseShouldContainImageURLs)
	ctx.Step(`^I have synced sets and images$`, apiCtx.haveSyncedSetsAndImages)
	ctx.Step(`^the response should contain field "([^"]*)"$`, apiCtx.responseShouldContainFieldName)
	ctx.Step(`^the "([^"]*)" field should be greater than (\d+)$`, apiCtx.fieldShouldBeGreaterThan)
	ctx.Step(`^cards should be available for set "([^"]*)"$`, apiCtx.cardsShouldBeAvailableForSet)
	ctx.Step(`^I call the "([^"]*)" endpoint with OPTIONS method$`, apiCtx.callEndpointWithOptions)
	ctx.Step(`^the response should contain CORS headers$`, apiCtx.responseShouldContainCORSHeaders)
	ctx.Step(`^the "([^"]*)" header should be "([^"]*)"$`, apiCtx.headerShouldBe)
}

func (a *APITestContext) deployViaSkaffold() error {
	if a.skaffoldDeployed {
		return nil
	}

	// Check if already deployed
	cmd := exec.Command("kubectl", "get", "deployment", "card-separator-backend", "-n", a.namespace)
	if err := cmd.Run(); err == nil {
		a.skaffoldDeployed = true
		return nil
	}

	// Deploy with Skaffold
	deployCmd := exec.Command("skaffold", "run", "-p", "dev")
	if err := deployCmd.Run(); err != nil {
		return fmt.Errorf("failed to deploy with Skaffold: %w", err)
	}

	// Wait for deployment to be ready
	time.Sleep(60 * time.Second)
	a.skaffoldDeployed = true
	return nil
}

func (a *APITestContext) allServicesAreHealthy() error {
	tunnel := k8s.NewTunnel(a.kubectlOptions, k8s.ResourceTypeService, "card-separator-backend", 0, 8080)
	defer tunnel.Close()
	tunnel.ForwardPort(a.t)

	endpoint := fmt.Sprintf("http://%s/api/health", tunnel.Endpoint())
	resp, err := http.Get(endpoint)
	if err != nil {
		return fmt.Errorf("health check failed: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("health check returned status %d", resp.StatusCode)
	}

	return nil
}

func (a *APITestContext) callEndpoint(endpoint string) error {
	tunnel := k8s.NewTunnel(a.kubectlOptions, k8s.ResourceTypeService, "card-separator-backend", 0, 8080)
	defer tunnel.Close()
	tunnel.ForwardPort(a.t)

	url := fmt.Sprintf("http://%s%s", tunnel.Endpoint(), endpoint)
	resp, err := http.Get(url)
	if err != nil {
		return fmt.Errorf("failed to call endpoint: %w", err)
	}

	body, err := io.ReadAll(resp.Body)
	resp.Body.Close()
	if err != nil {
		return fmt.Errorf("failed to read response body: %w", err)
	}

	a.httpResponse = resp
	a.responseBody = body
	return nil
}

func (a *APITestContext) postToEndpoint(endpoint string) error {
	tunnel := k8s.NewTunnel(a.kubectlOptions, k8s.ResourceTypeService, "card-separator-backend", 0, 8080)
	defer tunnel.Close()
	tunnel.ForwardPort(a.t)

	url := fmt.Sprintf("http://%s%s", tunnel.Endpoint(), endpoint)
	resp, err := http.Post(url, "application/json", nil)
	if err != nil {
		return fmt.Errorf("failed to POST to endpoint: %w", err)
	}

	body, err := io.ReadAll(resp.Body)
	resp.Body.Close()
	if err != nil {
		return fmt.Errorf("failed to read response body: %w", err)
	}

	a.httpResponse = resp
	a.responseBody = body
	return nil
}

func (a *APITestContext) responseStatusShouldBe(expectedStatus int) error {
	if a.httpResponse.StatusCode != expectedStatus {
		return fmt.Errorf("expected status %d, got %d", expectedStatus, a.httpResponse.StatusCode)
	}
	return nil
}

func (a *APITestContext) responseShouldContainField(field, value string) error {
	var data map[string]interface{}
	if err := json.Unmarshal(a.responseBody, &data); err != nil {
		return fmt.Errorf("failed to parse JSON: %w", err)
	}

	fieldValue, ok := data[field]
	if !ok {
		return fmt.Errorf("field '%s' not found in response", field)
	}

	if fmt.Sprintf("%v", fieldValue) != value {
		return fmt.Errorf("expected field '%s' to be '%s', got '%v'", field, value, fieldValue)
	}

	return nil
}

func (a *APITestContext) responseShouldBeJSONArray() error {
	var data []interface{}
	if err := json.Unmarshal(a.responseBody, &data); err != nil {
		return fmt.Errorf("response is not a JSON array: %w", err)
	}
	return nil
}

func (a *APITestContext) eachSetShouldHaveFields(field1, field2, field3 string) error {
	var data []map[string]interface{}
	if err := json.Unmarshal(a.responseBody, &data); err != nil {
		return fmt.Errorf("failed to parse JSON array: %w", err)
	}

	if len(data) == 0 {
		return fmt.Errorf("response array is empty")
	}

	for _, item := range data {
		if _, ok := item[field1]; !ok {
			return fmt.Errorf("field '%s' not found in set", field1)
		}
		if _, ok := item[field2]; !ok {
			return fmt.Errorf("field '%s' not found in set", field2)
		}
		if _, ok := item[field3]; !ok {
			return fmt.Errorf("field '%s' not found in set", field3)
		}
	}

	return nil
}

func (a *APITestContext) haveSyncedSets() error {
	return a.postToEndpoint("/api/sets/sync")
}

func (a *APITestContext) eachCardShouldHaveFields(field1, field2, field3, field4, field5 string) error {
	var data []map[string]interface{}
	if err := json.Unmarshal(a.responseBody, &data); err != nil {
		return fmt.Errorf("failed to parse JSON array: %w", err)
	}

	if len(data) == 0 {
		return nil // Empty result is acceptable
	}

	for _, item := range data {
		fields := []string{field1, field2, field3, field4, field5}
		for _, field := range fields {
			if _, ok := item[field]; !ok {
				return fmt.Errorf("field '%s' not found in card", field)
			}
		}
	}

	return nil
}

func (a *APITestContext) allCardsShouldHaveColor(color string) error {
	var data []map[string]interface{}
	if err := json.Unmarshal(a.responseBody, &data); err != nil {
		return fmt.Errorf("failed to parse JSON array: %w", err)
	}

	for _, card := range data {
		cardColor := fmt.Sprintf("%v", card["color"])
		if cardColor != color {
			return fmt.Errorf("expected card color '%s', got '%s'", color, cardColor)
		}
	}

	return nil
}

func (a *APITestContext) allCardsShouldHaveType(cardType string) error {
	var data []map[string]interface{}
	if err := json.Unmarshal(a.responseBody, &data); err != nil {
		return fmt.Errorf("failed to parse JSON array: %w", err)
	}

	for _, card := range data {
		cType := fmt.Sprintf("%v", card["type"])
		if cType != cardType {
			return fmt.Errorf("expected card type '%s', got '%s'", cardType, cType)
		}
	}

	return nil
}

func (a *APITestContext) allCardsShouldHaveRarity(rarity string) error {
	var data []map[string]interface{}
	if err := json.Unmarshal(a.responseBody, &data); err != nil {
		return fmt.Errorf("failed to parse JSON array: %w", err)
	}

	for _, card := range data {
		cardRarity := fmt.Sprintf("%v", card["rarity"])
		if cardRarity != rarity {
			return fmt.Errorf("expected card rarity '%s', got '%s'", rarity, cardRarity)
		}
	}

	return nil
}

func (a *APITestContext) requestImageWithSizeAndURL(size, imageURL string) error {
	tunnel := k8s.NewTunnel(a.kubectlOptions, k8s.ResourceTypeService, "card-separator-backend", 0, 8080)
	defer tunnel.Close()
	tunnel.ForwardPort(a.t)

	url := fmt.Sprintf("http://%s/api/images/%s?url=%s", tunnel.Endpoint(), size, imageURL)
	resp, err := http.Get(url)
	if err != nil {
		return fmt.Errorf("failed to request image: %w", err)
	}

	body, err := io.ReadAll(resp.Body)
	resp.Body.Close()
	if err != nil {
		return fmt.Errorf("failed to read response body: %w", err)
	}

	a.httpResponse = resp
	a.responseBody = body
	a.imageSize = int64(len(body))
	return nil
}

func (a *APITestContext) responseContentTypeShouldBe(contentType string) error {
	actualType := a.httpResponse.Header.Get("Content-Type")
	if !strings.Contains(actualType, contentType) {
		return fmt.Errorf("expected content type to contain '%s', got '%s'", contentType, actualType)
	}
	return nil
}

func (a *APITestContext) imageSizeShouldBeLessThan(maxKB int) error {
	maxBytes := int64(maxKB * 1024)
	if a.imageSize >= maxBytes {
		return fmt.Errorf("image size %d bytes exceeds maximum %d bytes", a.imageSize, maxBytes)
	}
	return nil
}

func (a *APITestContext) responseShouldContainImageURLs(size1, size2, size3, size4 string) error {
	var data map[string]interface{}
	if err := json.Unmarshal(a.responseBody, &data); err != nil {
		return fmt.Errorf("failed to parse JSON: %w", err)
	}

	sizes := []string{size1, size2, size3, size4}
	for _, size := range sizes {
		if _, ok := data[size]; !ok {
			return fmt.Errorf("size '%s' not found in response", size)
		}
	}

	return nil
}

func (a *APITestContext) haveSyncedSetsAndImages() error {
	if err := a.haveSyncedSets(); err != nil {
		return err
	}

	// Request an image to cache it
	return a.requestImageWithSizeAndURL("thumbnail", "https://optcgapi.com/images/OP01-001.jpg")
}

func (a *APITestContext) responseShouldContainFieldName(field string) error {
	var data map[string]interface{}
	if err := json.Unmarshal(a.responseBody, &data); err != nil {
		return fmt.Errorf("failed to parse JSON: %w", err)
	}

	if _, ok := data[field]; !ok {
		return fmt.Errorf("field '%s' not found in response", field)
	}

	return nil
}

func (a *APITestContext) fieldShouldBeGreaterThan(field string, minValue int) error {
	var data map[string]interface{}
	if err := json.Unmarshal(a.responseBody, &data); err != nil {
		return fmt.Errorf("failed to parse JSON: %w", err)
	}

	value, ok := data[field]
	if !ok {
		return fmt.Errorf("field '%s' not found in response", field)
	}

	// Try to convert to number
	var numValue float64
	switch v := value.(type) {
	case float64:
		numValue = v
	case int:
		numValue = float64(v)
	default:
		return fmt.Errorf("field '%s' is not a number", field)
	}

	if numValue <= float64(minValue) {
		return fmt.Errorf("expected field '%s' to be greater than %d, got %f", field, minValue, numValue)
	}

	return nil
}

func (a *APITestContext) cardsShouldBeAvailableForSet(setID string) error {
	tunnel := k8s.NewTunnel(a.kubectlOptions, k8s.ResourceTypeService, "card-separator-backend", 0, 8080)
	defer tunnel.Close()
	tunnel.ForwardPort(a.t)

	url := fmt.Sprintf("http://%s/api/sets/%s/cards", tunnel.Endpoint(), setID)
	resp, err := http.Get(url)
	if err != nil {
		return fmt.Errorf("failed to get cards for set: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("failed to get cards, status: %d", resp.StatusCode)
	}

	return nil
}

func (a *APITestContext) callEndpointWithOptions(endpoint string) error {
	tunnel := k8s.NewTunnel(a.kubectlOptions, k8s.ResourceTypeService, "card-separator-backend", 0, 8080)
	defer tunnel.Close()
	tunnel.ForwardPort(a.t)

	url := fmt.Sprintf("http://%s%s", tunnel.Endpoint(), endpoint)
	req, err := http.NewRequest("OPTIONS", url, nil)
	if err != nil {
		return fmt.Errorf("failed to create OPTIONS request: %w", err)
	}

	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		return fmt.Errorf("failed to execute OPTIONS request: %w", err)
	}
	defer resp.Body.Close()

	a.httpResponse = resp
	return nil
}

func (a *APITestContext) responseShouldContainCORSHeaders() error {
	corsHeader := a.httpResponse.Header.Get("Access-Control-Allow-Origin")
	if corsHeader == "" {
		return fmt.Errorf("CORS header 'Access-Control-Allow-Origin' not found")
	}
	return nil
}

func (a *APITestContext) headerShouldBe(header, expectedValue string) error {
	actualValue := a.httpResponse.Header.Get(header)
	if actualValue != expectedValue {
		return fmt.Errorf("expected header '%s' to be '%s', got '%s'", header, expectedValue, actualValue)
	}
	return nil
}
