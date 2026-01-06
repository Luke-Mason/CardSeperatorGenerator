package main

import (
	"card-separator/config"
	"card-separator/database"
	"card-separator/handlers"
	"card-separator/services"
	"card-separator/storage"
	"context"
	"encoding/json"
	"log"
	"net/http"
	"time"

	"github.com/gorilla/mux"
	"github.com/joho/godotenv"
	"github.com/rs/cors"
)

func main() {
	log.Println("🚀 Starting Card Separator Backend...")

	// Load .env file if it exists (optional, will use environment variables or defaults)
	_ = godotenv.Load()

	// Load configuration
	cfg := config.Load()
	log.Printf("📝 Configuration loaded")
	log.Printf("   - Port: %s", cfg.Port)
	log.Printf("   - Database: %s", cfg.DatabasePath)
	log.Printf("   - MinIO: %s", cfg.MinIOEndpoint)

	// Initialize database
	db, err := database.NewDB(cfg.DatabasePath)
	if err != nil {
		log.Fatalf("❌ Failed to initialize database: %v", err)
	}
	defer db.Close()

	if err := db.Initialize(); err != nil {
		log.Fatalf("❌ Failed to initialize schema: %v", err)
	}
	log.Println("✅ Database initialized")

	// Initialize MinIO storage
	minioStorage, err := storage.NewMinIOStorage(
		cfg.MinIOEndpoint,
		cfg.MinIOAccessKey,
		cfg.MinIOSecretKey,
		cfg.MinIOBucket,
		cfg.MinIORegion,
		cfg.MinIOUseSSL,
	)
	if err != nil {
		log.Fatalf("❌ Failed to initialize MinIO: %v", err)
	}
	log.Println("✅ MinIO storage initialized")

	// Initialize services
	imageService := services.NewImageService(db, minioStorage, cfg.ImageSizes)
	setSyncService := services.NewSetSyncService(db)
	cardSyncService := services.NewCardSyncService(db)
	log.Println("✅ Services initialized")

	// Auto-sync on startup
	if cfg.AutoSyncOnStartup {
		log.Println("🔄 Running initial set sync...")
		if count, err := setSyncService.SyncAllSets(); err != nil {
			log.Printf("⚠️  Initial sync failed: %v", err)
		} else {
			log.Printf("✅ Synced %d sets on startup", count)
		}
	}

	// Start background sync worker
	setSyncService.StartAutoSync(cfg.SetSyncInterval)

	// Initialize handlers
	imageHandler := handlers.NewImageHandler(imageService)
	setHandler := handlers.NewSetHandler(db, setSyncService)
	cardHandler := handlers.NewCardHandler(db, cardSyncService)
	log.Println("✅ Handlers initialized")

	// Setup router
	r := mux.NewRouter()
	api := r.PathPrefix("/api").Subrouter()

	// Health endpoint
	api.HandleFunc("/health", handleHealth(db, minioStorage)).Methods("GET")

	// Image endpoints
	api.HandleFunc("/images/{size}", imageHandler.GetImage).Methods("GET")
	api.HandleFunc("/images", imageHandler.GetAllSizes).Methods("GET")

	// Set endpoints
	api.HandleFunc("/sets", setHandler.ListSets).Methods("GET")
	api.HandleFunc("/sets/sync", setHandler.SyncSets).Methods("POST")

	// Card endpoints
	api.HandleFunc("/cards", cardHandler.SearchCards).Methods("GET")
	api.HandleFunc("/sets/{set_id}/cards", cardHandler.GetSetCards).Methods("GET")
	api.HandleFunc("/sets/{set_id}/sync", cardHandler.SyncSetCards).Methods("POST")

	// Cache stats endpoint
	api.HandleFunc("/cache/stats", handleCacheStats(db)).Methods("GET")

	// CORS configuration
	corsHandler := cors.New(cors.Options{
		AllowedOrigins:   []string{"*"}, // TODO: Restrict in production
		AllowedMethods:   []string{"GET", "POST", "OPTIONS"},
		AllowedHeaders:   []string{"*"},
		AllowCredentials: true,
		MaxAge:           86400,
	}).Handler(r)

	// Start server
	port := ":" + cfg.Port
	log.Printf("🌐 Server starting on port %s", cfg.Port)
	log.Println("📡 API Endpoints:")
	log.Println("   - GET  /api/health")
	log.Println("   - GET  /api/images/{size}?url=...")
	log.Println("   - GET  /api/images?url=...")
	log.Println("   - GET  /api/sets")
	log.Println("   - POST /api/sets/sync")
	log.Println("   - GET  /api/sets/{set_id}/cards")
	log.Println("   - POST /api/sets/{set_id}/sync")
	log.Println("   - GET  /api/cards?color=&type=&rarity=")
	log.Println("   - GET  /api/cache/stats")

	srv := &http.Server{
		Addr:         port,
		Handler:      corsHandler,
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 30 * time.Second,
		IdleTimeout:  120 * time.Second,
	}

	log.Printf("✅ Server ready! Listening on %s", port)
	if err := srv.ListenAndServe(); err != nil {
		log.Fatalf("❌ Server failed: %v", err)
	}
}

// handleHealth provides a health check endpoint
func handleHealth(db *database.DB, storage *storage.MinIOStorage) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		health := map[string]interface{}{
			"status":    "ok",
			"timestamp": time.Now().Format(time.RFC3339),
			"service":   "card-separator-backend",
		}

		// Check database
		if err := db.Ping(); err != nil {
			health["status"] = "degraded"
			health["database"] = "error: " + err.Error()
		} else {
			health["database"] = "ok"
		}

		// Check MinIO
		ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()
		if err := storage.Ping(ctx); err != nil {
			health["status"] = "degraded"
			health["minio"] = "error: " + err.Error()
		} else {
			health["minio"] = "ok"
		}

		w.Header().Set("Content-Type", "application/json")
		if health["status"] == "degraded" {
			w.WriteHeader(http.StatusServiceUnavailable)
		}
		json.NewEncoder(w).Encode(health)
	}
}

// handleCacheStats provides cache statistics
func handleCacheStats(db *database.DB) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		stats, err := db.GetCacheStats()
		if err != nil {
			http.Error(w, "Failed to get cache stats", http.StatusInternalServerError)
			return
		}

		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(stats)
	}
}
