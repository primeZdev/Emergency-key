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

	var certPath, keyPath string
	certPath = "/etc/letsencrypt/live/" + domain + "/fullchain.pem"
	keyPath = "/etc/letsencrypt/live/" + domain + "/privkey.pem"

	return &Config{
		Port:     port,
		APIKey:   apiKey,
		Domain:   domain,
		CertPath: certPath,
		KeyPath:  keyPath,
	}
}
