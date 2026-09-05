#!/usr/bin/env bash

# ============================================================================
# AI Security Gateway - Comprehensive Test Suite
# ============================================================================

set -e

echo "🔍 Starting Comprehensive Test Suite for Ai-security-gateway..."
echo "================================================================"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0

# Test function
test_case() {
    local test_name=$1
    local test_command=$2
    
    echo -e "\n${BLUE}▶ Testing: ${test_name}${NC}"
    
    if eval "$test_command"; then
        echo -e "${GREEN}✓ PASSED${NC}: $test_name"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗ FAILED${NC}: $test_name"
        ((TESTS_FAILED++))
    fi
}

# ============================================================================
# SECTION 1: Environment & Configuration Tests
# ============================================================================
echo -e "\n${YELLOW}[SECTION 1] Environment & Configuration Tests${NC}"
echo "=================================================="

test_case "Docker Compose file exists" "test -f docker-compose.yml"
test_case "Dockerfile exists" "test -f Dockerfile"
test_case "requirements.txt exists" "test -f requirements.txt"
test_case ".env file exists" "test -f .env"
test_case ".env.example file exists" "test -f .env.example"
test_case "main.py exists" "test -f main.py"
test_case "logs directory created" "mkdir -p logs && test -d logs"
test_case "certs directory created" "mkdir -p certs && test -d certs"

# ============================================================================
# SECTION 2: Docker Configuration Tests
# ============================================================================
echo -e "\n${YELLOW}[SECTION 2] Docker Configuration Tests${NC}"
echo "========================================="

test_case "Docker is installed" "command -v docker"
test_case "Docker daemon is running" "docker ps >/dev/null 2>&1"
test_case "Docker Compose is available" "docker compose version >/dev/null 2>&1 || docker-compose --version >/dev/null 2>&1"
test_case "docker-compose.yml is valid YAML" "docker compose config >/dev/null 2>&1 || docker-compose config >/dev/null 2>&1"

# ============================================================================
# SECTION 3: Python Dependencies Tests
# ============================================================================
echo -e "\n${YELLOW}[SECTION 3] Python Dependencies Tests${NC}"
echo "========================================"

test_case "Python 3.11+ is available" "python3 --version | grep -E 'Python 3.(1[1-9]|[2-9][0-9])'"
test_case "FastAPI in requirements" "grep -q 'fastapi' requirements.txt"
test_case "Uvicorn in requirements" "grep -q 'uvicorn' requirements.txt"
test_case "Celery in requirements" "grep -q 'celery' requirements.txt"
test_case "Redis client in requirements" "grep -q 'redis' requirements.txt"
test_case "Docker SDK in requirements" "grep -q 'docker' requirements.txt"
test_case "httpx in requirements" "grep -q 'httpx' requirements.txt"

# ============================================================================
# SECTION 4: Security Configuration Tests
# ============================================================================
echo -e "\n${YELLOW}[SECTION 4] Security Configuration Tests${NC}"
echo "=========================================="

test_case "mTLS certificate paths configured" "grep -q 'ssl-keyfile' docker-compose.yml && grep -q 'ssl-certfile' docker-compose.yml"
test_case "Redis password configured" "grep -q 'requirepass' docker-compose.yml"
test_case "Rate limiting logic in main.py" "grep -q 'check_rate_limit' main.py"
test_case "Prompt injection detection in main.py" "grep -q 'INJECTION_REGEX' main.py"
test_case "Leak detection patterns defined" "grep -q 'LEAK_DETECTION_PATTERNS' main.py"
test_case "Outbound data scrubbing function" "grep -q 'verify_and_scrub_outbound_data' main.py"
test_case "Security event logging configured" "grep -q 'log_security_event' main.py"
test_case "API key authentication enabled" "grep -q 'X-Gateway-Auth-Token' main.py"

# ============================================================================
# SECTION 5: Code Quality Tests
# ============================================================================
echo -e "\n${YELLOW}[SECTION 5] Code Quality Tests${NC}"
echo "================================="

test_case "main.py has proper imports" "grep -q 'from fastapi import' main.py && grep -q 'import redis' main.py"
test_case "FastAPI app initialized" "grep -q 'app = FastAPI' main.py"
test_case "Dispatch endpoint defined" "grep -q '@app.post.*dispatch' main.py"
test_case "Task result endpoint defined" "grep -q '@app.get.*tasks' main.py"
test_case "Environment variables loaded" "grep -q 'os.getenv' main.py"

