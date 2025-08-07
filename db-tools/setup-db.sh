#!/bin/bash
# Database Quick Setup

echo "🗄️ Database Setup Assistant"
echo ""
echo "Choose your database:"
echo "1) Local PostgreSQL (Docker)"
echo "2) Supabase (Cloud - Free)"
echo "3) Neon (Cloud - Free)"
echo "4) Existing PostgreSQL"

read -p "Choice (1-4): " choice

case $choice in
    1)
        echo "🐳 Setting up PostgreSQL with Docker..."
        docker run --name postgres-dev \
            -e POSTGRES_PASSWORD=postgres \
            -p 5432:5432 \
            -d postgres:15
        echo "✅ PostgreSQL running on localhost:5432"
        echo "📝 Connection string: postgresql://postgres:postgres@localhost:5432/myapp"
        ;;
    2)
        echo "🌊 Supabase setup:"
        echo "1. Go to https://supabase.com"
        echo "2. Create new project"
        echo "3. Copy connection string from Settings > Database"
        echo "4. Update .env.local"
        ;;
    3)
        echo "⚡ Neon setup:"
        echo "1. Go to https://neon.tech"
        echo "2. Create new project"
        echo "3. Copy connection string"
        echo "4. Update .env.local"
        ;;
    4)
        read -p "Enter your DATABASE_URL: " db_url
        echo "DATABASE_URL=\"$db_url\"" >> .env.local
        echo "✅ Database configured!"
        ;;
esac
