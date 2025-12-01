const { execSync } = require('child_process');

console.log('🔄 Running database migrations...');

try {
  // Deploy migrations
  execSync('npx prisma migrate deploy', { stdio: 'inherit' });
  console.log('✅ Migrations completed successfully');
} catch (error) {
  console.error('❌ Migration failed:', error.message);
  console.log('💡 Tip: The database may need to be reset on Render.');
  // Exit with error so Render knows deployment failed
  process.exit(1);
}

console.log('🚀 Starting application...');
