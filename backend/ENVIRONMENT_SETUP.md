# Environment Setup for PalHands Backend

## Quick Start

1. **Create your environment file (.env):**
    - Windows (PowerShell):
       ```powershell
       Copy-Item env.example .env
       notepad .env
       ```
    - macOS/Linux:
       ```bash
       cp env.example .env && ${EDITOR:-nano} .env
       ```

2. **Update the values in `.env` as needed**

3. **Start the server:**
    - Windows (PowerShell):
       ```powershell
       npm run dev
       ```
    - macOS/Linux:
       ```bash
       npm run dev
       ```

## Environment Files

### `.env` - Essential Variables
Contains the essential environment variables needed to run the application in development mode. Start by copying from `env.example`.

### `env.example` - Complete Configuration
Contains all possible environment variables with sample values for reference.

## Required Environment Variables

### Essential (Minimum Required)
- `NODE_ENV` - Environment (development/production)
- `PORT` - Server port (default: 3000)
- `MONGODB_URI` - MongoDB connection string
- `JWT_SECRET` - Secret key for JWT tokens

### Optional (Recommended)
- `EMAIL_HOST` - SMTP server for email notifications
- `EMAIL_USER` - Email username
- `EMAIL_PASS` - Email password
- `CORS_ORIGIN` - Allowed origins for CORS

## Database Setup

### Local MongoDB
Using a local MongoDB or Docker is no longer the default. Prefer MongoDB Atlas for consistency.

### MongoDB Atlas (Cloud)
1. Create a free account at [MongoDB Atlas](https://www.mongodb.com/atlas)
2. Create a cluster
3. Get your connection string
4. Update `MONGODB_URI` in your `.env` file (required)

## Email Configuration

### Gmail Setup
1. Enable 2-factor authentication
2. Generate an App Password
3. Use the App Password in `EMAIL_PASS`

### Example Gmail Configuration
```
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USER=your-email@gmail.com
EMAIL_PASS=your-16-digit-app-password
EMAIL_FROM=PalHands <noreply@palhands.com>
```

## Security Notes

⚠️ **Important Security Reminders:**

1. **Never commit `.env` files to version control**
2. **Change default JWT secrets in production**
3. **Use strong, unique passwords**
4. **Enable HTTPS in production**
5. **Regularly update dependencies**

## Production Deployment

For production deployment:

1. Copy `env.example` to `.env`
2. Update all values with production credentials
3. Set `NODE_ENV=production`
4. Use a strong, unique `JWT_SECRET`
5. Configure proper `CORS_ORIGIN` values
6. Set up proper logging and monitoring

## Troubleshooting

### Common Issues

1. **MongoDB Connection Error**
   - Check if MongoDB is running
   - Verify connection string format
   - Ensure network connectivity

2. **JWT Errors**
   - Verify `JWT_SECRET` is set
   - Check token expiration settings

3. **Email Not Sending**
   - Verify SMTP credentials
   - Check firewall settings
   - Ensure 2FA is enabled for Gmail

4. **CORS Errors**
   - Update `CORS_ORIGIN` with your frontend URL
   - Check browser console for specific errors

## Environment Variable Reference

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `NODE_ENV` | Environment mode | development | Yes |
| `PORT` | Server port | 3000 | No |
| `MONGODB_URI` | Database connection | (Atlas URI recommended) | Yes |
| `JWT_SECRET` | JWT signing secret | - | Yes |
| `JWT_EXPIRES_IN` | Token expiration | 7d | No |
| `EMAIL_HOST` | SMTP server | - | No |
| `EMAIL_USER` | Email username | - | No |
| `EMAIL_PASS` | Email password | - | No |
| `CORS_ORIGIN` | Allowed origins | localhost:3000,8080 | No |
| `BCRYPT_ROUNDS` | Password hashing rounds | 12 | No |
| `MAX_FILE_SIZE` | Max upload size (bytes) | 5242880 | No |
| `UPLOAD_PATH` | File upload directory | ./uploads | No | 
| `STORAGE_DRIVER` | local | s3 | minio | local | No |
| `S3_BUCKET` | S3/MinIO bucket name | - | When STORAGE_DRIVER is s3/minio |
| `S3_REGION` | S3 region | us-east-1 | When STORAGE_DRIVER is s3 |
| `S3_ENDPOINT` | MinIO or custom S3 endpoint URL | - | When STORAGE_DRIVER is minio/custom |
| `S3_ACCESS_KEY_ID` | Access key | - | When STORAGE_DRIVER is s3/minio |
| `S3_SECRET_ACCESS_KEY` | Secret key | - | When STORAGE_DRIVER is s3/minio |
| `S3_FORCE_PATH_STYLE` | Use path-style URLs | false | No |
| `S3_SIGNED_URL_TTL` | Presign TTL (seconds) | 900 | No |
| `ENABLE_MEDIA_CLEANUP` | Enable background media orphan cleanup | false | No |
| `MEDIA_CLEANUP_INTERVAL_MIN` | Cleanup interval minutes | 120 | No |