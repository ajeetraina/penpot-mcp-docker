#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SOURCE_REPO="https://github.com/montevive/penpot-mcp.git"
SOURCE_DIR="penpot-mcp-source"
IMAGE_NAME="penpot-mcp"
CONTAINER_NAME="penpot-mcp-server"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    if ! command_exists docker; then
        print_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    if ! command_exists git; then
        print_error "Git is not installed. Please install Git first."
        exit 1
    fi
    
    # Check if docker-compose exists (v1 or v2)
    if ! command_exists docker-compose && ! docker compose version >/dev/null 2>&1; then
        print_error "Docker Compose is not installed. Please install Docker Compose first."
        exit 1
    fi
    
    print_success "All prerequisites are met!"
}

# Clone the source repository
clone_source() {
    print_status "Cloning the source repository..."
    
    if [ -d "$SOURCE_DIR" ]; then
        print_warning "Source directory already exists. Updating..."
        cd "$SOURCE_DIR"
        git pull origin main
        cd ..
    else
        git clone "$SOURCE_REPO" "$SOURCE_DIR"
    fi
    
    print_success "Source code cloned successfully!"
}

# Copy source files to current directory
copy_source_files() {
    print_status "Copying source files..."
    
    # Copy all source files except .git and other unnecessary files
    rsync -av --exclude='.git' --exclude='__pycache__' --exclude='*.pyc' \
          --exclude='.pytest_cache' --exclude='.coverage' \
          "$SOURCE_DIR/" ./
    
    print_success "Source files copied successfully!"
}

# Setup environment file
setup_environment() {
    print_status "Setting up environment file..."
    
    if [ ! -f ".env" ]; then
        cp .env.example .env
        print_warning "Created .env file from template. Please edit it with your Penpot credentials:"
        print_warning "  PENPOT_USERNAME=your_username"
        print_warning "  PENPOT_PASSWORD=your_password"
        echo
        read -p "Press Enter to continue after editing the .env file..."
    else
        print_success "Environment file already exists."
    fi
}

# Build Docker image
build_image() {
    print_status "Building Docker image..."
    
    docker build -t "$IMAGE_NAME:latest" .
    
    print_success "Docker image built successfully!"
}

# Start services with Docker Compose
start_services() {
    print_status "Starting services with Docker Compose..."
    
    # Determine docker-compose command
    if command_exists docker-compose; then
        COMPOSE_CMD="docker-compose"
    else
        COMPOSE_CMD="docker compose"
    fi
    
    $COMPOSE_CMD up -d
    
    print_success "Services started successfully!"
    
    print_status "Waiting for services to be healthy..."
    sleep 10
    
    # Check if the service is running
    if curl -f http://localhost:5000/health >/dev/null 2>&1; then
        print_success "PenPot MCP Server is running and healthy!"
        echo
        print_status "You can now:"
        echo "  • View logs: $COMPOSE_CMD logs -f penpot-mcp"
        echo "  • Check status: $COMPOSE_CMD ps"
        echo "  • Access health endpoint: http://localhost:5000/health"
        echo "  • Stop services: $COMPOSE_CMD down"
    else
        print_warning "Service might still be starting up. Check logs with: $COMPOSE_CMD logs penpot-mcp"
    fi
}

# Clean up function
cleanup() {
    print_status "Cleaning up temporary files..."
    rm -rf "$SOURCE_DIR"
    print_success "Cleanup completed!"
}

# Main function
main() {
    echo
    print_status "🐳 PenPot MCP Server Docker Setup Script"
    echo "==========================================="
    echo
    
    # Parse command line arguments
    case "${1:-setup}" in
        "setup")
            check_prerequisites
            clone_source
            copy_source_files
            setup_environment
            build_image
            start_services
            cleanup
            ;;
        "build")
            check_prerequisites
            clone_source
            copy_source_files
            build_image
            cleanup
            ;;
        "start")
            check_prerequisites
            start_services
            ;;
        "clean")
            cleanup
            ;;
        "help"|"--help"|"-h")
            echo "Usage: $0 [command]"
            echo
            echo "Commands:"
            echo "  setup    Complete setup (clone, build, start) [default]"
            echo "  build    Only build the Docker image"
            echo "  start    Start the services"
            echo "  clean    Clean up temporary files"
            echo "  help     Show this help message"
            echo
            exit 0
            ;;
        *)
            print_error "Unknown command: $1"
            echo "Use '$0 help' for usage information."
            exit 1
            ;;
    esac
    
    echo
    print_success "🎉 Done! Your PenPot MCP Server is ready!"
}

# Trap to cleanup on exit
trap cleanup EXIT INT TERM

# Run main function
main "$@"
