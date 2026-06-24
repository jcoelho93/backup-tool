# backup-tool

A minimal Docker image that dumps a PostgreSQL database and uploads the compressed backup to any S3-compatible storage.

## How it works

On each run, the container:

1. Dumps the database with `pg_dump --data-only --no-privileges`
2. Compresses the output with gzip
3. Uploads the file to `s3://<S3_BUCKET>/backups/<YEAR>/<MONTH>/<APP_NAME>-<TIMESTAMP>.sql.gz`
4. Removes the local temp file

Backups are automatically organized by year and month, making them easy to browse and apply retention policies to.

## Usage

Pull the image from the GitHub Container Registry:

```bash
docker pull ghcr.io/jcoelho93/backup-tool:latest
```

Run a one-off backup:

```bash
docker run --rm \
  -e APP_NAME=myapp \
  -e DATABASE_URL=postgres://user:password@host:5432/dbname \
  -e S3_BUCKET=my-backups \
  -e S3_ENDPOINT=https://s3.amazonaws.com \
  -e S3_ACCESS_KEY_ID=... \
  -e S3_SECRET_ACCESS_KEY=... \
  ghcr.io/jcoelho93/backup-tool:latest
```

### Environment variables

| Variable | Description |
|---|---|
| `APP_NAME` | Prefix for the backup filename (e.g. `myapp`) |
| `DATABASE_URL` | Full PostgreSQL connection string |
| `S3_BUCKET` | Name of the S3 bucket |
| `S3_ENDPOINT` | S3-compatible endpoint URL |
| `S3_ACCESS_KEY_ID` | S3 access key |
| `S3_SECRET_ACCESS_KEY` | S3 secret key |
| `HEARTBEAT_URL` | _(optional)_ URL pinged on success; `/fail` is appended on failure |

All variables except `HEARTBEAT_URL` are required. The container exits immediately if any required variable is missing.

### Heartbeat monitoring

When `HEARTBEAT_URL` is set, the container sends a `GET` request to monitor each run:

- **Success:** a `GET` to `HEARTBEAT_URL` after the backup is uploaded.
- **Failure:** a `GET` to `HEARTBEAT_URL` with `/fail` appended if the backup fails for any reason.

This works with services like [Healthchecks.io](https://healthchecks.io/), Uptime Kuma, or any endpoint that accepts a ping. If `HEARTBEAT_URL` is unset, no heartbeat is sent.

### Scheduled backups with Kubernetes

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: db-backup
spec:
  schedule: "0 3 * * *"
  jobTemplate:
    spec:
      template:
        spec:
          restartPolicy: OnFailure
          containers:
            - name: backup
              image: ghcr.io/jcoelho93/backup-tool:latest
              env:
                - name: APP_NAME
                  value: myapp
                - name: DATABASE_URL
                  valueFrom:
                    secretKeyRef:
                      name: db-secret
                      key: url
                - name: S3_BUCKET
                  value: my-backups
                - name: S3_ENDPOINT
                  value: https://s3.amazonaws.com
                - name: S3_ACCESS_KEY_ID
                  valueFrom:
                    secretKeyRef:
                      name: s3-secret
                      key: access-key-id
                - name: S3_SECRET_ACCESS_KEY
                  valueFrom:
                    secretKeyRef:
                      name: s3-secret
                      key: secret-access-key
```

## S3-compatible storage

The `S3_ENDPOINT` variable makes this tool work with any S3-compatible provider:

| Provider | Endpoint |
|---|---|
| AWS S3 | `https://s3.amazonaws.com` |
| MinIO | `http://minio:9000` |
| Backblaze B2 | `https://s3.us-west-004.backblazeb2.com` |
| Cloudflare R2 | `https://<account-id>.r2.cloudflarestorage.com` |
| DigitalOcean Spaces | `https://<region>.digitaloceanspaces.com` |

## Platform

The image is built for `linux/arm64`.

## License

MIT
