#!/bin/bash

# VMware vCenter Password Management Tool - Modules Directory Chunking Script
# Purpose: Create GitHub-compliant chunks of the entire Modules directory
# Version: 2.0 - Directory-level chunking approach

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

SOURCE_DIR="Modules"
OUTPUT_DIR="."
MAX_CHUNK_SIZE_MB=95
CHUNK_PREFIX="modules-chunk-"

echo "=== VMware Modules Directory Chunking Script ==="
echo "Creating GitHub-compliant chunks of the entire Modules directory"
echo ""

# Validate source directory
if [ ! -d "$SOURCE_DIR" ]; then
    echo "ERROR: Source directory '$SOURCE_DIR' not found!"
    exit 1
fi

# Get source directory info
SOURCE_SIZE_MB=$(du -sm "$SOURCE_DIR" | cut -f1)
echo "Source Directory: $(pwd)/$SOURCE_DIR"
echo "Total Size: ${SOURCE_SIZE_MB} MB"
echo "Max Chunk Size: ${MAX_CHUNK_SIZE_MB} MB"
echo ""

# Calculate estimated number of chunks
ESTIMATED_CHUNKS=$(( (SOURCE_SIZE_MB + MAX_CHUNK_SIZE_MB - 1) / MAX_CHUNK_SIZE_MB ))
echo "Estimated chunks needed: $ESTIMATED_CHUNKS"
echo ""

# Check for existing chunks
EXISTING_CHUNKS=$(find "$OUTPUT_DIR" -name "${CHUNK_PREFIX}*.zip" -type f 2>/dev/null | wc -l)
if [ "$EXISTING_CHUNKS" -gt 0 ]; then
    echo "WARNING: Found $EXISTING_CHUNKS existing chunk files"
    echo "Removing existing chunks..."
    find "$OUTPUT_DIR" -name "${CHUNK_PREFIX}*.zip" -type f -delete
    find "$OUTPUT_DIR" -name "${CHUNK_PREFIX}*.z*" -type f -delete
    echo ""
fi

# Create chunks using split and zip
echo "Creating directory chunks..."

# Create a temporary tar file first
TEMP_TAR="/tmp/modules-temp-$(date +%Y%m%d-%H%M%S).tar"
echo "Creating temporary tar file: $TEMP_TAR"
tar -cf "$TEMP_TAR" "$SOURCE_DIR"

# Get tar file size
TAR_SIZE_MB=$(du -sm "$TEMP_TAR" | cut -f1)
echo "Tar file size: ${TAR_SIZE_MB} MB"

# Calculate chunk size in bytes (slightly smaller than max to account for compression)
CHUNK_SIZE_BYTES=$((MAX_CHUNK_SIZE_MB * 1024 * 1024))

# Split the tar file
echo "Splitting tar file into chunks..."
split -b "$CHUNK_SIZE_BYTES" "$TEMP_TAR" "/tmp/modules-chunk-"

# Compress each chunk
CHUNK_NUM=1
for chunk_file in /tmp/modules-chunk-*; do
    if [ -f "$chunk_file" ]; then
        CHUNK_NAME=$(printf "%s%02d.zip" "$CHUNK_PREFIX" "$CHUNK_NUM")
        echo "Creating $CHUNK_NAME..."
        
        # Create a temporary directory for this chunk
        TEMP_DIR="/tmp/chunk-$CHUNK_NUM"
        mkdir -p "$TEMP_DIR"
        
        # Extract the chunk to temp directory
        cd "$TEMP_DIR"
        tar -xf "$chunk_file"
        
        # Zip the extracted content
        cd "$SCRIPT_DIR"
        zip -r "$CHUNK_NAME" -C "$TEMP_DIR" .
        
        # Clean up temp directory
        rm -rf "$TEMP_DIR"
        rm -f "$chunk_file"
        
        CHUNK_NUM=$((CHUNK_NUM + 1))
    fi
done

# Clean up temporary tar file
rm -f "$TEMP_TAR"

# Actually, let's use a simpler approach with 7zip if available, or fall back to creating multiple zips
echo "Using alternative approach: creating multiple zip files..."

# Remove any temporary files
rm -f /tmp/modules-chunk-*

