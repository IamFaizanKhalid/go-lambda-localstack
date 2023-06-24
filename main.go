package main

import (
	"encoding/json"
	"log"
	"net/http"

	"github.com/apex/gateway"
	"github.com/go-chi/chi/v5"
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
	r := chi.NewRouter()

	r.HandleFunc("/test/{testId}/request", ping)

	err := gateway.ListenAndServe("", r)
	if err != nil {
		log.Fatalln(err)
	}
}

func ping(w http.ResponseWriter, r *http.Request) {
	resp := &response{
		Id:      chi.URLParam(r, "testId"),
		Message: r.URL.Query().Get("message"),
	}

	body, _ := json.Marshal(resp)

	_, _ = cache.Do("SET", "lastResponse", body)

	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.WriteHeader(http.StatusOK)
	w.Write(body)
}

type response struct {
	Id      string `json:"id"`
	Message string `json:"message"`
}
