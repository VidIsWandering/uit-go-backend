# Makefile for UIT Go Backend

.PHONY: up down restart logs seed test clean help

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

up: ## Start all services in background
	docker compose up -d

down: ## Stop and remove all services
	docker compose down

restart: down up ## Restart all services

logs: ## Follow logs of all services
	docker compose logs -f

seed: ## Seed initial data (User & Drivers)
	chmod +x ./scripts/seed-data.sh
	./scripts/seed-data.sh

test-load: ## Run k6 load test (Spike Test) and push metrics to InfluxDB
	docker run --rm -i \
		-v $(PWD)/tests/k6:/scripts \
		--network host \
		grafana/k6 run --out influxdb=http://localhost:8086/k6 /scripts/spike-test.js

test-stress: ## Run k6 STRESS test (Find Limits) and push metrics to InfluxDB
	docker run --rm -i \
		-v $(PWD)/tests/k6:/scripts \
		--network host \
		grafana/k6 run --out influxdb=http://localhost:8086/k6 /scripts/stress-test.js

test-average: ## Run k6 AVERAGE LOAD test (Stability) and push metrics to InfluxDB
	docker run --rm -i \
		-v $(PWD)/tests/k6:/scripts \
		--network host \
		grafana/k6 run --out influxdb=http://localhost:8086/k6 /scripts/average-load-test.js

clean: ## Remove all containers and volumes
	docker compose down -v

status: ## Check status of containers
	docker compose ps

# ===================================
# Round 2 - VIDEO RECORDING TARGETS
# ===================================
# Các lệnh tối ưu cho quay video demo load testing
# Mỗi test tự động generate token + cooldown sau khi chạy

.PHONY: r2-spike r2-stress r2-cache r2-replica r2-prepare r2-cleanup r2-help

r2-help: ## Huong dan chay test cases Round 2
	@echo =========================================
	@echo   ROUND 2 LOAD TESTING - HUONG DAN
	@echo =========================================
	@echo.
	@echo [SETUP] CAC BUOC THUC HIEN:
	@echo   1. Chuan bi: make r2-prepare
	@echo   2. Mo Grafana: http://localhost:3001 (admin/admin)
	@echo   3. Chon dashboard: UIT Go - Load Test Dashboard
	@echo   4. Time Range: Last 15 minutes ^| Refresh: 5s
	@echo.
	@echo [RUN] CHAY TUNG TEST CASE:
	@echo   - Spike Test (300 VUs):     make r2-spike
	@echo   - Stress Test (500 VUs):    make r2-stress
	@echo   - Cache Test (100 VUs):     make r2-cache
	@echo   - Replica Test (300 VUs):   make r2-replica
	@echo.
	@echo [TIME] THOI GIAN DU KIEN:
	@echo   - Spike:   ~2 phut (50s test + 60s cooldown)
	@echo   - Stress:  ~7 phut (5.5m test + 90s cooldown)
	@echo   - Cache:   ~2 phut (50s test + 45s cooldown)
	@echo   - Replica: ~2 phut (50s test + 45s cooldown)
	@echo.
	@echo [PASS] KET QUA VALIDATION:
	@echo   - Tat ca 4 tests da PASS voi actual metrics
	@echo   - Spike: p95=1.76s, Stress: p95=3.26s
	@echo   - Cache: p95=8ms, Replica: p95=1.30s
	@echo.
	@echo [CLEANUP] KET THUC:
	@echo   - Don dep: make r2-cleanup
	@echo.
	@echo [DOC] Tai lieu: docs/module-a/VIDEO-SCRIPTS.md
	@echo =========================================

r2-prepare: ## [Round 2] Chuan bi moi truong test (rebuild infrastructure)
	@echo [SETUP] Restarting infrastructure with optimized settings...
	docker compose down
	docker compose up -d --scale trip-service=3
	@echo [WAIT] Waiting 60s for system stabilization...
	@powershell -Command "Start-Sleep -Seconds 60"
	@echo.
	@echo [OK] System ready! Open Grafana at http://localhost:3001
	@echo      Dashboard: UIT Go - Load Test Dashboard
	@echo      Time Range: Last 15 minutes ^| Auto Refresh: 5s
	@echo      Run: make r2-help
	@echo.

r2-warmup: ## [Round 2] Warmup Test (50 VUs, 5m) - Chuan bi JVM JIT compilation
	@echo.
	@echo [WARMUP] =======================================
	@echo          JVM WARMUP (5 minutes)
	@echo =========================================
	@echo [WHY]  JVM can warmup 5 phut de JIT compile
	@echo [GAIN] Tang 60%% performance (discovery Round 2)
	@echo [CFG]  50 VUs sustained load trong 5 phut
	@echo =========================================
	@echo.
	@powershell -ExecutionPolicy Bypass -NoProfile -Command "$$token = .\scripts\generate-token.ps1 | Select-Object -Last 1; docker run -i --rm -v \"$$(Get-Location)\tests\k6:/scripts\" --network uit-go-backend_default -e BASE_URL=http://nginx -e API_PREFIX=/api -e ASYNC=1 -e WARMUP_VUS=50 -e WARMUP_DURATION=5m -e PASSENGER_TOKEN=$$token grafana/k6:latest run /scripts/warmup-test.js"
	@echo.
	@echo [OK] Warmup hoan tat - JVM da optimize
	@echo.