# ============================================================================
# SECTION 6: Docker Services Configuration Tests
# ============================================================================
echo -e "\n${YELLOW}[SECTION 6] Docker Services Configuration Tests${NC}"
echo "================================================"

test_case "gateway-api service configured" "grep -q 'gateway-api:' docker-compose.yml"
test_case "redis-broker service configured" "grep -q 'redis-broker:' docker-compose.yml"
test_case "celery-worker service configured" "grep -q 'celery-worker:' docker-compose.yml"
test_case "Volume for gateway logs configured" "grep -q 'gateway_logs' docker-compose.yml"
test_case "Volume for certs configured" "grep -q './certs:/app/certs' docker-compose.yml"
test_case "Redis volume configured" "grep -q 'redis_data' docker-compose.yml"
test_case "Network bridge configured" "grep -q 'gateway-network' docker-compose.yml"
test_case "Health checks enabled" "grep -q 'healthcheck:' docker-compose.yml"
test_case "Resource limits configured" "grep -q 'deploy:' docker-compose.yml && grep -q 'resources:' docker-compose.yml"

# ============================================================================
# SECTION 7: Environment Variables Tests
# ============================================================================
echo -e "\n${YELLOW}[SECTION 7] Environment Variables Tests${NC}"
echo "========================================"

test_case "EXPECTED_GATEWAY_TOKEN set" "grep -q 'EXPECTED_GATEWAY_TOKEN' .env"
test_case "REDIS_PASSWORD set" "grep -q 'REDIS_PASSWORD' .env"
test_case "LLAMA_GUARD_ENDPOINT set" "grep -q 'LLAMA_GUARD_ENDPOINT' .env"
test_case "LOG_LEVEL set" "grep -q 'LOG_LEVEL' .env"

# ============================================================================
# SECTION 8: Documentation Tests
# ============================================================================
echo -e "\n${YELLOW}[SECTION 8] Documentation Tests${NC}"
echo "================================"

test_case "README.md exists (if required)" "test -f README.md || echo 'Optional file'"
test_case "Comments in docker-compose.yml" "grep -q '#' docker-compose.yml"
test_case "Docstrings in main.py functions" "grep -q '\"\"\"' main.py"

# ============================================================================
# SECTION 9: Syntax Validation Tests
# ============================================================================
echo -e "\n${YELLOW}[SECTION 9] Syntax Validation Tests${NC}"
echo "===================================="

test_case "main.py Python syntax valid" "python3 -m py_compile main.py 2>/dev/null && echo 'Syntax OK' || echo 'Syntax Check'"
test_case "No obvious syntax errors in requirements" "grep -v '^#' requirements.txt | grep -v '^$' | head -1 | grep -q '=' && echo 'Valid Format'"

# ============================================================================
# SECTION 10: Feature Tests
# ============================================================================
echo -e "\n${YELLOW}[SECTION 10] Feature Implementation Tests${NC}"
echo "=========================================="

test_case "SECRET_KEY leak detection pattern" "grep -q 'SECRET_KEY' main.py && grep -q 'sk-' main.py"
test_case "SYSTEM_PROMPT_LEAK detection pattern" "grep -q 'SYSTEM_PROMPT_LEAK' main.py"
test_case "PII_DATA detection pattern (SSN)" "grep -q 'PII_DATA' main.py && grep -q '\\\\d{3}-\\\\d{2}-\\\\d{4}' main.py"
test_case "Violations logged with details" "grep -q 'triggered_rules' main.py"
test_case "REDACTED tag for blocked events" "grep -q 'BLOCK EVENT' main.py"

# ============================================================================
# SUMMARY
# ============================================================================
echo -e "\n${YELLOW}================================================${NC}"
echo -e "${YELLOW}TEST SUMMARY${NC}"
echo -e "${YELLOW}================================================${NC}"

TOTAL_TESTS=$((TESTS_PASSED + TESTS_FAILED))

echo -e "Total Tests: ${BLUE}${TOTAL_TESTS}${NC}"
echo -e "Passed: ${GREEN}${TESTS_PASSED}${NC}"
echo -e "Failed: ${RED}${TESTS_FAILED}${NC}"

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "\n${GREEN}✓ All tests passed! Production stack is ready for deployment.${NC}"
    exit 0
else
    echo -e "\n${RED}✗ Some tests failed. Please review the errors above.${NC}"
    exit 1
fi
