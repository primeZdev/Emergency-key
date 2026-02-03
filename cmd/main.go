package main

import (
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"strings"

	"github.com/gofiber/fiber/v2"
	"github.com/primeZdev/Emergency-key/internal/config"
)

func main() {
	app := fiber.New()

	config := config.LoadConfig()
	keys, err := os.ReadFile("keys.txt")
	if err != nil {
		log.Fatal(err)
	}

	lines := strings.Split(string(keys), "\n")
	var allKeys []string

	for _, line := range lines {
		line = strings.TrimSpace(line)
		if line == "" {
			continue
		}

		if strings.HasPrefix(line, "http://") || strings.HasPrefix(line, "https://") {
			subscriptionContent, err := fetchSubscription(line)
			if err != nil {
				log.Printf("Warning: Could not fetch subscription %s: %v", line, err)
				allKeys = append(allKeys, line)
			} else {
				subKeys := strings.Split(subscriptionContent, "\n")
				for _, key := range subKeys {
					if trimmed := strings.TrimSpace(key); trimmed != "" {
						allKeys = append(allKeys, trimmed)
					}
				}
			}
		} else {
			allKeys = append(allKeys, line)
		}
	}

	content := strings.Join(allKeys, "\n")

	app.Get("/"+config.APIKey, func(c *fiber.Ctx) error {
		return c.SendString(content)
	})

	app.Listen("127.0.0.1:" + config.Port)
}

func fetchSubscription(url string) (string, error) {
	resp, err := http.Get(url)
	if err != nil {
		return "", fmt.Errorf("failed to fetch subscription: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return "", fmt.Errorf("subscription returned status: %s", resp.Status)
	}

	bodyBytes, err := io.ReadAll(resp.Body)
	if err != nil {
		return "", fmt.Errorf("failed to read subscription body: %v", err)
	}

	return string(bodyBytes), nil
}