r2-spike: ## [Round 2] Spike Test (300 VUs, 50s) - Kiem tra kha nang chiu tai dot bien
	@echo.
	@echo [TEST] =========================================
	@echo        ROUND 2: SPIKE TEST
	@echo =========================================
	@echo [CFG]  Cau hinh: 300 VUs dong thoi trong 50 giay
	@echo [TGT]  Muc tieu: p95 ^< 3.7s, error rate ^< 1%%
	@echo [DATA] Metrics: Latency, throughput, error rate
	@echo [TIME] Thoi luong: ~2 phut (test + recovery)
	@echo =========================================
	@echo.
	@powershell -ExecutionPolicy Bypass -File .\scripts\run-k6-test.ps1 -TestScript "spike-test.js" -TargetVUs 300 -RunLabel "round2-spike-300vus" -Threshold 3700
	@echo.
	@echo [WAIT] Cooldown: 60s...
	@powershell -Command "Start-Sleep -Seconds 60"
	@echo [OK] Ready for next test

r2-stress: ## [Round 2] Stress Test (500 VUs, 5.5m) - Danh gia gioi han he thong
	@echo.
	@echo [TEST] =========================================
	@echo        ROUND 2: STRESS PLATEAU TEST
	@echo =========================================
	@echo [CFG]  Cau hinh: 100-^>500 VUs trong 5.5 phut
	@echo [TGT]  Muc tieu: p95 ^< 6.5s, error ^< 5%%
	@echo [STEP] Giai doan: Ramp-up -^> Plateau -^> Ramp-down
	@echo [TIME] Thoi luong: ~7 phut (5.5m test + 90s recovery)
	@echo =========================================
	@echo.
	@powershell -ExecutionPolicy Bypass -File .\scripts\run-k6-test.ps1 -TestScript "stress-plateau-test.js" -TargetVUs 500 -RunLabel "round2-stress-500vus" -Threshold 6500
	@echo.
	@echo [WAIT] Cooldown: 90s (critical)...
	@powershell -Command "Start-Sleep -Seconds 90"
	@echo [OK] System stabilized

r2-cache: ## [Round 2] Cache Test (100 VUs, 50s) - Do luong hieu qua Redis caching
	@echo.
	@echo [TEST] =========================================
	@echo        ROUND 2: CACHE EFFECTIVENESS TEST
	@echo =========================================
	@echo [CFG]  Cau hinh: 100 VUs trong 50 giay
	@echo [TGT]  Muc tieu: p95 ^< 100ms voi Redis cache
	@echo [DATA] Metrics: Cache hit rate, latency improvement
	@echo [TIME] Thoi luong: ~2 phut (50s test + 45s recovery)
	@echo =========================================
	@echo.
	@powershell -ExecutionPolicy Bypass -File .\scripts\run-k6-test.ps1 -TestScript "spike-test.js" -TargetVUs 100 -RunLabel "round2-cache-100vus" -Threshold 100
	@echo.
	@echo [WAIT] Cooldown: 45s...
	@powershell -Command "Start-Sleep -Seconds 45"
	@echo [OK] Ready for next test

r2-replica: ## [Round 2] Replica Test (300 VUs, 50s) - Kiem tra load balancing 3 replicas
	@echo.
	@echo [TEST] =========================================
	@echo        ROUND 2: LOAD BALANCING TEST
	@echo =========================================
	@echo [CFG]  Cau hinh: 300 VUs phan phoi qua 3 replicas
	@echo [TGT]  Muc tieu: p95 ^< 3.7s, can bang tai dong deu
	@echo [DATA] Metrics: Replica distribution, latency consistency
	@echo [TIME] Thoi luong: ~2 phut (50s test + 45s recovery)
	@echo =========================================
	@echo.
	@powershell -ExecutionPolicy Bypass -File .\scripts\run-k6-test.ps1 -TestScript "spike-test.js" -TargetVUs 300 -RunLabel "round2-replica-300vus" -Threshold 3700
	@echo.
	@echo [WAIT] Cooldown: 45s...
	@powershell -Command "Start-Sleep -Seconds 45"
	@echo [OK] All Round 2 tests complete!

r2-cleanup: ## [Round 2] Don dep moi truong test
	@echo [CLEANUP] Cleaning up Round 2 test environment...
	docker compose down
	@echo [OK] Cleanup complete. Infrastructure stopped.
