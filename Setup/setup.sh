#!/bin/bash

# Get absolute paths for our directories
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
MINIVMAC_DIR="$ROOT_DIR/Submodules/minivmac"
CONFIG_DIR="$ROOT_DIR/Configuration"

# Create Configuration directory if it doesn't exist
mkdir -p "$CONFIG_DIR"

# Define arrays of models and their corresponding app names and class names
models=("128K" "512Ke" "Plus" "SE" "Classic" "SEFDHD" "II")
app_names=("mnvm128k" "mnvm512k" "mnvmplus" "mnvmse" "mnvmclsc" "mnvmsefd" "mnvmii")
display_names=(
    "Macintosh 128K"
    "Macintosh 512Ke"
    "Macintosh Plus"
    "Macintosh SE"
    "Macintosh Classic"
    "Macintosh SE FDHD"
    "Macintosh II"
)
class_names=(
    "Macintosh128KEmulatorVariation"
    "Macintosh512KeEmulatorVariation"
    "MacintoshPlusEmulatorVariation"
    "MacintoshSEEmulatorVariation"
    "MacintoshClassicEmulatorVariation"
    "MacintoshSEFDHDEmulatorVariation"
    "MacintoshIIEmulatorVariation"
)

# Function to get app name for a model
get_app_name() {
    local model=$1
    local index=0
    for m in "${models[@]}"; do
        if [ "$m" = "$model" ]; then
            echo "${app_names[$index]}"
            return
        fi
        ((index++))
    done
}

# Function to get array index for a model
get_model_index() {
    local model=$1
    local index=0
    for m in "${models[@]}"; do
        if [ "$m" = "$model" ]; then
            echo $index
            return
        fi
        ((index++))
    done
}

# Function to update CNFUIOSG.h with maintainer information
update_maintainer_info() {
    local display_name=$1
    local config_file="$CONFIG_DIR/$display_name/CNFUIOSG.h"
    
    if [ -f "$config_file" ]; then
        echo "Updating maintainer info in $display_name..."
        
        # Create temporary file with new content
        local temp_file=$(mktemp)
        
        # Read original file, excluding existing definitions if they exist
        grep -v "^#define kMaintainerName\|^#define kStrHomePage" "$config_file" > "$temp_file"
        
        # Add our new definitions with a clear comment
        echo "" >> "$temp_file"
        echo "/* Maintainer information */" >> "$temp_file"
        echo '#define kMaintainerName "Phil Zakharchenko"' >> "$temp_file"
        echo '#define kStrHomePage "https://philz.work"' >> "$temp_file"
        echo "" >> "$temp_file"
        
        # Replace original file and set permissions
        mv "$temp_file" "$config_file"
        chmod 666 "$config_file"
        echo "Updated maintainer info in $config_file"
    else
        echo "Warning: CNFUIOSG.h not found at $config_file"
    fi
}

# Function to update CNFUDALL.h with correct values
update_config_file() {
    local model=$1
    local index=$(get_model_index "$model")
    local display_name="${display_names[$index]}"
    local config_file="$CONFIG_DIR/$display_name/CNFUDALL.h"
    local index=$(get_model_index "$model")
    
    if [ -f "$config_file" ]; then
        echo "Updating configuration for $model..."
        
        # Create temporary file with new content
        local temp_file=$(mktemp)
        
        # Read original file, excluding existing definitions if they exist
        grep -v "^#define MMPrincipalClassName\|^#define MMDisplayName" "$config_file" > "$temp_file"
        
        # Add our new definitions with a clear comment
        echo "" >> "$temp_file"
        echo "/* Custom configuration for ${display_names[$index]} */" >> "$temp_file"
        echo "#define MMPrincipalClassName ${class_names[$index]}" >> "$temp_file"
        echo "#define MMDisplayName ${display_names[$index]}" >> "$temp_file"
        echo "" >> "$temp_file"
        
        # Replace original file and set permissions
        mv "$temp_file" "$config_file"
        chmod 666 "$config_file"
        echo "Updated $config_file and set permissions"
    else
        echo "Warning: Configuration file not found at $config_file"
    fi
}

# Function to build for a specific model
build_model() {
    local model=$1
    local app_name=$(get_app_name "$model")
    
    echo "Building for Macintosh $model..."
    
    # Create and move to temporary build directory
    local build_dir="$SCRIPT_DIR/build_temp"
    mkdir -p "$build_dir"
    cd "$build_dir" || exit 1
    
    # Copy necessary files from minivmac
    cp -r "$MINIVMAC_DIR/setup" .
    cp -r "$MINIVMAC_DIR/src" .
    
    # Generate setup tool
    gcc -o setup_t ./setup/tool.c
    
    # Generate build script for this model
    ./setup_t -e xcd -t mcar -sound 1 -drives 20 -sony-sum 1 -sony-tag 1 -sony-dc42 1 -speed z \
        -n "minivmac-37.03-$model" -an "$app_name" -m "$model" > generate_xcodeproj.sh
    
    # Make the generate script executable
    chmod +x ./generate_xcodeproj.sh
    
    # Run the generate script
    bash ./generate_xcodeproj.sh
    
    # If cfg folder exists, move it to Configuration directory with model-specific name
    if [ -d "./cfg" ]; then
        local index=$(get_model_index "$model")
        local display_name="${display_names[$index]}"
        
        # Remove existing directory if it exists
        if [ -d "$CONFIG_DIR/$display_name" ]; then
            rm -rf "$CONFIG_DIR/$display_name"
        fi
        
        mv "./cfg" "$CONFIG_DIR/$display_name"
        # Set permissions for the cfg directory and all its contents
        chmod -R 775 "$CONFIG_DIR/$display_name"
        find "$CONFIG_DIR/$display_name" -type f -exec chmod 666 {} \;
        echo "Moved cfg folder to $CONFIG_DIR/$display_name and set permissions"
        
        # Update the configuration files
        update_config_file "$model"
        update_maintainer_info "${display_names[$index]}"
    else
        echo "Warning: cfg folder not found after build for $model"
    fi
    
    # Clean up build directory
    cd "$SCRIPT_DIR"
    rm -rf "$build_dir"
}

# Build for each model
for model in "${models[@]}"; do
    build_model "$model"
done

echo "Build process complete!"
echo "Generated and configured folders in $CONFIG_DIR:"
ls -d "$CONFIG_DIR/Macintosh"*