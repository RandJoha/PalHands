# MongoDB Setup Guide for PalHands

## Quick Solutions (Atlas First)

### Option 1: MongoDB Atlas (Recommended - Free Cloud Database)

1. **Go to [MongoDB Atlas](https://www.mongodb.com/atlas)**
2. **Create a free account**
3. **Create a new cluster** (M0 Free tier)
4. **Set up database access:**
   - Create a database user with username and password
   - Remember these credentials
5. **Set up network access:**
   - Add your IP address or use `0.0.0.0/0` for all IPs (development only)
6. **Get your connection string:**
   - Click "Connect" on your cluster
   - Choose "Connect your application"
   - Copy the connection string
7. **Update your `.env` file:**
   ```
   MONGODB_URI=mongodb+srv://username:password@cluster.mongodb.net/palhands?retryWrites=true&w=majority
   ```
   Replace `username`, `password`, and `cluster` with your actual values

### Option 2: Docker MongoDB (Optional for contributors)
Atlas is recommended. If you must run locally for offline dev, you can use Docker MongoDB, but set `MONGODB_URI` explicitly and remove it before committing configs.

### Option 3: Install MongoDB Locally

#### Windows:
1. **Download MongoDB Community Server** from [mongodb.com](https://www.mongodb.com/try/download/community)
2. **Install with default settings**
3. **Start MongoDB service:**
   ```bash
   net start MongoDB
   ```

#### macOS:
```bash
# Using Homebrew
brew tap mongodb/brew
brew install mongodb-community
brew services start mongodb/brew/mongodb-community
```

#### Linux (Ubuntu):
```bash
# Import MongoDB public GPG key
wget -qO - https://www.mongodb.org/static/pgp/server-7.0.asc | sudo apt-key add -

# Create list file for MongoDB
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list

# Update package database
sudo apt-get update

# Install MongoDB
sudo apt-get install -y mongodb-org

# Start MongoDB
sudo systemctl start mongod
sudo systemctl enable mongod
```

## Test Your Connection

After setting up Atlas and `.env`, test the connection:

```bash
cd backend
npm run dev
```

You should see:
```
✅ Connected to MongoDB (Atlas)
🚀 PalHands server running on port 3000
```

## Restore frontend data into Atlas (providers, categories, services)

If your Atlas data was deleted or inflated incorrectly, you can restore a consistent snapshot derived from the frontend definitions without touching the `users` collection:

1. Ensure your `.env` points to Atlas (MONGODB_URI=...)
2. Run the restore script:

   Windows (PowerShell):
   ```powershell
   cd backend
   npm run restore:fe
   ```

   This will:
   - Upsert 8 service categories into `servicecategories`
   - Upsert ~34 providers into `providers` with uniform password `Provider123!`
   - Upsert services linked to those providers, capped at ~50 total

3. Optional: Hard reset before restore (drops only providers/services/servicecategories):

   ```powershell
   cd backend
   npm run restore:reset
   ```

Notes
- The script is idempotent (safe to re-run); it never modifies the `users` collection.
- Provider login format: `provider+<name>.<index>@palhands.com` with password `Provider123!`.

### Prune extra services (remove everything not in the canonical ~50)

If your `services` collection has duplicates or leftovers from previous conflicts, prune them:

```powershell
cd backend
npm run restore:prune
```

Or, do a full reset and prune in one step:

```powershell
cd backend
npm run restore:reset-prune
```

This deletes services not part of the freshly generated canonical set while leaving `users` untouched.

### Snapshot files for quick recovery

Every restore run writes JSON snapshots to `backend/src/utils/data/`:
- `snapshot.json` (combined)
- `categories.json`
- `providers.json`
- `services.json`

You can use these for quick audits or to re-seed another environment.

## Troubleshooting

### Connection Refused Error
- Make sure MongoDB is running
- Check if the port 27017 is available
- Verify your connection string format

### Authentication Error (MongoDB Atlas)
- Check your username and password
- Ensure your IP is whitelisted
- Verify the cluster name in the connection string

### Docker Issues
- Make sure Docker Desktop is running
- Check if the container is running: `docker ps`
- Restart the container: `docker restart mongodb-palhands`

## Next Steps

Once MongoDB is connected:
1. Your backend will automatically create the database
2. Collections will be created when you first save data
3. You can start building your API endpoints

## Production Notes

For production deployment:
- Use MongoDB Atlas or a managed MongoDB service
- Set up proper authentication and authorization
- Configure backups and monitoring
- Use environment-specific connection strings 