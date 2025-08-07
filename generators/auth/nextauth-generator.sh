#!/bin/bash
# CCE Auth Generator - NextAuth.js Setup

echo "🔐 Installing NextAuth.js..."

# Check Next.js project
if [ ! -f "package.json" ]; then
    echo "❌ Error: Run in Next.js project"
    exit 1
fi

# Install dependencies
npm install next-auth @auth/prisma-adapter bcryptjs
npm install -D @types/bcryptjs

# Create auth folders
mkdir -p src/lib
mkdir -p src/app/api/auth/\[...nextauth\]
mkdir -p src/app/auth/{login,register}
mkdir -p src/components/providers

echo "✅ NextAuth folders created"

# Create basic auth config
cat > src/lib/auth-config.txt << 'EOF'
// Move this to src/lib/auth.ts and customize
import NextAuth from "next-auth"
import CredentialsProvider from "next-auth/providers/credentials"

export const authOptions = {
  providers: [
    CredentialsProvider({
      name: 'credentials',
      credentials: {
        email: { label: "Email", type: "email" },
        password: { label: "Password", type: "password" }
      },
      async authorize(credentials) {
        // Add your auth logic here
        return { id: "1", email: credentials.email }
      }
    })
  ]
}
EOF

echo "✅ Auth template created at src/lib/auth-config.txt"
echo ""
echo "Next steps:"
echo "1. Rename auth-config.txt to auth.ts"
echo "2. Create login/register pages"
echo "3. Add middleware.ts for protected routes"
