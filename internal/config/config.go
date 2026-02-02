package config

import (
	"log"
	"os"

	"github.com/joho/godotenv"
)

type Config struct {
	Port     string
	APIKey   string
	Domain   string
	CertPath string
	KeyPath  string
}

// LoadConfig loads all values from .env
func LoadConfig() *Config {
	err := godotenv.Load()
	if err != nil {
		log.Fatalf("Error loading .env file: %v", err)
	}

	port := os.Getenv("PORT")
	apiKey := os.Getenv("API_KEY")
	domain := os.Getenv("DOMAIN")

	return &Config{
		Port:   port,
		APIKey: apiKey,
		Domain: domain,
	}
}
