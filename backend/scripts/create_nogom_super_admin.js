require('dotenv').config();
const dns = require('dns');
const mongoose = require('mongoose');

// The local resolver in some environments blocks SRV record lookups, which
// mongodb+srv:// URIs require; force public resolvers that support them.
dns.setServers(['8.8.8.8', '1.1.1.1']);

const EMAIL = 'nogom@admin.com';
const PASSWORD = 'nogom2026#';

const connectDB = async () => {
  await mongoose.connect(process.env.MONGODB_URI, { dbName: 'basketball_academy' });
  console.log('✅ MongoDB connected');
};

const createOrUpdateSuperAdmin = async () => {
  await connectDB();
  const User = require('../src/models/user.model');

  const existing = await User.findOne({ email: EMAIL });

  if (existing) {
    existing.password = PASSWORD; // hashed by the pre('save') hook
    existing.role = 'super_admin';
    existing.isActive = true;
    await existing.save();
    console.log(`✅ Updated existing super_admin: ${EMAIL}`);
  } else {
    await User.create({
      name: 'Nogom Super Admin',
      email: EMAIL,
      password: PASSWORD, // hashed by the pre('save') hook
      role: 'super_admin',
      isActive: true,
    });
    console.log(`✅ Created super_admin: ${EMAIL}`);
  }

  console.log('Role: super_admin | Active: true | Password: hashed with bcrypt (not printed)');
  process.exit(0);
};

createOrUpdateSuperAdmin().catch((err) => {
  console.error('❌ Failed:', err.message);
  process.exit(1);
});
