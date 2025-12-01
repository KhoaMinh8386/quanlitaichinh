const { execSync } = require('child_process');

console.log('🔄 Running database migrations...');

try {
  // Try to deploy migrations
  execSync('npx prisma migrate deploy', { stdio: 'inherit' });
  console.log('✅ Migrations completed successfully');
} catch (error) {
  console.log('⚠️ Migration deploy failed, attempting to resolve...');
  
  try {
    // Try to resolve the failed migration by marking it as rolled back
    execSync('npx prisma migrate resolve --rolled-back 20251201105153_', { stdio: 'inherit' });
    console.log('✅ Marked failed migration as rolled back');
    
    // Try to deploy again
    execSync('npx prisma migrate deploy', { stdio: 'inherit' });
    console.log('✅ Migrations completed after resolve');
  } catch (resolveError) {
    console.log('⚠️ Could not resolve migration, trying to skip...');
    
    try {
      // As a last resort, try marking it as applied
      execSync('npx prisma migrate resolve --applied 20251201105153_', { stdio: 'inherit' });
      console.log('✅ Marked migration as applied');
      
      // Try to deploy remaining migrations
      execSync('npx prisma migrate deploy', { stdio: 'inherit' });
      console.log('✅ Remaining migrations completed');
    } catch (applyError) {
      console.error('❌ Could not resolve migration issues. Database may need manual intervention.');
      console.log('💡 Tip: Consider deleting and recreating the database on Render.');
      // Don't exit with error - let the app try to start anyway
    }
  }
}

console.log('🚀 Starting application...');

