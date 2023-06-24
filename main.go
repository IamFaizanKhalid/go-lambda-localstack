package main

import (
	"encoding/json"
	"log"
	"net/http"
	"time"

	"github.com/apex/gateway"
	"github.com/gomodule/redigo/redis"
)

var cache redis.Conn

func init() {
	//connectionUrl := os.Getenv("REDIS_CONN_URL")
	connectionUrl := "redis://:@my-cache:6379/0"

	var err error
	cache, err = redis.DialURL(connectionUrl, redis.DialUseTLS(false))
	if err != nil {
		log.Fatalln(err)
	}
}

func main() {
	mux := http.NewServeMux()
	mux.HandleFunc("/", ping)

	err := gateway.ListenAndServe("", mux)
	if err != nil {
		log.Fatalln(err)
	}
}

func ping(w http.ResponseWriter, _ *http.Request) {
	resp := &response{
		Timestamp: time.Now().UTC(),
	}

	body, _ := json.Marshal(resp)

	_, _ = cache.Do("SET", "lastResponse", body)

	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.WriteHeader(http.StatusOK)
	w.Write(body)
}

type response struct {
	Timestamp time.Time `json:"timestamp"`
}
