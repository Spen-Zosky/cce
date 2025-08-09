#!/bin/bash
# CCE Templates Module
# Handles project templates and quick-start functionality

setup_template_system() {
    log_step "Setting up template system..."
    
    # Create templates directory structure
    mkdir -p ~/.cce-universal/templates/{nextjs,react,python,rust,go}
    
    log_success "Template system initialized"
}

install_nextjs_postgres_template() {
    log_step "Installing Next.js + PostgreSQL template..."
    
    cat > ~/.cce-universal/templates/nextjs-postgres.sh << 'TEMPLATE'
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
TEMPLATE
    chmod +x ~/.cce-universal/templates/nextjs-postgres.sh
    
    log_success "Next.js + PostgreSQL template installed"
}

install_additional_templates() {
    log_step "Installing additional templates..."
    
    # React SPA template
    cat > ~/.cce-universal/templates/react-spa.sh << 'REACT_TEMPLATE'
#!/bin/bash
# React SPA Template

PROJECT_NAME="${1:-my-react-app}"
echo "📦 Creating React SPA project: $PROJECT_NAME"

# Create React app
npx create-react-app "$PROJECT_NAME" --template typescript
cd "$PROJECT_NAME"

# Install additional dependencies
npm install @tanstack/react-query axios react-router-dom
npm install -D @types/react-router-dom

# Initialize CCE
~/.cce-universal/scripts/init-project.sh .

echo "✅ React SPA project created!"
echo "Run: cd $PROJECT_NAME && npm start"
REACT_TEMPLATE
    chmod +x ~/.cce-universal/templates/react-spa.sh
    
    # Python FastAPI template
    cat > ~/.cce-universal/templates/python-fastapi.sh << 'PYTHON_TEMPLATE'
#!/bin/bash
# Python FastAPI Template

PROJECT_NAME="${1:-my-fastapi-app}"
echo "📦 Creating Python FastAPI project: $PROJECT_NAME"

mkdir -p "$PROJECT_NAME"
cd "$PROJECT_NAME"

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Create requirements.txt
cat > requirements.txt << 'REQUIREMENTS'
fastapi==0.104.1
uvicorn[standard]==0.24.0
pydantic==2.4.2
python-multipart==0.0.6
sqlalchemy==2.0.23
alembic==1.12.1
REQUIREMENTS

# Install dependencies
pip install -r requirements.txt

# Create main.py
cat > main.py << 'MAIN'
from fastapi import FastAPI
from pydantic import BaseModel

app = FastAPI(title="My FastAPI App")

class Item(BaseModel):
    name: str
    description: str = None

@app.get("/")
def read_root():
    return {"message": "Hello World"}

@app.get("/items/{item_id}")
def read_item(item_id: int, q: str = None):
    return {"item_id": item_id, "q": q}

@app.post("/items/")
def create_item(item: Item):
    return item
MAIN

# Initialize CCE
~/.cce-universal/scripts/init-project.sh .

echo "✅ Python FastAPI project created!"
echo "Run: cd $PROJECT_NAME && source venv/bin/activate && uvicorn main:app --reload"
PYTHON_TEMPLATE
    chmod +x ~/.cce-universal/templates/python-fastapi.sh
    
    log_success "Additional templates installed"
}

create_template_manager() {
    log_step "Creating template management tool..."
    
    cat > ~/.cce-universal/bin/cce-create << 'TEMPLATE_MANAGER'
#!/usr/bin/env bash
# CCE Project Template Manager

TEMPLATES_DIR=~/.cce-universal/templates

list_templates() {
    echo "Available CCE Templates:"
    echo "======================="
    echo ""
    echo "📦 Web Applications:"
    echo "  nextjs-postgres  - Next.js 14 + PostgreSQL + Prisma"
    echo "  react-spa        - React SPA with TypeScript"
    echo ""
    echo "🔌 API Services:"
    echo "  python-fastapi   - Python FastAPI + SQLAlchemy"
    echo ""
    echo "Usage:"
    echo "  cce-create <template> [project-name]"
    echo ""
    echo "Examples:"
    echo "  cce-create nextjs-postgres my-app"
    echo "  cce-create react-spa my-frontend"
    echo "  cce-create python-fastapi my-api"
}

create_project() {
    local template="$1"
    local project_name="$2"
    
    if [ -z "$template" ]; then
        list_templates
        return 0
    fi
    
    local template_script="$TEMPLATES_DIR/${template}.sh"
    
    if [ ! -f "$template_script" ]; then
        echo "❌ Template '$template' not found"
        echo ""
        list_templates
        return 1
    fi
    
    echo "🚀 Creating project using template: $template"
    echo ""
    
    # Execute template script
    bash "$template_script" "$project_name"
    
    echo ""
    echo "✅ Project creation complete!"
    echo "💡 Use 'cc' or 'claude' to start working with Claude AI"
}

# Quick winner shortcut
quick_winner() {
    echo "🏆 Creating Quick Winner Project..."
    echo "   Template: Next.js + PostgreSQL + Prisma"
    echo ""
    
    local project_name="${1:-quick-winner-$(date +%Y%m%d-%H%M)}"
    create_project "nextjs-postgres" "$project_name"
    
    if [ $? -eq 0 ]; then
        echo ""
        echo "🎉 Quick Winner project ready!"
        echo "   Perfect for rapid MVP development"
        echo ""
        echo "🚀 Next steps:"
        echo "   1. cd $project_name"
        echo "   2. Update .env.local with your database URL"
        echo "   3. npx prisma migrate dev --name init"
        echo "   4. npm run dev"
        echo "   5. Start building with 'cc' (Claude)"
    fi
}

case "$1" in
    list|ls|--list)
        list_templates
        ;;
    quick|winner|quick-winner)
        shift
        quick_winner "$@"
        ;;
    *)
        create_project "$@"
        ;;
esac
TEMPLATE_MANAGER
    chmod +x ~/.cce-universal/bin/cce-create
    
    log_success "Template manager created"
}

# Main function for templates setup
setup_templates() {
    setup_template_system
    install_nextjs_postgres_template
    install_additional_templates
    create_template_manager
}