package main

import (
	"bytes"
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"log"
	"net/http"
	"net/http/httputil"
	"net/url"
)

var (
	listenAddr = flag.String("listen", ":11435", "address to listen on")
	ollamaAddr = flag.String("ollama", "http://localhost:11434", "ollama base URL")
)

func main() {
	flag.Parse()

	target, err := url.Parse(*ollamaAddr)
	if err != nil {
		log.Fatalf("invalid ollama address: %v", err)
	}

	proxy := httputil.NewSingleHostReverseProxy(target)
	proxy.Director = func(req *http.Request) {
		req.URL.Scheme = target.Scheme
		req.URL.Host = target.Host
		req.Host = target.Host

		if req.Body == nil || req.ContentLength == 0 {
			return
		}

		body, err := io.ReadAll(req.Body)
		if err != nil {
			log.Printf("failed to read request body: %v", err)
			return
		}

		var payload map[string]any
		if err := json.Unmarshal(body, &payload); err != nil {
			// not JSON, pass through as-is
			req.Body = io.NopCloser(bytes.NewReader(body))
			return
		}

		payload["reasoning_effort"] = "none"

		modified, err := json.Marshal(payload)

		fmt.Printf("payload: %+v\n", payload)
		fmt.Printf("req.URL: %+v\n", req.URL)

		if err != nil {
			log.Printf("failed to marshal modified payload: %v", err)
			req.Body = io.NopCloser(bytes.NewReader(body))
			return
		}

		req.Body = io.NopCloser(bytes.NewReader(modified))
		req.ContentLength = int64(len(modified))
	}

	log.Printf("proxying %s -> %s (injecting think: false)", *listenAddr, *ollamaAddr)
	if err := http.ListenAndServe(*listenAddr, proxy); err != nil {
		log.Fatalf("server error: %v", err)
	}
}
