package main

import (
	"log"
	"os"

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

	app.Get("/"+config.APIKey, func(c *fiber.Ctx) error {
		return c.SendString(string(keys))
	})

	log.Fatal(app.ListenTLS(":"+config.Port, config.CertPath, config.KeyPath))
}
