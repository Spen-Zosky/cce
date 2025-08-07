#!/bin/bash
# Smart CRUD Generator for Next.js + Prisma

generate_crud() {
    MODEL_NAME="$1"
    MODEL_LOWER=$(echo "$MODEL_NAME" | tr '[:upper:]' '[:lower:]')
    
    echo "🔨 Generating CRUD for model: $MODEL_NAME"
    
    # Generate API routes
    mkdir -p "src/app/api/${MODEL_LOWER}s/"
    mkdir -p "src/app/api/${MODEL_LOWER}s/[id]"
    
    cat > "src/app/api/${MODEL_LOWER}s/route.ts" << EOF
import { NextResponse } from 'next/server'
import { prisma } from '@/lib/prisma'

// GET all ${MODEL_NAME}s
export async function GET() {
  try {
    const items = await prisma.${MODEL_LOWER}.findMany()
    return NextResponse.json(items)
  } catch (error) {
    return NextResponse.json({ error: 'Failed to fetch' }, { status: 500 })
  }
}

// CREATE new ${MODEL_NAME}
export async function POST(request: Request) {
  try {
    const json = await request.json()
    const item = await prisma.${MODEL_LOWER}.create({ data: json })
    return NextResponse.json(item, { status: 201 })
  } catch (error) {
    return NextResponse.json({ error: 'Failed to create' }, { status: 500 })
  }
}
EOF

    cat > "src/app/api/${MODEL_LOWER}s/[id]/route.ts" << EOF
import { NextResponse } from 'next/server'
import { prisma } from '@/lib/prisma'

// GET single ${MODEL_NAME}
export async function GET(
  request: Request,
  { params }: { params: { id: string } }
) {
  try {
    const item = await prisma.${MODEL_LOWER}.findUnique({
      where: { id: params.id }
    })
    if (!item) return NextResponse.json({ error: 'Not found' }, { status: 404 })
    return NextResponse.json(item)
  } catch (error) {
    return NextResponse.json({ error: 'Failed to fetch' }, { status: 500 })
  }
}

// UPDATE ${MODEL_NAME}
export async function PUT(
  request: Request,
  { params }: { params: { id: string } }
) {
  try {
    const json = await request.json()
    const item = await prisma.${MODEL_LOWER}.update({
      where: { id: params.id },
      data: json,
    })
    return NextResponse.json(item)
  } catch (error) {
    return NextResponse.json({ error: 'Failed to update' }, { status: 500 })
  }
}

// DELETE ${MODEL_NAME}
export async function DELETE(
  request: Request,
  { params }: { params: { id: string } }
) {
  try {
    await prisma.${MODEL_LOWER}.delete({
      where: { id: params.id }
    })
    return NextResponse.json({ success: true })
  } catch (error) {
    return NextResponse.json({ error: 'Failed to delete' }, { status: 500 })
  }
}
EOF

    echo "✅ CRUD API generated for $MODEL_NAME"
    echo "📍 Routes created:"
    echo "   GET    /api/${MODEL_LOWER}s"
    echo "   POST   /api/${MODEL_LOWER}s"
    echo "   GET    /api/${MODEL_LOWER}s/[id]"
    echo "   PUT    /api/${MODEL_LOWER}s/[id]"
    echo "   DELETE /api/${MODEL_LOWER}s/[id]"
}

# Check if model name provided
if [ -z "$1" ]; then
    echo "Usage: cce-crud <ModelName>"
    echo "Example: cce-crud Product"
    exit 1
fi

generate_crud "$1"
