#!/bin/bash
# Next.js + PostgreSQL + Prisma Template

PROJECT_NAME="${1:-my-app}"
echo "📦 Creating Next.js + PostgreSQL project: $PROJECT_NAME"

# Create Next.js app
npx create-next-app@latest "$PROJECT_NAME" \
  --typescript \
  --tailwind \
  --app \
  --src-dir \
  --import-alias "@/*" \
  --no-eslint

cd "$PROJECT_NAME"

# Install database dependencies
npm install @prisma/client prisma
npm install @tanstack/react-query axios zod
npm install -D @types/node

# Initialize Prisma
npx prisma init

# Create Prisma schema
cat > prisma/schema.prisma << 'SCHEMA'
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

model User {
  id        String   @id @default(cuid())
  email     String   @unique
  name      String?
  posts     Post[]
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt
}

model Post {
  id        String   @id @default(cuid())
  title     String
  content   String?
  published Boolean  @default(false)
  author    User?    @relation(fields: [authorId], references: [id])
  authorId  String?
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt
}
SCHEMA

# Create .env.local
cat > .env.local << 'ENV'
# Database
DATABASE_URL="postgresql://postgres:password@localhost:5432/myapp?schema=public"

# Next Auth (when needed)
NEXTAUTH_URL="http://localhost:3000"
NEXTAUTH_SECRET="your-secret-here"
ENV

# Create database utilities
mkdir -p src/lib
cat > src/lib/prisma.ts << 'PRISMALIB'
import { PrismaClient } from '@prisma/client'

const globalForPrisma = globalThis as unknown as {
  prisma: PrismaClient | undefined
}

export const prisma = globalForPrisma.prisma ?? new PrismaClient()

if (process.env.NODE_ENV !== 'production') globalForPrisma.prisma = prisma
PRISMALIB

# Create API route example
mkdir -p src/app/api/users
cat > src/app/api/users/route.ts << 'APIROUTE'
import { NextResponse } from 'next/server'
import { prisma } from '@/lib/prisma'

export async function GET() {
  try {
    const users = await prisma.user.findMany({
      include: { posts: true }
    })
    return NextResponse.json(users)
  } catch (error) {
    return NextResponse.json({ error: 'Failed to fetch users' }, { status: 500 })
  }
}

export async function POST(request: Request) {
  try {
    const json = await request.json()
    const user = await prisma.user.create({
      data: json,
    })
    return NextResponse.json(user, { status: 201 })
  } catch (error) {
    return NextResponse.json({ error: 'Failed to create user' }, { status: 500 })
  }
}
APIROUTE

# Initialize CCE in project
~/.cce-universal/scripts/init-project.sh .

# Update project CLAUDE.md
cat >> .claude/CLAUDE.md << 'CLAUDEMD'

## Tech Stack
- Next.js 14 (App Router)
- TypeScript
- PostgreSQL + Prisma ORM
- Tailwind CSS
- React Query

## Project Structure
- /src/app - Next.js app router pages
- /src/app/api - API routes
- /src/components - React components
- /src/lib - Utilities and database
- /prisma - Database schema and migrations

## Database
Using PostgreSQL with Prisma ORM.
Schema includes User and Post models.

## Commands
- npm run dev - Start development
- npx prisma studio - Database GUI
- npx prisma migrate dev - Run migrations
- npx prisma generate - Generate client

## Deployment
Ready for Vercel deployment with PostgreSQL on Supabase/Neon.
CLAUDEMD

echo ""
echo "✅ Next.js + PostgreSQL project created!"
echo ""
echo "Next steps:"
echo "1. cd $PROJECT_NAME"
echo "2. Update DATABASE_URL in .env.local"
echo "3. npx prisma migrate dev --name init"
echo "4. npm run dev"
echo "5. Open http://localhost:3000"
