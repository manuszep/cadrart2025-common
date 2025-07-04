# Cadrart common components and infrastructure

## Secure Test Endpoint Secret

For all projects in this workspace, a shared environment variable is used to protect test-only endpoints:

- **Environment variable:** `TEST_ENDPOINT_SECRET`
- **Purpose:** Required to access `/api/test/cleanup` and `/api/test/setup` endpoints in backend
- **How to set:**
  - In your shell: `export TEST_ENDPOINT_SECRET="your-strong-secret"`
  - In CI/CD: Set as a secret environment variable
  - In a local `.env` file (not committed):
    ```
    TEST_ENDPOINT_SECRET=your-strong-secret
    ```
- **Default (for local dev only):** If not set, falls back to `dev-secret-key` (not secure for shared/dev/CI)

**Never commit your real secret to version control.**

## Usage Example

```sh
# Set the secret for your session
export TEST_ENDPOINT_SECRET="your-strong-secret"

# Use the secret in API calls
curl -X POST http://localhost:3000/api/test/setup -H "x-test-secret: your-strong-secret"
```