# Create chunks by splitting the directory contents
MODULES_SUBDIRS=($(find "$SOURCE_DIR" -mindepth 1 -maxdepth 1 -type d | sort))
TOTAL_SUBDIRS=${#MODULES_SUBDIRS[@]}

if [ "$TOTAL_SUBDIRS" -eq 0 ]; then
    echo "ERROR: No subdirectories found in $SOURCE_DIR"
    exit 1
fi

echo "Found $TOTAL_SUBDIRS module subdirectories"

# Calculate how many subdirs per chunk
SUBDIRS_PER_CHUNK=$(( (TOTAL_SUBDIRS + ESTIMATED_CHUNKS - 1) / ESTIMATED_CHUNKS ))
if [ "$SUBDIRS_PER_CHUNK" -lt 1 ]; then
    SUBDIRS_PER_CHUNK=1
fi

echo "Subdirectories per chunk: $SUBDIRS_PER_CHUNK"
echo ""

CHUNK_NUM=1
CURRENT_CHUNK_DIRS=()
CURRENT_CHUNK_SIZE=0

for subdir in "${MODULES_SUBDIRS[@]}"; do
    SUBDIR_SIZE_MB=$(du -sm "$subdir" | cut -f1)
    
    # Check if adding this directory would exceed the chunk size
    if [ "$CURRENT_CHUNK_SIZE" -gt 0 ] && [ $((CURRENT_CHUNK_SIZE + SUBDIR_SIZE_MB)) -gt "$MAX_CHUNK_SIZE_MB" ]; then
        # Create current chunk
        CHUNK_NAME=$(printf "%s%02d.zip" "$CHUNK_PREFIX" "$CHUNK_NUM")
        echo "Creating $CHUNK_NAME with ${#CURRENT_CHUNK_DIRS[@]} modules (${CURRENT_CHUNK_SIZE} MB)..."
        
        # Create zip with current directories
        zip -r "$CHUNK_NAME" "${CURRENT_CHUNK_DIRS[@]}"
        
        # Reset for next chunk
        CHUNK_NUM=$((CHUNK_NUM + 1))
        CURRENT_CHUNK_DIRS=("$subdir")
        CURRENT_CHUNK_SIZE=$SUBDIR_SIZE_MB
    else
        # Add to current chunk
        CURRENT_CHUNK_DIRS+=("$subdir")
        CURRENT_CHUNK_SIZE=$((CURRENT_CHUNK_SIZE + SUBDIR_SIZE_MB))
    fi
done

# Create final chunk if there are remaining directories
if [ "${#CURRENT_CHUNK_DIRS[@]}" -gt 0 ]; then
    CHUNK_NAME=$(printf "%s%02d.zip" "$CHUNK_PREFIX" "$CHUNK_NUM")
    echo "Creating final $CHUNK_NAME with ${#CURRENT_CHUNK_DIRS[@]} modules (${CURRENT_CHUNK_SIZE} MB)..."
    zip -r "$CHUNK_NAME" "${CURRENT_CHUNK_DIRS[@]}"
fi

# List created chunks
echo ""
echo "=== Chunking Complete ==="
CREATED_CHUNKS=($(find "$OUTPUT_DIR" -name "${CHUNK_PREFIX}*.zip" -type f | sort))
echo "Created ${#CREATED_CHUNKS[@]} chunks:"

TOTAL_COMPRESSED_SIZE=0
for chunk in "${CREATED_CHUNKS[@]}"; do
    CHUNK_SIZE_MB=$(du -sm "$chunk" | cut -f1)
    TOTAL_COMPRESSED_SIZE=$((TOTAL_COMPRESSED_SIZE + CHUNK_SIZE_MB))
    echo "  - $(basename "$chunk") (${CHUNK_SIZE_MB} MB)"
done

# Create manifest
MANIFEST_FILE="modules-chunks-manifest.txt"
cat > "$MANIFEST_FILE" << EOF
# VMware Modules Directory Chunks Manifest
# Generated: $(date)
# Source Directory: $SOURCE_DIR
# Total Source Size: ${SOURCE_SIZE_MB} MB
# Compression Method: Directory-level chunking with subdirectory grouping

# Chunk Information:
EOF

for chunk in "${CREATED_CHUNKS[@]}"; do
    CHUNK_SIZE_MB=$(du -sm "$chunk" | cut -f1)
    echo "# Chunk: $(basename "$chunk") (${CHUNK_SIZE_MB} MB)" >> "$MANIFEST_FILE"
done

cat >> "$MANIFEST_FILE" << EOF

# Extraction Instructions:
# 1. Ensure all chunk files are in the same directory
# 2. Run the startup script or extraction script
# 3. Chunks will be automatically extracted and cleaned up
# 4. The complete Modules directory will be recreated

Total-Chunks: ${#CREATED_CHUNKS[@]}
Total-Compressed-Size: ${TOTAL_COMPRESSED_SIZE} MB
Compression-Ratio: $(( (TOTAL_COMPRESSED_SIZE * 100) / SOURCE_SIZE_MB ))%
EOF

echo "  - $MANIFEST_FILE (manifest file)"
echo ""
echo "Compression ratio: $(( (TOTAL_COMPRESSED_SIZE * 100) / SOURCE_SIZE_MB ))%"
echo ""
echo "Next steps:"
echo "1. Commit the chunk files to your repository"
echo "2. Update the startup script to download and extract chunks"
echo "3. Test the extraction process"
echo ""
echo "Directory chunking completed successfully!"